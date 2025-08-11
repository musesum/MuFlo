// created by musesum on 6/22/25

import Foundation

public protocol ResetDelegate {
    func resetAll()
}

/// akin to MIDI panic which resets all buffers

public class Reset {

    nonisolated(unsafe) static var resets = [Int: ResetDelegate]()
    static let lock = NSLock()

    public static func reset() {
        DebugLog { P("🫨 Reset delgates count: \(self.resets.count)") }
        lock.lock()
        for resetter in resets.values {
            resetter.resetAll()
        }
        lock.unlock()
    }
    public static func add(_ id: Int, _ reset: ResetDelegate) {
        lock.lock()
        resets[id] = reset
        lock.unlock()
    }
    public static func remove(_ id: Int) {
        lock.lock()
        resets.removeValue(forKey: id)
        lock.unlock()
    }

}
