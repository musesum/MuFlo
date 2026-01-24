// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeDeck {

    var tapeItems : [TapeItem] = []
    var duration  : TimeInterval = 0

    // Playback control
    private var playbackTask: Task<Void, Never>?
    private var loop = true
    private var learn = false

    init() {}

    public func snapshot() -> TapePlay {
        return TapePlay(tapeItems, duration)
    }

    func add(_ item: TapeItem) {
        tapeItems.append(item)
    }
    func record(_ on: Bool) {
        let timeNow = Date().timeIntervalSince1970
        if on {
            duration = 0
        } else if let timeRec = tapeItems.first?.time {
            // user tapped record to stop, so set duration
            duration = timeNow - timeRec
        }
    }
    func play(_ on: Bool) {
        if on {
            startPlayback(loop)
        } else {
            stopPlayback()
        }
    }

    func loop (_ on: Bool) { self.loop  = on }
    func learn(_ on: Bool) { self.learn = on }
    func beat (_ on: Bool) { }

    private func startPlayback(_ loop: Bool) {
        guard !tapeItems.isEmpty else { return }
        stopPlayback() // cancel any existing task
        let copy = snapshot()
        playbackTask = copy.startPlayback(loop: loop)
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        NextFrame.shared.addBetweenFrame {
            Reset.reset()
        }
    }
}
