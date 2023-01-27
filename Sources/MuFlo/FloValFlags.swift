//  FloValFlags.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/** flags for scalar ranges

        A scalar range may have minimum and maximum value. It may have both a default value `dflt` and current value `now`. So, 0…3=1:2 has a min of 0, max of 3, dflt of 1 and a now of 2.

        When assigning from another scalar range, the values are remapped to relative position with each respective range. So, a current value of 1 in range 0…2
 */
public struct FloValFlags: OptionSet {

    public static let thru = FloValFlags(rawValue: 1 <<  1) // 0…1 range including 1
    public static let modu = FloValFlags(rawValue: 1 <<  2) // %2 modulo
    public static let min  = FloValFlags(rawValue: 1 <<  3) // 0 in 0…1, min of range
    public static let max  = FloValFlags(rawValue: 1 <<  4) // 1 in 0…1, max of range
    public static let dflt = FloValFlags(rawValue: 1 <<  5) // = n default value
    public static let now  = FloValFlags(rawValue: 1 <<  6) // current value
    public static let lit  = FloValFlags(rawValue: 1 <<  7) // literal value
    public static let anim = FloValFlags(rawValue: 1 <<  8) // animated

    func hasDef() -> Bool {
        let defset: FloValFlags = [.thru, .modu, .min, .max, .dflt]
        return (self.rawValue & defset.rawValue) > 0
    }

    /// Some values like midi.note.on midi.note.off should not persist transient values.
    /// So, when saving FloScriptFlags.delta, ignore a transient node.
    /// Otherwise, restoring from a .delta could activate stale values,
    /// such as a stale midi.note.on
    func isTransient() -> Bool {
        let defset: FloValFlags = [.now, .lit]
        return (self.rawValue & defset.rawValue) == 0
    }

    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var thru : Bool { contains(.thru) }
    var modu : Bool { contains(.modu) }
    var min  : Bool { contains(.min ) }
    var max  : Bool { contains(.max ) }
    var dflt : Bool { contains(.dflt) }
    var now  : Bool { contains(.now ) }
    var lit  : Bool { contains(.lit ) }
    var anim : Bool { contains(.anim) }
}
extension FloValFlags: CustomStringConvertible {

    static public var debugDescriptions: [(Self, String)] = [
        (.thru, "thru"),
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
}
