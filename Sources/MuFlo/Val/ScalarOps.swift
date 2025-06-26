//  FloValOps.swift
//  created by musesum on 3/10/19.

import Foundation

/** options for scalar ranges

 A scalar range may have minimum and maximum value. It may have both a default value `origin` and current value `now`. So, 0…3=1:2 has a min of 0, max of 3, origin of 1 and a now of 2.

 When assigning from another scalar range, the values are remapped to relative position with each respective range. So, a current value of 1 in range 0…2
 */
public struct ScalarOps: OptionSet, Sendable {
    
    public static let ranged = ScalarOps(rawValue: 1 <<  1) // double m…n range
    public static let rangei = ScalarOps(rawValue: 1 <<  2) // integer m_n range
    public static let rangea = ScalarOps(rawValue: 1 <<  3) // double m~n auto ranged
    public static let modulo = ScalarOps(rawValue: 1 <<  4) // %2 modulo
    public static let minim  = ScalarOps(rawValue: 1 <<  5) // 0 in 0…1, min of range
    public static let maxim  = ScalarOps(rawValue: 1 <<  6) // 1 in 0…1, max of range
    public static let origin = ScalarOps(rawValue: 1 <<  7) // = n default value
    public static let value  = ScalarOps(rawValue: 1 <<  8) // next value
    public static let tween  = ScalarOps(rawValue: 1 <<  9) // tween animation value
    public static let liter  = ScalarOps(rawValue: 1 << 10) // literal value

    /// Some values like midi.note.on midi.note.off should not persist transient values.
    /// So, when saving FloScriptOps.delta, ignore a transient node.
    /// Otherwise, restoring from a .delta could activate stale values,
    /// such as a stale midi.note.on
    var isTransient: Bool {
        let defset: ScalarOps = [.tween, .value, .liter]
        return (self.rawValue & defset.rawValue) == 0
    }
    
    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public var hasRange: Bool { contains(.ranged) || contains(.rangei) || contains(.rangea) }
    public var ranged : Bool { contains(.ranged) }
    public var rangei : Bool { contains(.rangei) }
    public var rangea : Bool { contains(.rangea) }
    public var modulo : Bool { contains(.modulo) }
    public var minim  : Bool { contains(.minim)  }
    public var maxim  : Bool { contains(.maxim)  }
    public var origin : Bool { contains(.origin) }
    public var tween  : Bool { contains(.tween)  }
    public var value  : Bool { contains(.value)  }
    public var liter  : Bool { contains(.liter)  }
}
extension ScalarOps: CustomStringConvertible {

    static nonisolated(unsafe) public var debugDescriptions: [(Self, String)] = [
        (.ranged, "ranged" ),
        (.rangei, "rangei" ),
        (.rangea, "rangea" ),
        (.modulo, "modulo" ),
        (.minim,  "minim"  ),
        (.maxim,  "maxim"  ),
        (.origin, "origin" ),
        (.tween,  "tween"  ),
        (.value,  "value"  ),
        (.liter,  "liter"  ),
    ]
   
    var hasDef: Bool {
        let defOps: ScalarOps = [.minim, .ranged, .rangei, .rangea, .modulo, .maxim, .origin]
        return self.intersection(defOps).rawValue > 0
    }
    
    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ",")
        return "\(joined)"
    }
    public static func |= (lhs: inout ScalarOps, rhs: ScalarOps) {
        lhs.rawValue |= rhs.rawValue
    }
    public static func -= (lhs: inout ScalarOps, rhs: ScalarOps) {
        let neg = lhs.rawValue & rhs.rawValue
        lhs.rawValue ^= neg
    }
}
