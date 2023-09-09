//  Created by warren on 7/10/23.

import Foundation


public struct VisitFrom: OptionSet {

    public let rawValue: Int

    public static let bind   = VisitFrom(rawValue: 1 << 0) // 1
    public static let model  = VisitFrom(rawValue: 1 << 1) // 2
    public static let canvas = VisitFrom(rawValue: 1 << 2) // 4
    public static let user   = VisitFrom(rawValue: 1 << 3) // 8
    public static let remote = VisitFrom(rawValue: 1 << 4) // 16
    public static let midi   = VisitFrom(rawValue: 1 << 5) // 32
    public static let tween  = VisitFrom(rawValue: 1 << 6) // 64
    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    static public var debugDescriptions: [(Self, String)] = [
        (.bind   , "bind"  ),   // parsing in progress
        (.model  , "model" ),   // a non-user update
        (.canvas , "canvas"),   // user touched a non-menu canvas
        (.user   , "user"  ),   // a user gesture
        (.remote , "remote"),   // from a remote device
        (.remote , "midi"  ),   // from a midi device
        (.tween  , "tween" ),   // from an animataion
    ]
    static public var logDescriptions: [(Self, String)] = [
        (.bind   , "􁀘"),
        (.model  , "􀬎"),
        (.canvas , "􀏅"),
        (.user   , "􀉩"),
        (.remote , "􀤆"),
        (.midi   , "􀑪"),
        (.tween  , "􀎶"),
    ]

    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ", ")
        return "[\(joined)]"
    }
    public var log: String {
        let result: [String] = Self.logDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: "")
       return joined
    }
    public var bind   : Bool { contains(.bind  ) }
    public var remote : Bool { contains(.remote) }
    public var canvas : Bool { contains(.canvas) }
    public var user   : Bool { contains(.user  ) }
    public var model  : Bool { contains(.model ) }
    public var midi   : Bool { contains(.midi  ) }
    public var tween  : Bool { contains(.tween ) }

    public static func + (lhs: VisitFrom, rhs: VisitFrom) -> VisitFrom {
        return VisitFrom(rawValue: lhs.rawValue | rhs.rawValue)
    }

    public static func += (lhs: inout VisitFrom, rhs: VisitFrom) {
        lhs = lhs + rhs
    }
}
