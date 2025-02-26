//  FloValOps.swift
//  created by musesum on 3/10/19.

import Foundation

/** options for scalar ranges

 A scalar range may have minimum and maximum value. It may have both a default value `dflt` and current value `now`. So, 0…3=1:2 has a min of 0, max of 3, dflt of 1 and a now of 2.

 When assigning from another scalar range, the values are remapped to relative position with each respective range. So, a current value of 1 in range 0…2
 */
public struct ScalarOptions: OptionSet {

    public static let thru  = ScalarOptions(rawValue: 1 <<  1) // double 0…1 range including 1
    public static let thri  = ScalarOptions(rawValue: 1 <<  2) // integer 0_n range including n
    public static let mod  = ScalarOptions(rawValue: 1 <<  3) // %2 modulo
    public static let mini  = ScalarOptions(rawValue: 1 <<  4) // 0 in 0…1, min of range
    public static let maxi  = ScalarOptions(rawValue: 1 <<  5) // 1 in 0…1, max of range
    public static let dflt  = ScalarOptions(rawValue: 1 <<  6) // = n default value
    public static let value = ScalarOptions(rawValue: 1 <<  7) // next value
    public static let tween = ScalarOptions(rawValue: 1 <<  8) // tween animation value
    public static let liter = ScalarOptions(rawValue: 1 <<  9) // literal value
    public static let match = ScalarOptions(rawValue: 1 << 10) //  < <= >= > In condition
    public static let equal = ScalarOptions(rawValue: 1 << 11) // == condition
    public static let notEq = ScalarOptions(rawValue: 1 << 12) // != condition
    public static let anim  = ScalarOptions(rawValue: 1 << 13) // animated

    /// Some values like midi.note.on midi.note.off should not persist transient values.
    /// So, when saving FloScriptOps.delta, ignore a transient node.
    /// Otherwise, restoring from a .delta could activate stale values,
    /// such as a stale midi.note.on
    var isTransient: Bool {
        let defset: ScalarOptions = [.tween, .value, .liter]
        return (self.rawValue & defset.rawValue) == 0
    }

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public var thru  : Bool { contains(.thru ) }
    public var thri  : Bool { contains(.thri ) }
    public var modu  : Bool { contains(.mod ) }
    public var mini  : Bool { contains(.mini) }
    public var maxi  : Bool { contains(.maxi) }
    public var dflt  : Bool { contains(.dflt) }
    public var tween : Bool { contains(.tween) }
    public var value : Bool { contains(.value) }
    public var liter : Bool { contains(.liter) }
    public var match : Bool { contains(.match) }
    public var equal : Bool { contains(.equal) }
    public var notEq : Bool { contains(.notEq) }
    public var anim  : Bool { contains(.anim ) }
}
extension ScalarOptions: CustomStringConvertible {

    static public var debugDescriptions: [(Self, String)] = [
        (.thru,  "thru" ),
        (.thri,  "thri" ),
        (.mod,   "mod"  ),
        (.mini,  "mini" ),
        (.maxi,  "maxi" ),
        (.dflt,  "dflt" ),
        (.tween, "tween"),
        (.value, "value"),
        (.liter, "liter"),
        (.match, "match"),
        (.equal, "equal"),
        (.notEq, "notEq"),
        (.anim,  "anim" ),
    ]
   
    var hasDef: Bool {
        let ops: ScalarOptions = [.mini, .thru, .thri, .mod, .maxi, .dflt]
        return self.intersection(ops).rawValue > 0
    }
    var isLit: Bool {
        let ops: ScalarOptions =  [.liter, .equal, .notEq, .match]
        return self.intersection(ops).rawValue > 0
    }
    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ",")
        return "\(joined)"
    }
    public static func += (lhs: inout ScalarOptions, rhs: ScalarOptions) {
        lhs.rawValue |= rhs.rawValue
    }
    public static func -= (lhs: inout ScalarOptions, rhs: ScalarOptions) {
        let neg = lhs.rawValue & rhs.rawValue
        lhs.rawValue ^= neg
    }
}
