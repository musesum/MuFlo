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

    private var learn = false
    private var lock  = NSLock()
    private var playbackTask: Task<Void, Never>?

    init() {
        Peers.shared.addDelegate(self, for: .tapeFrame)
    }

    func addTapeItem(_ item: TypeItem) {
        guard let tapeTrack else { return }
        lock.lock()
        tapeTrack.add(item)
        lock.unlock()
    }
    func record(_ on: Bool) {
        if on {
            let tapeTrack = TapeTrack(deckId)
            let trackId = tapeTrack.trackId
            tapeTrack.setState(.record)
            lock.lock()
            self.tapeTrack = tapeTrack
            tapeTracks[trackId] = tapeTrack
            lock.unlock()
        } else if let tapeTrack, tapeTrack.state.record {
            tapeTrack.setState(.stop)
            shareItem(tapeTrack)
        }
    }
    func play(_ on: Bool) {
        guard tapeTrack != nil else { return }
        if on {
            startPlayback()
        } else {
            stopPlayback()
        }
    }

    func loop (_ on: Bool) { self.tapeTrack?.state.set(.loop, on) }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    func startPlayback() {
        stopPlayback() // cancel any existing task
        guard let tapeTrack else { return }
        tapeTrack.normalizeTime()
        playbackTask = tapeTrack.makeTask()
    }

    func stopPlayback() {
        tapeTrack?.stop()
        playbackTask?.cancel()
        playbackTask = nil
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }
}

extension TapeDeck: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        let decoder = JSONDecoder()

        if let track = try? decoder.decode(TapeTrack.self, from: data) {
            print("✇ received TapeTrack deckId:\(track.deckId) trackId: \(track.trackId) from:\(from.rawValue)")

            lock.lock()
            tapeTracks[track.trackId] = track
            lock.unlock()
        }
    }
    public func shareItem(_ any: Any) {
        guard let track = any as? TapeTrack else { return }

        Task.detached {
            print("✇ share TapeTrack deckId:\(track.deckId) trackId: \(track.trackId)")
            await Peers.shared.sendItem(.tapeFrame) { @Sendable in
                try? JSONEncoder().encode(track)
            }
        }
    }

}
