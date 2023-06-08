//  Created by warren on 1/27/23.

import Foundation

public struct FloFindOps: OptionSet {

    public static let parents  = FloFindOps(rawValue: 1 << 0) // General type FloValScalar
    public static let children = FloFindOps(rawValue: 1 << 1) // General type FloValScalar
    public static let makePath = FloFindOps(rawValue: 1 << 2) // General type FloValScalar

    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var parents  : Bool { contains(.parents ) }
    var children : Bool { contains(.children) }
    var makePath : Bool { contains(.makePath) }
}
public struct FloParset: OptionSet {

    public static let expr   = FloParset(rawValue: 1 << 0)
    public static let name   = FloParset(rawValue: 1 << 1)
    public static let scalar = FloParset(rawValue: 1 << 3)
    public static let assign = FloParset(rawValue: 1 << 4)
    public static let quote  = FloParset(rawValue: 1 << 5)
    public static let match  = FloParset(rawValue: 1 << 6)
    public static let isIn   = FloParset(rawValue: 1 << 7)
    public static let equal  = FloParset(rawValue: 1 << 8)

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    static public var debugDescriptions: [(Self, String)] = [
        (.expr   , "expr"   ),
        (.name   , "name"   ),
        (.scalar , "scalar" ),
        (.assign , "assign" ),
        (.quote  , "quote"  ),
        (.match  , "match"  ),
        (.equal  , "equal"  ),
    ]

    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ", ")
        return "\(joined)"
    }
    static public func += (lhs: inout FloParset, rhs: FloParset) {
        lhs.rawValue |= rhs.rawValue
    }

    static public func & (lhs: inout FloParset, rhs: FloParset) -> FloParset {
        return FloParset(rawValue: lhs.rawValue & rhs.rawValue)
    }

    var expr   : Bool { contains(.expr  ) }
    var name   : Bool { contains(.name  ) }
    var scalar : Bool { contains(.scalar) }
    var assign : Bool { contains(.assign) }
    var quote  : Bool { contains(.quote ) }
    var match  : Bool { contains(.match ) }
    var isIn   : Bool { contains(.isIn  ) }
    var equal  : Bool { contains(.equal ) }

    mutating func removeAll() {
        rawValue = 0
    }
}
