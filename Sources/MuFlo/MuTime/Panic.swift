// created by musesum on 6/22/25

import Foundation

public protocol PanicReset {
    func reset()
}

/// akin to MIDI panic which resets all buffers
public class Panic {
    public static let shared = Panic()
    var delegates = [Int:PanicReset]()

    public static func reset() {
        PrintLog("🫨 Panic count: \(shared.delegates.count)")
        for delegate in shared.delegates.values {
            delegate.reset()
        }
    }
    public static func add(_ id: Int, _ reset: PanicReset) {
        shared.delegates[id] = reset
    }
    public static func remove(_ id: Int) {

        shared.delegates.removeValue(forKey: id)
    }

}
