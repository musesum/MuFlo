// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeBeat {
    private var beatPrev = TimeInterval(0)
    private var beatNext = TimeInterval(0)
    private var beatAve  = TimeInterval(0)
}

public class TapeDeck {

    let deckId = Visitor.nextId()
    var tapeClip: TapeClip?
    var tapeClips = [Int: TapeClip]()

    private var learn = false
    private var lock  = NSLock()
    private var playbackTask: Task<Void, Never>?

    init() {}

    func addTapeItem(_ item: TypeItem) {
        guard let tapeClip else { return }
        lock.lock()
        tapeClip.add(item)
        lock.unlock()
    }
    func record(_ on: Bool) {
        if on {
            let clip = TapeClip(deckId)
            let clipId = clip.clipId
            clip.setState(.recording)
            lock.lock()
            tapeClip = clip
            tapeClips[clipId] = clip
            lock.unlock()
        }
    }
    func play(_ on: Bool) {
        guard tapeClip != nil else { return }
        if on {
            startPlayback()
        } else {
            stopPlayback()
        }
    }

    func loop (_ on: Bool) { self.tapeClip?.loop  = on }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    func startPlayback() {
        stopPlayback() // cancel any existing task
        guard let tapeClip else { return }
        tapeClip.normalizeTime()
        var tapeItem = TapeItem(tapeClip)
        playbackTask = tapeItem.makeTask()
    }

    func stopPlayback() {
        tapeClip?.stop()
        playbackTask?.cancel()
        playbackTask = nil
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }


}
