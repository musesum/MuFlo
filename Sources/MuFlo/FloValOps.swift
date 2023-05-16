//  FloValOps.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/** options for scalar ranges

 A scalar range may have minimum and maximum value. It may have both a default value `dflt` and current value `now`. So, 0…3=1:2 has a min of 0, max of 3, dflt of 1 and a now of 2.

 When assigning from another scalar range, the values are remapped to relative position with each respective range. So, a current value of 1 in range 0…2
 */
public struct FloValOps: OptionSet {

    public static let thru = FloValOps(rawValue: 1 <<  1) // double 0…1 range including 1
    public static let thri = FloValOps(rawValue: 1 <<  2) // integer 0_n range including n
    public static let modu = FloValOps(rawValue: 1 <<  3) // %2 modulo
    public static let min  = FloValOps(rawValue: 1 <<  4) // 0 in 0…1, min of range
    public static let max  = FloValOps(rawValue: 1 <<  5) // 1 in 0…1, max of range
    public static let dflt = FloValOps(rawValue: 1 <<  6) // = n default value
    public static let now  = FloValOps(rawValue: 1 <<  7) // current value
    public static let lit  = FloValOps(rawValue: 1 <<  8) // literal value
    public static let anim = FloValOps(rawValue: 1 <<  9) // animated

    func hasDef() -> Bool {
        let defset: FloValOps = [.thru, .thri, .modu, .min, .max, .dflt]
        return (self.rawValue & defset.rawValue) > 0
    }

    /// Some values like midi.note.on midi.note.off should not persist transient values.
    /// So, when saving FloScriptOps.delta, ignore a transient node.
    /// Otherwise, restoring from a .delta could activate stale values,
    /// such as a stale midi.note.on
    func isTransient() -> Bool {
        let defset: FloValOps = [.now, .lit]
        return (self.rawValue & defset.rawValue) == 0
    }

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var thrui: Bool { contains(.thru) || contains(.thri) }
    var thru : Bool { contains(.thru) }
    var thri : Bool { contains(.thri) }
    var modu : Bool { contains(.modu) }
    var min  : Bool { contains(.min ) }
    var max  : Bool { contains(.max ) }
    var dflt : Bool { contains(.dflt) }
    var now  : Bool { contains(.now ) }
    var lit  : Bool { contains(.lit ) }
    var anim : Bool { contains(.anim) }
}
extension FloValOps: CustomStringConvertible {

    static public var debugDescriptions: [(Self, String)] = [
        (.thru, "thru"),
        (.thri, "thri"),
        (.modu, "modu"),
        (.min , "min" ),
        (.max , "max" ),
        (.dflt, "dflt"),
        (.now , "now" ),
        (.lit , "lit" ),
        (.anim, "anim"),
    ]

    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ", ")
        return "\(joined)"
    }

    public static func += (lhs: inout FloValOps, rhs: FloValOps) {
        lhs.rawValue |= rhs.rawValue
    }
}
