// created by musesum on 7/20/26

#if !os(watchOS)
import Foundation
import MuPeers

/// Gesture phase; raw values are the on-disk contract.
public enum GesturePhase: Int, Codable, Sendable {
    case began = 0
    case moved = 1
    case ended = 2
}

/// App-neutral gesture/control sample. JSON-encoded into `PlayItem.data`, keyed by
/// `controlId` (`PlayItem.path`) and typed `.gestureItem`. Scene-normalized `x`/`y` in 0…1.
public struct GestureEvent: Codable, Equatable, Sendable {
    public var t: Double            // relative time
    public var controlId: String    // maps to PlayItem.path
    public var phase: Int           // GesturePhase raw: began=0/moved=1/ended=2
    public var x: Float             // scene-normalized 0…1
    public var y: Float             // scene-normalized 0…1
    public var velocity: Float?
    public var extras: [String: Float]?

    public init(t: Double,
                controlId: String,
                phase: Int,
                x: Float,
                y: Float,
                velocity: Float? = nil,
                extras: [String: Float]? = nil) {
        self.t = t
        self.controlId = controlId
        self.phase = phase
        self.x = x
        self.y = y
        self.velocity = velocity
        self.extras = extras
    }

    public init(t: Double,
                controlId: String,
                phase: GesturePhase,
                x: Float,
                y: Float,
                velocity: Float? = nil,
                extras: [String: Float]? = nil) {
        self.init(t: t, controlId: controlId, phase: phase.rawValue,
                  x: x, y: y, velocity: velocity, extras: extras)
    }

    /// JSON-encode into a `.gestureItem` PlayItem; `path = controlId`, `time = t`.
    public func playItem() -> PlayItem? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        let item = PlayItem(.gestureItem, data, path: controlId)
        item.time = t
        return item
    }

    /// Decode from a `.gestureItem` PlayItem; nil on type/JSON mismatch.
    public init?(_ item: PlayItem) {
        guard item.type == .gestureItem,
              let event = try? JSONDecoder().decode(GestureEvent.self, from: item.data)
        else { return nil }
        self = event
    }
}
#endif
