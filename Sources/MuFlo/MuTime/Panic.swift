// created by musesum on 6/22/25

import Foundation

public protocol PanicReset {
    func reset()
}

/// akin to MIDI panic which resets all buffers


public class Panic {

    nonisolated(unsafe) static var delegates = [Int: PanicReset]()

    public static func reset() {
        PrintLog("🫨 Panic delgates count: \(delegates.count)")
        for delegate in delegates.values {
            delegate.reset()
        }
        delegates.removeAll()
    }
    public static func add(_ id: Int, _ reset: PanicReset) {
        delegates[id] = reset
    }
    public static func remove(_ id: Int) {

        delegates.removeValue(forKey: id)
    }

}
