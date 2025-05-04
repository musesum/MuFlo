//  FloSetOps
//  created by musesum on 5/9/19.


import Foundation

public struct SetOps: OptionSet {

    public static let fire    = SetOps(rawValue: 1 << 0) // trigger event
    public static let sneak   = SetOps(rawValue: 1 << 1) // quietly set value, no trigger
    public static let changed = SetOps(rawValue: 1 << 3) // bang only when changed
    public static let ranging = SetOps(rawValue: 1 << 4) // reset range for m~n

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var fire    : Bool { contains(.fire   ) }
    var sneak   : Bool { contains(.sneak  ) }
    var changed : Bool { contains(.changed) }
    var ranging : Bool { contains(.ranging) }

    static public func += (lhs: inout SetOps, rhs: SetOps) {
        lhs.rawValue |= rhs.rawValue
    }

    static public func - (lhs: inout SetOps, rhs: SetOps) -> SetOps {
        return lhs.subtracting(rhs)
    }

}
