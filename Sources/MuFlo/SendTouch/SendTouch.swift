import UIKit

// make UITouch Sendable

public struct SendTouch: Sendable {
    public enum Phase : Int, Sendable {
        case began = 0
        case moved = 1
        case stationary = 2
        case ended = 3
        case cancelled = 4
        case regionEntered = 5
        case regionMoved = 6
        case regionExited = 7

        public var done: Bool { return self == .ended || self == .cancelled }
    }
    public let force    : CGFloat
    public let radius   : CGFloat
    public let nextXY   : CGPoint
    public let phase    : Phase
    public let azimuth  : CGFloat
    public let altitude : CGFloat
    public let hash     : Int

    @MainActor public init(_ touch: UITouch) {
        let snapshot: SendTouch = {
            // Since this initializer is now main actor isolated,
            // you can safely call SendTouch.from(touch:) synchronously.
            return SendTouch.from(touch: touch)
        }()
        self = snapshot
    }

    @MainActor private static func from(touch: UITouch) -> SendTouch {
        let force = touch.force
        let radius = touch.majorRadius
        let nextXY = touch.location(in: nil)
        let phase = Phase(rawValue: touch.phase.rawValue) ?? .stationary
        let azimuth = touch.azimuthAngle(in: nil)
        let altitude: CGFloat = touch.altitudeAngle
        let hash = touch.hash
        return SendTouch(force, radius, nextXY, phase.rawValue, azimuth, altitude, hash)
    }

    private init(_ force     : CGFloat,
                 _ radius    : CGFloat,
                 _ nextXY    : CGPoint,
                 _ phase     : Int,
                 _ azimuth   : CGFloat,
                 _ altitude  : CGFloat,
                 _ hash      : Int) {

        self.force    = force
        self.radius   = radius
        self.nextXY   = nextXY
        self.phase    = Phase(rawValue: phase) ?? .began
        self.azimuth  = azimuth
        self.altitude = altitude
        self.hash     = hash
    }

}

public struct SendTouches: Sendable, Sequence {
    public let touches: [SendTouch]

    @MainActor public init(_ uiTouches: Set<UITouch>) {
        if Thread.isMainThread {
            self.touches = uiTouches.map { SendTouch($0) }
        } else {
            let result = DispatchQueue.main.sync {
                uiTouches.map { SendTouch($0) }
            }
            self.touches = result
        }
    }

    public func makeIterator() -> IndexingIterator<[SendTouch]> {
        return touches.makeIterator()
    }
}
