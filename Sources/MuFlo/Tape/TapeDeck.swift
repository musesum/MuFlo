// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeDeck {

    let deckId = UUID().uuidString.hashValue
    var tapeTrack: TapeTrack?
    var tapeTracks = [Int: TapeTrack]()
    var trackPlay = [Int: Task<Void, Never>]()

    private var learn = false
    private var lock  = NSLock()

    init() {
        Peers.shared.addDelegate(self, for: .tapeTrack)
    }

    func addTapeItem(_ item: PlayItem) {

        switch item.type {
        case .playStatus,
                .archiveFrame,
                .tapeTrack: return
            default: break
        }
        if let tapeTrack {
            lock.lock()
            tapeTrack.addTrack(item)
            lock.unlock()
        }
    }
    func recordOn(_ on: Bool) {
        PrintLog("🔄✇ recordOn: \(on)")
        lock.lock()
        if let tapeTrack {
            tapeTrack.updatePlayStatus(.record, on: on)
        } else if on {
            let tapeTrack = TapeTrack(deckId)
            let trackId = tapeTrack.playStatus.trackId
            Peers.shared.addDelegate(self, for: .playStatus)
            tapeTrack.setState(.record)
            self.tapeTrack = tapeTrack
            tapeTracks[trackId] = tapeTrack
            
            shareCurrentTrack()
        }
        lock.unlock()
    }
    func playOn(_ on: Bool) {
        PrintLog("🔄✇ playOn: \(on)")
        if on {
            startPlayback()
        } else {
            stopPlayback()
        }
        tapeTrack?.updatePlayStatus(.play, on: on)
    }

    func loop (_ on: Bool) { self.tapeTrack?.playStatus.updateState(.loop, on: on)
    }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    func startPlayback() {
        PrintLog("🔄✇ startPlayback")
        stopPlayback() // cancel any existing task
        guard let tapeTrack else { return }
        tapeTrack.normalizeTime()
        if let playTask = tapeTrack.makePlayTask(.local) {
            trackPlay[tapeTrack.playStatus.trackId] = playTask
        }
    }

    func stopPlayback() {
        guard let tapeTrack else { return }
        tapeTrack.stopTrack()

        if let playTask = trackPlay[tapeTrack.playStatus.trackId] {
            playTask.cancel()
            trackPlay.removeValue(forKey: tapeTrack.playStatus.trackId)
        }
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }
}

extension TapeDeck: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        let decoder = JSONDecoder()

        if let status = try? decoder.decode(PlayStatus.self, from: data) {
            // Changed Tape Status
            guard let track = tapeTracks[status.trackId]  else {
                return PrintLog("🔄 received  \(status.script) unmatched trackId ⁉️")
            }
            updateTrackStatus(status)
            track.playStatus.playState = status.playState

        } else if let track = try? decoder.decode(TapeTrack.self, from: data) {
            // New Tape Track
            PrintLog("🔄 received  \(track.Script) .\(from.rawValue)")
            if deckId != track.playStatus.deckId {
                lock.lock()
                tapeTracks[track.playStatus.trackId] = track
                lock.unlock()
            }
        }
        func updateTrackStatus(_ playStatus: PlayStatus) {
            PrintLog("🔄 received  \(playStatus.Script) .\(from.rawValue)")
            if let tapeTrack = tapeTracks[playStatus.trackId] {

                let playStatus = tapeTrack.playStatus
                let playState = playStatus.playState
                let trackId = playStatus.trackId

                if playState.ending {

                    tapeTrack.reset()
                }
                if playState.record ||
                    playState.stop ||
                    playState.remove {

                    trackPlay[trackId]?.cancel()
                    lock.lock()
                    tapeTracks.removeValue(forKey: trackId)
                    trackPlay.removeValue(forKey: trackId)
                    lock.unlock()

                } else if playState.play {

                    // local has same deckId
                    let from:DataFrom = self.deckId == playStatus.deckId ? .local : .remote

                    if let playTask = tapeTrack.makePlayTask(from) {
                        tapeTracks[trackId] = tapeTrack
                        trackPlay[trackId] = playTask
                    }
                } else if playState.loop {
                    //TODO:
                }
            } else {
                // remote will always have a different deckId
            }
        }
    }
    public func resetItem(_ playItem: PlayItem) {
        //...... should never get here? 
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
    func shareCurrentTrack() {
        guard let tapeTrack else { return }
        PrintLog("🔄 shareTapeTrack \(tapeTrack.Script)")
        shareItem(tapeTrack)
    }
}
