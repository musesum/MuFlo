// created by musesum on 8/12/25

import Foundation
import MuPeers

public struct TapeState: OptionSet, Sendable {
    
    static let record = TapeState(rawValue: 1 << 0)
    static let play   = TapeState(rawValue: 1 << 1)
    static let loop   = TapeState(rawValue: 1 << 2)
    static let learn  = TapeState(rawValue: 1 << 3)
    static let beat   = TapeState(rawValue: 1 << 4)

    public var rawValue: UInt8
    public init(rawValue: UInt8 = 0) { self.rawValue = rawValue }


    var record : Bool { contains(.record) }
    var play   : Bool { contains(.play  ) }
    var loop   : Bool { contains(.loop  ) }
    var learn  : Bool { contains(.learn ) }
    var beat   : Bool { contains(.beat  ) }

    func hasAny(_ value: TapeState) -> Bool {
        !self.intersection(value).isEmpty
    }
    func has(_ value: TapeState) -> Bool {
        self.contains(value)
    }

    mutating func adjust(_ on: Bool,_ nextState: TapeState) {
        if on {
            self.insert(nextState)
        } else {
            self = self.subtracting(nextState)
        }
    }
}







