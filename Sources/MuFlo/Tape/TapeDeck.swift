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
        } else if let tapeTrack, tapeTrack.state == .record {
            tapeTrack.setState(.stop)
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

    func loop (_ on: Bool) { self.tapeTrack?.loop  = on }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    func startPlayback() {
        stopPlayback() // cancel any existing task
        guard let tapeTrack else { return }
        tapeTrack.normalizeTime()
        var tapeItem = TapeItem(tapeTrack)
        playbackTask = tapeItem.makeTask()
    }

    func stopPlayback() {
        tapeTrack?.stop()
        playbackTask?.cancel()
        playbackTask = nil
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }
    func receiveItem(_ tapeItem: TapeItem, from: DataFrom) {
        let tapeTrack = TapeTrack(tapeItem)
        print("✇ receiveItem tapeTrack deckId:\(tapeTrack.deckId) trackId: \(tapeTrack.trackId)")
        lock.lock()
        tapeTracks[tapeTrack.trackId] = tapeTrack
        lock.unlock()
    }
}

extension TapeDeck: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        print("✇ received Data from:\(from.rawValue)")
        let decoder = JSONDecoder()
        if let item = try? decoder.decode(TapeItem.self, from: data) {
            receiveItem(item, from: from)

        }
    }
    public func shareItem(_ item: Any) {
        guard let item = item as? TapeItem else { return }
        print("✇ shareItem tapeItem deckId:\(item.deckId) trackId: \(item.trackId)")
        Task.detached {
            await Peers.shared.sendItem(.tapeFrame) { @Sendable in
                try? JSONEncoder().encode(item)
            }
        }
    }

}
