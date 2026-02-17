// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeDeck {

    let deckId = UUID().uuidString.hashValue
    var selfTrack: TapeTrack?
    var tapeTracks = [Int: TapeTrack]()
    var trackPeerIds = [Int: String]() // Map trackId to peerId
    var tapeTasks = [Int: Task<Void, Never>]()

    private var learn = false
    private var lock  = NSLock()

    init() {
        Peers.shared.addDelegate(self, for: .tapeTrack)
        Peers.shared.addDelegate(self, for: .playStatus)
    }

    // from TapeFlo
    func addTapeItem(_ item: PlayItem) {

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
    func recordOn() {
        PrintLog("🎞️✇ recordOn")
        if let selfTrack {
            stopPlayback(selfTrack)
            let oldTrackId = selfTrack.playStatus.trackId
            tapeTracks.removeValue(forKey: oldTrackId)
            trackPeerIds.removeValue(forKey: oldTrackId)
        }
        let newTrack = TapeTrack(deckId)
        let newTrackId = newTrack.playStatus.trackId
        newTrack.updateStatus(.record, on: true, from: .local)
        tapeTracks[newTrackId] = newTrack
        selfTrack = newTrack
    }
    func recordOff() {
        guard let selfTrack else { return }
        PrintLog("🎞️✇ recordOff")
        selfTrack.updateStatus(.record, on: false, from: .local)
        shareTapeTrack(selfTrack)
    }
    func playOn() {
        PrintLog("🎞️✇ playOn")
        tapeTracks.forEach { startPlayback($1) }

    }
    func playOff() {
        PrintLog("🎞️✇ playOff")
        tapeTracks.forEach { stopPlayback($1) }
    }
    func dataFrom_(_ tapeTrack: TapeTrack) -> DataFrom? {
        let trackId = tapeTrack.playStatus.trackId
        guard let selfTrack else {
            if let peerId = trackPeerIds[trackId] {
                return .remote(peerId)
            }
            return nil
        }
        if tapeTrack.playStatus.deckId == selfTrack.playStatus.deckId {
            return .local
        }
        if let peerId = trackPeerIds[trackId] {
            return .remote(peerId)
        }
        return nil
    }
    func loop (_ on: Bool) { selfTrack?.updateStatus(.loop, on: on, from: .local) }
    func learn(_ on: Bool) { learn = on }
    func beat (_ on: Bool) { }

    func startPlayback(_ tapeTrack: TapeTrack?) {

        guard let tapeTrack else { return }
        let trackId = tapeTrack.playStatus.trackId
        guard tapeTasks[trackId] == nil else { return }
        
        PrintLog("🎞️ start  \(tapeTrack.script)")
        tapeTrack.normalizeTime()
        if let dataFrom = dataFrom_(tapeTrack),
            let playTask = tapeTrack.makePlayTask(dataFrom) {
            tapeTasks[trackId] = playTask
        }
    }

    func stopPlayback(_ tapeTrack: TapeTrack) {
        let trackId = tapeTrack.playStatus.trackId
        if let tapeTrack = self.tapeTracks[trackId] {
            Peers.shared.resetPlayItems(tapeTrack.playItems)
            tapeTasks[trackId]?.cancel()
            tapeTasks.removeValue(forKey: trackId)
        }
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
        //..... Peers.shared.resetPlayItems([playItem])
    }
    public func playItem(_ item: PlayItem, from: DataFrom) {
        //..... received(data: playItem.data, from: from)
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
