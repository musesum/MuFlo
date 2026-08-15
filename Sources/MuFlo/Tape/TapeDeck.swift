// created by musesum on 1/18/26

#if !os(watchOS)
import Foundation
import MuPeers

/// @unchecked: task/track maps are NSLock-guarded; the natural-end
/// callback crosses from the play task's executor
public class TapeDeck: @unchecked Sendable {

    let deckId = UUID().uuidString.hashValue
    var selfTrack: TapeTrack?
    var tapeTracks = [Int: TapeTrack]()
    var trackPeerIds = [Int: String]() // Map trackId to peerId
    var tapeTasks = [Int: Task<Void, Never>]()

    private var learn = false
    private var lock  = NSLock()
    /// mid-record pause (Dreamatic recordSetPaused model): items drop while
    /// paused; resume shifts the take anchor so event times stay contiguous
    private var paused = false
    private var pauseBegan: TimeInterval = 0

    init() {
        Peers.shared.addDelegate(self, for: .tapeTrack)
        Peers.shared.addDelegate(self, for: .playStatus)
    }

    // from TapeFlo
    func addTapeItem(_ item: PlayItem) {

        guard !paused else { return }
        switch item.type {
        case .playStatus,
                .archiveFrame,
                .tapeTrack: return
        default: break
        }
        if let selfTrack {
            lock.lock()
            selfTrack.addTrack(item)
            lock.unlock()
        }
    }
    /// Host opt-in: keep prior selfTracks on recordOn (multi-take decks like Living Author).
    /// Default off preserves the single-jam semantics (re-record replaces the tape).
    var retainTracks = false

    /// recorded layer order, BASE TAKE FIRST (trackId random — creation
    /// order must be explicit); drives undo depth and roll row order
    private var trackOrder = [Int]()
    /// undone layers held for redo
    private var undoneOverdubs = [TapeTrack]()
    /// playback generation per track — a stale task's deferred natural-end
    /// callback must never clear a successor task's map entry
    private var taskGen = [Int: Int]()

    /// Take-begin anchor, stamped by the host BEFORE the deck arms (the Author's
    /// onBeginRecording fires before its .recording phase publishes, so the anchor
    /// must pend here and be consumed by the NEXT recordOn — stamping selfTrack
    /// directly would hit the PREVIOUS take's track).
    var pendingBegan: TimeInterval = 0
    func markBegan() { pendingBegan = Date().timeIntervalSince1970 }

    /// Refine the recording track's anchor with the EXACT wall time of the take
    /// clock's zero (host back-computes it at finish: now − audioDuration —
    /// engine spin-up makes the begin-hook stamp early by ~0.5s).
    func setBegan(_ wallT: TimeInterval) { selfTrack?.tapeBegan = wallT }

    func recordOn() {
        PrintLog("🎞️✇ recordOn")
        setPaused(false)                    // a fresh take always starts unpaused
        // overdub: a RUNNING loop keeps playing; the new take layers into it,
        // anchored at the current loop phase and sharing the loop window.
        // Single-jam decks only — retainTracks (multi-take) and a pending
        // take anchor (markBegan) keep their fresh-take semantics
        if !retainTracks, pendingBegan == 0,
           let master = tapeTracks.values.first(where: { tapeTasks[$0.playStatus.trackId] != nil }) {
            let timeNow = Date().timeIntervalSince1970
            let phase = max(0, fmod(timeNow - master.playStatus.playBegan, master.playDuration))
            let newTrack = TapeTrack(deckId)
            newTrack.tapeBegan = timeNow - phase
            newTrack.loopDuration = master.playDuration
            newTrack.updateStatus(.record, on: true, from: .local)
            lock.lock()
            tapeTracks[newTrack.playStatus.trackId] = newTrack
            selfTrack = newTrack
            trackOrder.append(newTrack.playStatus.trackId)
            undoneOverdubs.removeAll()          // a new layer invalidates redo
            lock.unlock()
            PrintLog("🎞️✇ overdub phase \(phase.digits(2))")
            return
        }
        if !retainTracks {
            // a fresh take replaces the whole LOCAL tape — stale overdub
            // layers must not replay under the new loop
            let localIds = tapeTracks.keys.filter { trackPeerIds[$0] == nil }
            for trackId in localIds {
                if let track = tapeTracks[trackId] { stopPlayback(track) }
                lock.lock()
                tapeTracks.removeValue(forKey: trackId)
                lock.unlock()
            }
            lock.lock()
            trackOrder.removeAll()
            undoneOverdubs.removeAll()
            lock.unlock()
        } else if let selfTrack {
            stopPlayback(selfTrack)
        }
        let newTrack = TapeTrack(deckId)
        let newTrackId = newTrack.playStatus.trackId
        newTrack.tapeBegan = pendingBegan   // take-begin anchor (0 = first-item fallback)
        pendingBegan = 0
        newTrack.updateStatus(.record, on: true, from: .local)
        lock.lock()
        tapeTracks[newTrackId] = newTrack
        selfTrack = newTrack
        trackOrder.append(newTrackId)       // base take = bottom undo layer
        lock.unlock()
    }
    func recordOff() {
        pendingBegan = 0                    // hygiene: an unconsumed anchor never leaks forward
        setPaused(false)                    // stop always leaves the deck unpaused
        guard let selfTrack else { return }
        PrintLog("🎞️✇ recordOff")
        selfTrack.updateStatus(.record, on: false, from: .local)
        shareTapeTrack(selfTrack)
        // an overdub layer joins the still-running loop phase-aligned
        if let master = tapeTracks.values.first(where: {
            $0 !== selfTrack && tapeTasks[$0.playStatus.trackId] != nil }) {
            startPlayback(selfTrack, playBegan: master.playStatus.playBegan)
            PrintLog("🎞️✇ overdub joined loop")
        }
    }
    /// SINGLE mid-record pause gate: while paused addTapeItem drops items; resume
    /// shifts the take anchor forward by the pause span so post-resume event
    /// times stay contiguous (active-time model — no PlayState/wire change).
    func setPaused(_ on: Bool) {
        guard paused != on else { return }
        paused = on
        let timeNow = Date().timeIntervalSince1970
        if on {
            pauseBegan = timeNow
            PrintLog("🎞️✇ pause")
        } else {
            if pauseBegan > 0, let selfTrack, selfTrack.playStatus.playState.record {
                selfTrack.tapeBegan += timeNow - pauseBegan
                PrintLog("🎞️✇ resume span \((timeNow - pauseBegan).digits(2))")
            }
            pauseBegan = 0
        }
    }
    func playOn() {
        PrintLog("🎞️✇ playOn")
        tapeTracks.forEach { startPlayback($1) }

    }
    /// Scoped transport: play/stop ONE track by id (take-associated playback).
    /// `loop` non-nil overrides the track's loop bit (quiet, no status broadcast);
    /// the leading stopPlayback clears any prior/finished task so replays restart.
    func playTrack(_ trackId: Int, loop: Bool? = nil) {
        if let track = tapeTracks[trackId] {
            stopPlayback(track)
            if let loop { track.playStatus.updateState(.loop, on: loop) }
            startPlayback(track)
        } else {
            PrintLog("🎞️ ⚠️ playTrack unknown trackId \(trackId)")
        }
    }
    func stopTrack(_ trackId: Int) {
        if let track = tapeTracks[trackId] {
            stopPlayback(track)
        }
    }
    func playOff() {
        PrintLog("🎞️✇ playOff")
        tapeTracks.forEach { stopPlayback($1) }
    }
    func dataFrom_(_ tapeTrack: TapeTrack) -> DataFrom? {
        // Remote iff a peer owns the track (received() records the mapping); everything
        // else — self-recorded, loadTrack-seeded, archive-decoded (foreign deckId) — is
        // local. The old deckId comparison returned nil for seeded tracks once any
        // recording set selfTrack, silently killing their playback.
        if let peerId = trackPeerIds[tapeTrack.playStatus.trackId] {
            return .remote(peerId)
        }
        return .local
    }
    func loop (_ on: Bool) { selfTrack?.updateStatus(.loop, on: on, from: .local) }
    func learn(_ on: Bool) { learn = on }
    /// wall time of the last acted beat-on (double-tap suppression)
    private var lastBeatOn: TimeInterval = 0

    /// beat (fired at touch BEGAN) repositions playback to the beginning;
    /// within the last tenth of the window it first sets a new end mark.
    /// A second press within 200 ms is ignored — a near-end double-tap
    /// keeps duration = beginning→first-press began.
    /// no action while recording — the transport hides the button
    func beat (_ on: Bool) {
        guard on else { return } // press release
        if let selfTrack, selfTrack.playStatus.playState.record { return }
        let timeNow = Date().timeIntervalSince1970
        if timeNow - lastBeatOn < 0.2 { return }
        lastBeatOn = timeNow
        // LOCAL tracks only — a peer's loop window belongs to its owner
        for track in tapeTracks.values
        where trackPeerIds[track.playStatus.trackId] == nil
           && tapeTasks[track.playStatus.trackId] != nil {
            let pos = fmod(timeNow - track.playStatus.playBegan, track.playDuration)
            if pos >= 0.9 * track.playDuration {
                track.loopDuration = max(0.25, pos)
                PrintLog("🎞️ beat endMark \(pos.digits(2))")
            }
            stopPlayback(track)
            startPlayback(track)
            PrintLog("🎞️ beat restart \(pos.digits(2))")
        }
    }
    /// transport skip: restart running local loops at the beginning;
    /// no end-mark logic, no action while recording
    func skipToStart() {
        if let selfTrack, selfTrack.playStatus.playState.record { return }
        for track in tapeTracks.values
        where trackPeerIds[track.playStatus.trackId] == nil
           && tapeTasks[track.playStatus.trackId] != nil {
            stopPlayback(track)
            startPlayback(track)
        }
        PrintLog("🎞️ skipToStart")
    }
    /// sequencer pinch: scale the loop window across local tracks
    func setLoopDuration(_ seconds: TimeInterval) {
        let clamped = max(0.25, seconds)
        for track in tapeTracks.values
        where trackPeerIds[track.playStatus.trackId] == nil {
            track.loopDuration = clamped
        }
        selfTrack?.loopDuration = clamped
    }
    /// current loop window in seconds; nil before any recording
    var loopSeconds: TimeInterval? {
        let longest = tapeTracks.values.map(\.playDuration).max()
        if let longest, longest > 0 { return longest }
        return nil
    }
    /// live loop phase of the longest task-running window — the same track
    /// loopSeconds measures, so playhead and legend share one timebase.
    /// Task-keyed — playState.play is never set on the first pass
    var playPhase: TimeInterval? {
        let timeNow = Date().timeIntervalSince1970
        lock.lock(); defer { lock.unlock() }
        var longest: TapeTrack?
        for track in tapeTracks.values
        where tapeTasks[track.playStatus.trackId] != nil && track.playDuration > 0 {
            if track.playDuration > (longest?.playDuration ?? 0) { longest = track }
        }
        guard let track = longest else { return nil }
        return max(0, fmod(timeNow - track.playStatus.playBegan, track.playDuration))
    }
    /// recording a layer while another local track's loop task runs
    var isOverdubbing: Bool {
        lock.lock(); defer { lock.unlock() }
        guard let selfTrack, selfTrack.playStatus.playState.record else { return false }
        return tapeTracks.values.contains {
            $0 !== selfTrack && tapeTasks[$0.playStatus.trackId] != nil
        }
    }
    var canUndoOverdub: Bool {
        lock.lock(); defer { lock.unlock() }
        return !trackOrder.isEmpty
    }
    var canRedoOverdub: Bool {
        lock.lock(); defer { lock.unlock() }
        return !undoneOverdubs.isEmpty
    }

    /// most recent overdub layer off the tape; the redo stack keeps it
    func undoOverdub() {
        lock.lock()
        guard let trackId = trackOrder.last else { lock.unlock(); return }
        guard let track = tapeTracks[trackId] else {
            trackOrder.removeLast()      // dead id (peer removal) — drop it
            lock.unlock()
            return
        }
        guard !track.playStatus.playState.record else { lock.unlock(); return }
        trackOrder.removeLast()
        lock.unlock()

        stopPlayback(track)                // needs the map entry — before removal
        lock.lock()
        tapeTracks.removeValue(forKey: trackId)
        undoneOverdubs.append(track)
        if selfTrack === track { selfTrack = nil }
        lock.unlock()
        PrintLog("🎞️✇ undo overdub \(trackId.script5)")
    }
    /// reinstate the last undone layer, phase-aligned to a running master
    func redoOverdub() {
        lock.lock()
        guard selfTrack?.playStatus.playState.record != true,
              let track = undoneOverdubs.popLast() else { lock.unlock(); return }
        let trackId = track.playStatus.trackId
        tapeTracks[trackId] = track
        trackOrder.append(trackId)
        let master = tapeTracks.values.first(where: {
            $0 !== track && tapeTasks[$0.playStatus.trackId] != nil })
        lock.unlock()
        if let master {
            startPlayback(track, playBegan: master.playStatus.playBegan)
        }
        PrintLog("🎞️✇ redo overdub \(trackId.script5)")
    }

    /// `playBegan` anchors the task to a running master's phase (overdub
    /// join, redo) — stamped before the task starts, never after
    func startPlayback(_ tapeTrack: TapeTrack?, playBegan: TimeInterval? = nil) {

        guard let tapeTrack else { return }
        let trackId = tapeTrack.playStatus.trackId
        guard tapeTasks[trackId] == nil else { return }

        PrintLog("🎞️ start  \(tapeTrack.script)")
        tapeTrack.normalizeTime()
        lock.lock()
        let gen = (taskGen[trackId] ?? 0) + 1
        taskGen[trackId] = gen
        lock.unlock()
        if let dataFrom = dataFrom_(tapeTrack),
            let playTask = tapeTrack.makePlayTask(dataFrom, playBegan: playBegan,
                                                  ended: { [weak self] in
                self?.playTaskEnded(trackId, gen) }) {
            tapeTasks[trackId] = playTask
        }
    }
    /// natural task end — clear the map entry so task-keyed state
    /// (playPhase, isOverdubbing, overdub arming) goes idle
    private func playTaskEnded(_ trackId: Int, _ gen: Int) {
        lock.lock()
        if taskGen[trackId] == gen {
            tapeTasks.removeValue(forKey: trackId)
        }
        lock.unlock()
    }

    func stopPlayback(_ tapeTrack: TapeTrack) {
        let trackId = tapeTrack.playStatus.trackId
        if let tapeTrack = self.tapeTracks[trackId] {
            Peers.shared.resetPlayItems(tapeTrack.playItems)
            tapeTasks[trackId]?.cancel()
            tapeTasks.removeValue(forKey: trackId)
        }
    }

    /// Seed a LOCAL track (e.g. from archive). Mirrors received() storage; no trackPeerIds
    /// (local), does not touch selfTrack, does not auto-play, does not route through received().
    func loadTrack(_ track: TapeTrack) {
        let trackId = track.playStatus.trackId
        lock.lock()
        tapeTracks[trackId] = track
        lock.unlock()
    }
    var recordedTracks: [TapeTrack] { Array(tapeTracks.values) }
    /// creation-ordered tracks (base take first, layers after); seeded and
    /// remote tracks — never in trackOrder — append by id for stability
    var orderedTracks: [TapeTrack] {
        lock.lock(); defer { lock.unlock() }
        var ordered = trackOrder.compactMap { tapeTracks[$0] }
        let rest = tapeTracks.values
            .filter { !trackOrder.contains($0.playStatus.trackId) }
            .sorted { $0.playStatus.trackId < $1.playStatus.trackId }
        ordered.append(contentsOf: rest)
        return ordered
    }
}

extension TapeDeck: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        let decoder = JSONDecoder()
        if let status = receivedStatus() {
            PrintLog("🎞️ received status \(status.script) .\(from.icon)")
        } else if let track = receivedTrack() {
            PrintLog("🎞️ received track  \(track.script) .\(from.icon)")
        }
        func receivedTrack() -> TapeTrack? {
            if let track = try? decoder.decode(TapeTrack.self, from: data) {
                let trackId = track.playStatus.trackId
                if deckId != track.playStatus.deckId {
                    lock.lock()
                    tapeTracks[trackId] = track
                    if case .remote(let peerId) = from {
                        trackPeerIds[trackId] = peerId
                    }
                    lock.unlock()
                }
                return track
            }
            return nil
        }
        func receivedStatus() -> PlayStatus? {
            // Changed Tape Status
            if let status = try? decoder.decode(PlayStatus.self, from: data) {
                // some status received when remote begins recording
                if let track = tapeTracks[status.trackId]  {
                    updateTrackStatus(status)
                    track.playStatus.playState = status.playState
                }
                return status
            }
            return nil

            func updateTrackStatus(_ playStatus: PlayStatus) {

                let playState = playStatus.playState
                let trackId = playStatus.trackId
                let playTask = tapeTasks[trackId]

                if let tapeTrack = tapeTracks[trackId] {

                    if !playState.play, let playTask {
                        PrintLog("🎞️ cancelPlayTask \(playStatus.trackId.script5) 🛑")
                        playTask.cancel()
                        lock.lock()
                        tapeTasks.removeValue(forKey: trackId)
                        lock.unlock()
                        Peers.shared.resetPlayItems(tapeTrack.playItems)
                    }
                    else if playState.play, playTask == nil {
                        startPlayback(tapeTrack)
                    }
                    if playState.remove {

                        lock.lock()
                        tapeTracks.removeValue(forKey: trackId)
                        trackPeerIds.removeValue(forKey: trackId)
                        tapeTasks.removeValue(forKey: trackId)
                        lock.unlock()

                    }
                }
            }
        }
    }
    public func resetItem(_ playItem: MuPeers.PlayItem) {
        //... Peers.shared.resetPlayItems([playItem])
    }
    public func playItem(_ item: PlayItem, from: DataFrom) {
        //... received(data: playItem.data, from: from)
    }
    public func shareItem(_ any: Any) {

        if let track = any as? TapeTrack  {

            Task.detached {
                await Peers.shared.sendItem(.tapeTrack) { @Sendable in
                    try? JSONEncoder().encode(track)
                }
            }
        }
    }
    public func dropped(from: DataFrom) {
        guard case .remote(let peerId) = from,
                peerId.prefix(1) == PeersPrefix else { return }

        PrintLog("📡 TapeDeck dropped .\(from.icon) peer: \(peerId) cancelling tracks...")

        let tracksToStop = tapeTracks.values.filter { track in
             let trackId = track.playStatus.trackId
             return trackPeerIds[trackId] == peerId
        }
        for track in tracksToStop {
            stopPlayback(track)
            tapeTracks.removeValue(forKey: track.playStatus.trackId)
        }
    }
    func shareTapeTrack(_ tapeTrack: TapeTrack?) {
        guard let tapeTrack else { return }
        PrintLog("🎞️ shareTapeTrack \(tapeTrack.Script)")
        shareItem(tapeTrack)
    }
}
#endif
