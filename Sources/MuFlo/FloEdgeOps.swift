// FloEdgeOps.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public struct FloEdgeOps: OptionSet {

    public let rawValue: Int

    public static let input   = FloEdgeOps(rawValue: 1 << 0) //  1 `<` in ` a << b            a <> b`
    public static let output  = FloEdgeOps(rawValue: 1 << 1) //  2 `>` in  `a >> b            a <> b`
    public static let solo    = FloEdgeOps(rawValue: 1 << 2) //  4 `=` in  `a <= b   a => b   a <=> b`
    public static let exclude = FloEdgeOps(rawValue: 1 << 3) //  8 `!` in  `a <! b   a !> b   a <!> b`
    public static let ternIf  = FloEdgeOps(rawValue: 1 << 5) // 32 ternary `a⟐→z` in `z(a ? b : c)`
    public static let ternGo  = FloEdgeOps(rawValue: 1 << 6) // 64 ternary `b◇→z`,`c◇→` in `z(a ? b : c)`
    public static let copyat  = FloEdgeOps(rawValue: 1 << 7) // 128 a @ b
    public static let animate = FloEdgeOps(rawValue: 1 << 8) // 256 a ~ b

    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    public init(with str: String) {
        self.init()
        for char in str {
            switch char {
            case "<","←": insert(.input)   // callback
            case ">","→": insert(.output)  // call out
            case "⟡"    : insert(.solo)    // overwrite
            case "!"    : insert(.exclude) // remove edge(s) //TODO: test
            case "?"    : insert(.ternIf)  // edge to ternary condition
            case "@"    : insert(.copyat)  // edge to ternary condition
            case "~"    : insert(.animate) // edge to ternary condition
            default     : continue
            }
        }
    }
    public init(flipIO: FloEdgeOps) {
        self.init(rawValue: flipIO.rawValue)

        let hasInput  = self.input
        let hasOutput = self.output
        // flip inputs and outputs, if have both, then remains the same
        if hasInput  { insert(.output) } else { remove(.output) }
        if hasOutput { insert(.input)  } else { remove(.input)  }
    }

    var input   : Bool { contains(.input  )}
    var output  : Bool { contains(.output )}
    var solo    : Bool { contains(.solo   )}
    var exclude : Bool { contains(.exclude)}
    var ternIf  : Bool { contains(.ternIf )}
    var ternGo  : Bool { contains(.ternGo )}
    var copyat  : Bool { contains(.copyat )}
    var animate : Bool { contains(.animate)}

    public func scriptExpicitOps() -> String {

        switch self {
            case [.input,.output]: return "<>"
            case [.input]: return "<<"
            case [.output]: return ">>"
            case [.input,.animate]: return "<~"
            case [.output,.animate]: return "~>"
            default: print( "⚠️ unexpected scriptEdgeOps")
        }
        return ""
    }
    public func scriptImplicitOps(_ active: Bool) -> String {

        var script = self.input ? "←" : ""

        if !active           { script += "◇" }
        else if self.solo    { script += "⟡" }
        else if self.ternIf  { script += "⟐" }
        else if self.ternGo  { script += "⟐" }
        else if self.copyat  { script += "@" }
        else if self.animate { script += "~" }

        script += self.output ? "→" : ""

        return script
    }
    var isImplicit: Bool {
        self.intersection([.solo,
                           .ternIf,
                           .ternGo,
                           .copyat]) != []
    }

    public func script(active: Bool = true) -> String {
        if isImplicit {
            return scriptImplicitOps(active)
        } else {
            return scriptExpicitOps()
        }
    }


}
