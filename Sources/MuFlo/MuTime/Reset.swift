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
        lock.lock(); defer { lock.unlock() }
        resets.forEach { $1.resetAll() }
    }
    public static func addReset(_ id: Int, _ reset: ResetDelegate) {
        lock.lock(); defer { lock.unlock() }
        resets[id] = reset
    }
    public static func removeReset(_ id: Int) {
        lock.lock(); defer { lock.unlock() }
        resets.removeValue(forKey: id)
    }

}
