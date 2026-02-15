// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeDeck {

    let deckId = UUID().uuidString.hashValue
    var selfTrack: TapeTrack?
    var tapeTracks = [Int: TapeTrack]()
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
        PrintLog("🔄✇ recordOn")
        if let selfTrack {
            stopPlayback(selfTrack)
            let oldTrackId = selfTrack.playStatus.trackId
            tapeTracks.removeValue(forKey: oldTrackId)
        }
        let newTrack = TapeTrack(deckId)
        let newTrackId = newTrack.playStatus.trackId
        newTrack.updateStatus(.record, on: true, from: .local)
        tapeTracks[newTrackId] = newTrack
        selfTrack = newTrack
    }
    func recordOff() {
        guard let selfTrack else { return }
        PrintLog("🔄✇ recordOff")
        selfTrack.updateStatus(.record, on: false, from: .local)
        shareTapeTrack(selfTrack)
    }
    func playOn() {
        PrintLog("🔄✇ playOn")
        tapeTracks.forEach { startPlayback($1) }

    }
    func playOff() {
        PrintLog("🔄✇ playOff")
        tapeTracks.forEach { stopPlayback($1) }
    }
    func dataFrom(_ tapeTrack: TapeTrack) -> DataFrom {
        guard let selfTrack else { return .remote  }
        return (tapeTrack.playStatus.deckId ==
                selfTrack.playStatus.deckId) ? .local : .remote
    }
    func loop (_ on: Bool) { selfTrack?.updateStatus(.loop, on: on, from: .local) }
    func learn(_ on: Bool) { learn = on }
    func beat (_ on: Bool) { }

    func startPlayback(_ tapeTrack: TapeTrack?) {

        guard let tapeTrack else { return }
        let trackId = tapeTrack.playStatus.trackId
        guard tapeTasks[trackId] == nil else { return }
        
        PrintLog("🔄 start  \(tapeTrack.script)")
        tapeTrack.normalizeTime()
        if let playTask = tapeTrack.makePlayTask(dataFrom(tapeTrack)) {
            tapeTasks[tapeTrack.playStatus.trackId] = playTask
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
            PrintLog("🔄 received status \(status.script) .\(from.icon)")
        } else if let track = receivedTrack() {
            PrintLog("🔄 received track  \(track.script) .\(from.icon)")
        }
        func receivedTrack() -> TapeTrack? {
            if let track = try? decoder.decode(TapeTrack.self, from: data) {

                if deckId != track.playStatus.deckId {
                    lock.lock()
                    tapeTracks[track.playStatus.trackId] = track
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
                        PrintLog("🔄 cancelPlayTask \(playStatus.trackId.script5) 🛑")
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
    func shareTapeTrack(_ tapeTrack: TapeTrack?) {
        guard let tapeTrack else { return }
        PrintLog("🔄 shareTapeTrack \(tapeTrack.Script)")
        shareItem(tapeTrack)
    }
}
