// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeTrack: @unchecked Sendable, Codable {
    
    var playStatus : PlayStatus
    var playItems  : [PlayItem]
    var playBeats  : PlayBeats?
    var tapeBegan = TimeInterval(0)
    var duration  = TimeInterval(0)
    
    init(_ deckId: Int) {
        self.playStatus = PlayStatus(deckId)
        self.playItems  = []
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
            tapeBegan = timeNow
            duration  = 0
        } else {
            duration = timeNow - tapeBegan
        }
        playItems.append(item)
    }
    
    func normalizeTime() {
        guard let tapeBegan = playItems.first?.time,
              tapeBegan != 0
        else { return }
        for item in playItems {
            item.normalize(tapeBegan)
        }
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
    
    func makePlayTask(_ from: DataFrom) -> Task<Void, Never>? {
        playStatus.playBegan = Date().timeIntervalSince1970  // set playBegan in playStatus for playback synchronization
        var index = 0
        PrintLog("🎞️ makePlayTask \(playStatus.deckId.script5) .\(from.icon) 🟢")
        return Task { [playItems, weak self] in
            guard let self else { return }
            do {
                while index < playItems.count {
                    try Task.checkCancellation()
                    let playItem = try await awaitPlayItem(index)
                    Peers.shared.playItem(playStatus.playState, playItem, from)
                    index = try await awaitNextIndex(index, from)
                }
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
        if index == playItems.count {
            updateStatus(.ending, on: true, from: from)
            let timeNow = Date().timeIntervalSince1970
            let timeDelta = fmod(timeNow - playStatus.playBegan, duration)
            let finalDelta = duration - timeDelta
            PrintLog("🎞️ playTask status \(playStatus.script) .\(from.icon) pause: \(finalDelta.digits(2))")

            try await sleep(finalDelta)

            if playStatus.playState.loop {
                updateStatus(.play, on: true, from: from)
                playStatus.playBegan = Date().timeIntervalSince1970  // reset playBegan in playStatus for next loop
                return 0
            } else {
                updateStatus(.stop, on: true, from: from)
            }
        }
        return index
    }
    func awaitPlayItem(_ index: Int) async throws -> PlayItem  {
        let playItem = playItems[index]
        let timeNow = Date().timeIntervalSince1970
        let timeDelta = fmod(timeNow - playStatus.playBegan, duration)
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

