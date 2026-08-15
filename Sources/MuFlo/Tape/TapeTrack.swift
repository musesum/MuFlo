// created by musesum on 1/18/26

#if !os(watchOS)
import Foundation
import MuPeers

public class TapeTrack: @unchecked Sendable, Codable {
    
    var playStatus : PlayStatus
    var playItems  : [PlayItem]
    var playBeats  : PlayBeats?
    var tapeBegan = TimeInterval(0)
    var duration  = TimeInterval(0)
    /// sequencer loop-end override (beat tap / pinch); nil = full duration.
    /// Optional so old archives decode (absent → nil) and old peers skip the key.
    public var loopDuration: TimeInterval?

    init(_ deckId: Int) {
        self.playStatus = PlayStatus(deckId)
        self.playItems  = []
    }

    /// Stable public identity (archive entry name; take↔track association key).
    public var trackId: Int { playStatus.trackId }

    /// playback length: loop override when set, else recorded duration
    public var playDuration: TimeInterval {
        if let loopDuration, loopDuration > 0 { return loopDuration }
        return duration
    }
    /// sequencer roll event: row key + loop-relative time + touch phase/finger
    public struct TapeEvent: Sendable {
        public let key: String
        public let time: TimeInterval
        public let phase: Int?   // 0 began, 1 moved, 2 ended; nil instantaneous
        public let finger: Int?  // concurrent-touch slot 1…
        public init(key: String, time: TimeInterval, phase: Int?, finger: Int?) {
            self.key = key; self.time = time; self.phase = phase; self.finger = finger
        }
    }
    /// per-event roll data — live during recording, already-relative after
    /// normalizeTime/decode (tapeBegan == 0). Key = flo path when present
    /// (menu items), else the input TYPE — draw, midi, hand … per row
    public var tapeEvents: [TapeEvent] {
        playItems.map {
            TapeEvent(key: $0.path.isEmpty ? $0.type.description : $0.path,
                      time: tapeBegan > 0 ? max(0, $0.time - tapeBegan) : $0.time,
                      phase: $0.phase,
                      finger: $0.finger)
        }
    }
    public var trackDuration : TimeInterval { duration }
    public var isPlaying     : Bool { playStatus.playState.play }
    public var isRecording   : Bool { playStatus.playState.record }
    public var playBeganTime : TimeInterval { playStatus.playBegan }
    /// live take elapsed while the anchor is armed (recording); else duration
    public var recordElapsed : TimeInterval {
        tapeBegan > 0 ? Date().timeIntervalSince1970 - tapeBegan : duration
    }

    var script: String {
        playStatus.script + " items: \(playItems.count)"
    }
    var Script: String {
        "TapeTrack   " + script
    }
    
    func addTrack(_ item: PlayItem) {

        let timeNow = Date().timeIntervalSince1970
        if playItems.isEmpty {
            // markBegan (take-begin anchor) may already have stamped tapeBegan —
            // first-item time is only the FALLBACK anchor (take never marked).
            if tapeBegan == 0 { tapeBegan = timeNow }
            duration = timeNow - tapeBegan
        } else {
            duration = timeNow - tapeBegan
        }
        playItems.append(item)
    }

    /// Make item times anchor-relative ONCE. tapeBegan==0 is the "already
    /// normalized / decoded from archive" marker — decoded tracks arrive
    /// relative with tapeBegan 0, and the reset keeps repeat playback stable.
    func normalizeTime() {
        guard tapeBegan != 0 else { return }
        for item in playItems {
            item.normalize(tapeBegan)
            if item.time < 0 { item.time = 0 }   // pre-begin capture (arm→begin window)
        }
        tapeBegan = 0
    }
    func setState_(_ nextState: PlayState) -> Void {
        let oldState = playStatus.playState
        playStatus.playState.setOn(nextState)
        if oldState.record, !playStatus.playState.record {
            duration = Date().timeIntervalSince1970 - tapeBegan
            PrintLog("🎞️ setState duration: \(duration)")
        }
        PrintLog("🎞️ setState \(oldState.description) -> \(playStatus.playState.description)")
    }
}
extension TapeTrack { // task
    
    func makePlayTask(_ from: DataFrom,
                      playBegan anchor: TimeInterval? = nil,
                      ended: (@Sendable () -> Void)? = nil) -> Task<Void, Never>? {
        // anchor = join a running master phase-aligned (overdub join, redo);
        // stamped BEFORE the task runs — a post-start write races the task
        playStatus.playBegan = anchor ?? Date().timeIntervalSince1970
        var index = 0
        PrintLog("🎞️ makePlayTask \(playStatus.deckId.script5) .\(from.icon) 🟢")
        return Task { [playItems, weak self] in
            guard let self else { return }
            do {
                if anchor != nil, !playItems.isEmpty {
                    // skip items behind the join phase — they fire on the
                    // next wrap, not as an instantaneous catch-up burst
                    let phase = fmod(Date().timeIntervalSince1970 - playStatus.playBegan,
                                     playDuration)
                    while index < playItems.count, playItems[index].time < phase {
                        index += 1
                    }
                    if index == playItems.count {
                        index = try await awaitNextIndex(playItems.count - 1, from)
                    }
                }
                while index < playItems.count {
                    try Task.checkCancellation()
                    let playItem = try await awaitPlayItem(index)
                    Peers.shared.playItem(playStatus.playState, playItem, from)
                    index = try await awaitNextIndex(index, from)
                }
                ended?()   // natural end — task-keyed deck state goes idle
            } catch is CancellationError {
                // Explicit cancellation handling: log and update status
                PrintLog("🎞️ playTask cancelled .\(from.icon) 🔴")
                Task.detached { [weak self] in
                    guard let self else { return }
                    self.updateStatus(.stop, on: true, from: from)
                }
            } catch {
                // Handle other errors if needed
                PrintLog("🎞️ ⚠️ playTask error: \(error)")
            }
        }
    }
    func awaitNextIndex(_ index: Int, _ from: DataFrom) async throws -> Int {
        let index = index + 1
        let loopEnd = playDuration
        // loop end = item list exhausted OR next item past the loop window
        if index == playItems.count || playItems[index].time > loopEnd {
            updateStatus(.ending, on: true, from: from)
            let timeNow = Date().timeIntervalSince1970
            let timeDelta = fmod(timeNow - playStatus.playBegan, loopEnd)
            let finalDelta = loopEnd - timeDelta
            PrintLog("🎞️ playTask status \(playStatus.script) .\(from.icon) pause: \(finalDelta.digits(2))")

            try await sleep(finalDelta)

            if playStatus.playState.loop {
                updateStatus(.play, on: true, from: from)
                playStatus.playBegan = Date().timeIntervalSince1970  // reset playBegan in playStatus for next loop
                return 0
            } else {
                updateStatus(.stop, on: true, from: from)
                // natural end mirrors explicit stop — release replay-latched gestures
                Peers.shared.resetPlayItems(playItems)
                return playItems.count // early loop-end must still exit the play task
            }
        }
        return index
    }
    func awaitPlayItem(_ index: Int) async throws -> PlayItem  {
        let playItem = playItems[index]
        let timeNow = Date().timeIntervalSince1970
        let timeDelta = fmod(timeNow - playStatus.playBegan, playDuration)
        try await sleep(playItem.time - timeDelta) // normalized
        return playItem
    }
    func sleep(_ duration: TimeInterval) async throws {
        if duration > 0 {
            let n = UInt64(duration * 1_000_000_000)
            try await Task.sleep(nanoseconds: n)
        }
    }
    public func updateStatus(_ state: PlayState, on: Bool, from: DataFrom) {
        
        let oldRecord = playStatus.playState.record
        playStatus.updateState(state, on: on)
        let newRecord = playStatus.playState.record
        
        // complete recording duration?
        if oldRecord, !newRecord {
            let timeNow = Date().timeIntervalSince1970
            duration = timeNow - tapeBegan
        }
        PrintLog("🎞️ update status   \(playStatus.script) .\(from.icon)")
        if from == .local {
            Task.detached {
                await Peers.shared.sendItem(.playStatus) { @Sendable in
                    try? JSONEncoder().encode(self.playStatus)
                }
            }
        }
    }
}
#endif

