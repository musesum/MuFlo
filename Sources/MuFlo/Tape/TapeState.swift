// created by musesum on 8/12/25

import Foundation
import MuPeers

public struct TapeState: OptionSet, Sendable, Codable {

    static let stop   = TapeState(rawValue: 1 << 0)
    static let play   = TapeState(rawValue: 1 << 1)
    static let record = TapeState(rawValue: 1 << 2)
    static let loop   = TapeState(rawValue: 1 << 3)
    static let learn  = TapeState(rawValue: 1 << 4)
    static let beat   = TapeState(rawValue: 1 << 5)

    public var rawValue: UInt8
    public init(rawValue: UInt8 = 0) { self.rawValue = rawValue }

    static nonisolated(unsafe) public var debugDescriptions: [(Self, String)] = [
        (.stop   , "stop"   ),
        (.play   , "play"   ),
        (.record , "record" ),
        (.loop   , "loop"   ),
        (.learn  , "learn"  ),
        (.beat   , "beat"   ),
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

    func hasAny(_ value: TapeState) -> Bool {
        !self.intersection(value).isEmpty
    }
    func has(_ value: TapeState) -> Bool {
        self.contains(value)
    }

    mutating func set(_ state: TapeState,_ on: Bool) {
        if on {
            setOn(state)
        } else {
            setOff(state)
        }
    }
    mutating func setOff(_ state: TapeState) {
        self = self.subtracting(state)
    }
    mutating func setOn(_ state: TapeState) {
        switch state {
        case .stop   : set(on: .stop  , off: [.record, .play, .learn, .beat])
        case .record : set(on: .record, off: [.play,   .stop, .learn, .beat])
        case .play   : set(on: .play  , off: [.record, .stop, .learn, .beat])
        case .loop   : set(on: .loop  , off: [])
        case .learn  : set(on: .learn , off: [.record, .stop, .play, .beat])
        case .beat   : set(on: .beat  , off: [.record, .stop, .play, .learn])
        default:  self = state
        }
    }
    mutating func set(on: TapeState, off: TapeState) {
        self.insert(on)
        self = self.subtracting(off)
    }
    mutating func adjust(_ nextState: TapeState, _ on: Bool) {
        if on {
            self.insert(nextState)
        } else {
            self = self.subtracting(nextState)
        }
    }
}







