// created by musesum on 8/12/25

import Foundation
import MuPeers

public struct TrackState: OptionSet, Sendable, Codable {

    static let stop   = TrackState(rawValue: 1 << 0)
    static let play   = TrackState(rawValue: 1 << 1)
    static let record = TrackState(rawValue: 1 << 2)
    static let loop   = TrackState(rawValue: 1 << 3)
    static let learn  = TrackState(rawValue: 1 << 4)
    static let beat   = TrackState(rawValue: 1 << 5)
    static let remove = TrackState(rawValue: 1 << 6)

    public var rawValue: UInt
    public init(rawValue: UInt = 0) { self.rawValue = rawValue }

    static nonisolated(unsafe) public var debugDescriptions: [(Self, String)] = [
        (.stop   , "stop"   ),
        (.play   , "play"   ),
        (.record , "record" ),
        (.loop   , "loop"   ),
        (.learn  , "learn"  ),
        (.beat   , "beat"   ),
        (.remove , "remove" ),
    ]

    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ",")
        return "[\(joined)]"
    }

    var stop   : Bool { contains(.stop  ) }
    var play   : Bool { contains(.play  ) }
    var record : Bool { contains(.record) }
    var loop   : Bool { contains(.loop  ) }
    var learn  : Bool { contains(.learn ) }
    var beat   : Bool { contains(.beat  ) }
    var remove : Bool { contains(.remove) }

    func hasAny(_ value: TrackState) -> Bool {
        !self.intersection(value).isEmpty
    }
    func has(_ value: TrackState) -> Bool {
        self.contains(value)
    }

    mutating func setState(_ state: TrackState, on: Bool) {
        if on {
            setOn(state)
        } else {
            setOff(state)
        }
    }
    mutating func setOff(_ state: TrackState) {
        self = self.subtracting(state)
    }
    mutating func setOn(_ state: TrackState) {

        switch state {
        case .stop   : set(on: .stop  , off: [.record, .play, .learn, .beat, .remove])
        case .record : set(on: .record, off: [.play,   .stop, .learn, .beat, .remove])
        case .play   : set(on: .play  , off: [.record, .stop, .learn, .beat, .remove])
        case .loop   : set(on: .loop  , off: [.remove])
        case .learn  : set(on: .learn , off: [.record, .stop, .play, .beat, .remove])
        case .beat   : set(on: .beat  , off: [.record, .stop, .play, .learn, .remove])
        case .remove : set(on: .remove, off: [])
        default:  self = state
        }
    }
    mutating func set(on: TrackState, off: TrackState) {
        self.insert(on)
        self = self.subtracting(off)
    }
    mutating func adjust(_ nextState: TrackState, _ on: Bool) {
        if on {
            self.insert(nextState)
        } else {
            self = self.subtracting(nextState)
        }
    }
}







