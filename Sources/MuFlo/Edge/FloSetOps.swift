//  FloSetOpsswift
//  created by musesum on 5/9/19.


import Foundation

public struct FloSetOps: OptionSet {

    public static let activate = FloSetOps(rawValue: 1 << 0) // trigger event
    public static let sneak    = FloSetOps(rawValue: 1 << 1) // quietly set value, no trigger
    public static let changed  = FloSetOps(rawValue: 1 << 3) // bang only when changed
    public static let animNow  = FloSetOps(rawValue: 1 << 4) // only set `now`, not `next` for animation

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var activate : Bool { contains(.activate) }
    var sneak    : Bool { contains(.sneak   ) }
    var changed  : Bool { contains(.changed ) }
    var animNow  : Bool { contains(.animNow ) }

    static public func += (lhs: inout FloSetOps, rhs: FloSetOps) {
        lhs.rawValue |= rhs.rawValue
    }

    static public func - (lhs: inout FloSetOps, rhs: FloSetOps) -> FloSetOps {
        return lhs.subtracting(rhs)
    }

}
