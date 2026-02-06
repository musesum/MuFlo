// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeBeat {
    private var beatPrev = TimeInterval(0)
    private var beatNext = TimeInterval(0)
    private var beatAve  = TimeInterval(0)
}

public class TapeDeck {

    let deckId = UUID().uuidString.hashValue
    var tapeTrack: TapeTrack?
    var tapeTracks = [Int: TapeTrack]()
    var trackPlay = [Int: Task<Void, Never>]()

    private var learn = false
    private var lock  = NSLock()

    init() {
        Peers.shared.addDelegate(self, for: .tapeFrame)
    }

    func addTapeItem(_ item: TypeItem) {

        switch item.type {
        case .trackFrame,
                .archiveFrame,
                .tapeFrame: return
            default: break
        }
        if let tapeTrack {
            lock.lock()
            tapeTrack.addTrack(item)
            lock.unlock()
        }
    }
    func recordOn(_ on: Bool) {
        PrintLog("✇✇ recordOn: \(on)")
        lock.lock()
        if let tapeTrack {
            tapeTrack.trackStatus.trackState.setState(.record, on: on)
            shareItem(tapeTrack.trackStatus)
        } else if on {
            let tapeTrack = TapeTrack(deckId)
            let trackId = tapeTrack.trackStatus.trackId
            Peers.shared.addDelegate(self, for: .trackFrame)
            tapeTrack.setState(.record)

            self.tapeTrack = tapeTrack
            tapeTracks[trackId] = tapeTrack
            shareItem(tapeTrack)
        }
        lock.unlock()
    }
    func playOn(_ on: Bool) {
        PrintLog("✇✇ playOn: \(on)")
        if on {
            startPlayback()
        } else {
            stopPlayback()
        }
        if let tapeTrack {
            tapeTrack.trackStatus.trackState.setState(.play, on: on)
            shareItem(tapeTrack.trackStatus)
        }
    }

    func loop (_ on: Bool) { self.tapeTrack?.trackStatus.trackState.setState(.loop, on: on)
    }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    func startPlayback() {
        PrintLog("✇✇ startPlayback")
        stopPlayback() // cancel any existing task
        guard let tapeTrack else { return }
        tapeTrack.normalizeTime()
        if let playTask = tapeTrack.makePlayTask(.local) {
            trackPlay[tapeTrack.trackStatus.trackId] = playTask
        }
    }

    func stopPlayback() {
        guard let tapeTrack else { return }
        tapeTrack.stopTrack()

        if let playTask = trackPlay[tapeTrack.trackStatus.trackId] {
            playTask.cancel()
            trackPlay.removeValue(forKey: tapeTrack.trackStatus.trackId)
        }
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }
}

extension TapeDeck: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        let decoder = JSONDecoder()

        if let status = try? decoder.decode(TrackStatus.self, from: data) {
            // Changed Tape Status
            guard let track = tapeTracks[status.trackId]  else {
                return PrintLog("✇ received  \(status.script) unmatched trackId ⁉️")
            }
            updateTrackStatus(status)
            track.trackStatus.trackState = status.trackState

        } else if let track = try? decoder.decode(TapeTrack.self, from: data) {
            // New Tape Track
            PrintLog("✇ received  \(track.Script) .\(from.rawValue)")
            if deckId != track.trackStatus.deckId {
                lock.lock()
                tapeTracks[track.trackStatus.trackId] = track
                lock.unlock()
            }
        }
        func updateTrackStatus(_ trackStatus: TrackStatus) {
            PrintLog("✇ received  \(trackStatus.Script) .\(from.rawValue)")
            if trackStatus.trackState.contains([.record,.loop]) {
                print("yo")
            }
            if let tapeTrack = tapeTracks[trackStatus.trackId] {

                let trackStatus = tapeTrack.trackStatus
                let trackState = trackStatus.trackState
                let trackId = trackStatus.trackId

                if trackState.record ||
                    trackState.stop ||
                    trackState.remove {

                    trackPlay[trackId]?.cancel()
                    lock.lock()
                    tapeTracks.removeValue(forKey: trackId)
                    trackPlay.removeValue(forKey: trackId)
                    lock.unlock()

                } else if trackState.play {

                    // local has same deckId
                    let from:DataFrom = self.deckId == trackStatus.deckId ? .local: .remote

                    if let playTask = tapeTrack.makePlayTask(from) {
                        tapeTracks[trackId] = tapeTrack
                        trackPlay[trackId] = playTask
                    }
                } else if trackState.loop {
                    //TODO:
                }
                if trackState.remove {
                    //TODO:
                }
            } else {
                // remote will always have a different deckId
            }
        }
    }
    public func shareItem(_ any: Any) {

        if let status = any as? TrackStatus {
            PrintLog("✇ shareItem \(status.Script)")
            Task.detached {
                await Peers.shared.sendItem(.trackFrame) { @Sendable in
                    try? JSONEncoder().encode(status)
                }
            }
        } else if let track = any as? TapeTrack  {
            PrintLog("✇ shareItem \(track.Script)")
            Task.detached {
                await Peers.shared.sendItem(.tapeFrame) { @Sendable in
                    try? JSONEncoder().encode(track)
                }
            }
        }
    }
}
