//  FloSetOpsswift
//  created by musesum on 5/9/19.


import Foundation

public struct SetOptions: OptionSet {

    public static let fire    = SetOptions(rawValue: 1 << 0) // trigger event
    public static let sneak   = SetOptions(rawValue: 1 << 1) // quietly set value, no trigger
    public static let changed = SetOptions(rawValue: 1 << 3) // bang only when changed
    public static let animNow = SetOptions(rawValue: 1 << 4) // only set `now`, not `next` for animation

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var fire    : Bool { contains(.fire   ) }
    var sneak   : Bool { contains(.sneak  ) }
    var changed : Bool { contains(.changed) }
    var animNow : Bool { contains(.animNow) }

    static public func += (lhs: inout SetOptions, rhs: SetOptions) {
        lhs.rawValue |= rhs.rawValue
    }

    static public func - (lhs: inout SetOptions, rhs: SetOptions) -> SetOptions {
        return lhs.subtracting(rhs)
    }

}
