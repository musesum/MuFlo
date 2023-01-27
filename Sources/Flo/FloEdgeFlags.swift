// FloEdgeFlags.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public struct FloEdgeFlags: OptionSet {

    public let rawValue: Int

    public static let input   = FloEdgeFlags(rawValue: 1 << 0) //  1 `<` in ` a << b            a <> b`
    public static let output  = FloEdgeFlags(rawValue: 1 << 1) //  2 `>` in  `a >> b            a <> b`
    public static let solo    = FloEdgeFlags(rawValue: 1 << 2) //  4 `=` in  `a <= b   a => b   a <=> b`
    public static let exclude = FloEdgeFlags(rawValue: 1 << 3) //  8 `!` in  `a <! b   a !> b   a <!> b`
    public static let ternIf  = FloEdgeFlags(rawValue: 1 << 5) // 32 ternary `a⟐→z` in `z(a ? b : c)`
    public static let ternGo  = FloEdgeFlags(rawValue: 1 << 6) // 64 ternary `b◇→z`,`c◇→` in `z(a ? b : c)`
    public static let copyat  = FloEdgeFlags(rawValue: 1 << 7) // 128 a @ b
    public static let animate = FloEdgeFlags(rawValue: 1 << 8) // 256 a ~ b

    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    public init(with str: String) {
        self.init()
        for char in str {
            switch char {
            case "<","←": self.insert(.input)   // callback
            case ">","→": self.insert(.output)  // call out
            case "⟡"    : self.insert(.solo)    // overwrite
            case "!"    : self.insert(.exclude) // remove edge(s) //TODO: test
            case "?"    : self.insert(.ternIf)  // edge to ternary condition
            case "@"    : self.insert(.copyat)  // edge to ternary condition
            case "~"    : self.insert(.animate) // edge to ternary condition
            default     : continue
            }
        }
    }
    public init(flipIO: FloEdgeFlags) {
        self.init(rawValue: flipIO.rawValue)

        let hasInput  = self.input
        let hasOutput = self.output
        // flip inputs and outputs, if have both, then remains the same
        if hasInput  { insert(.output) } else { remove(.output) }
        if hasOutput { insert(.input)  } else { remove(.input)  }
    }

    var input   : Bool { contains(.input   )}
    var output  : Bool { contains(.output  )}
    var solo    : Bool { contains(.solo    )}
    var exclude : Bool { contains(.exclude )}
    var ternIf  : Bool { contains(.ternIf  )}
    var ternGo  : Bool { contains(.ternGo  )}
    var copyat  : Bool { contains(.copyat  )}
    var animate : Bool { contains(.animate )}

    public func scriptExpicitFlags() -> String {

        switch self {
            case [.input,.output]: return "<>"
            case [.input]: return "<<"
            case [.output]: return ">>"
            case [.input,.animate]: return "<~"
            case [.output,.animate]: return "~>"
            default: print( "⚠️ unexpected scriptEdgeFlags")
        }
        return ""
    }
    public func scriptImplicitFlags(_ active: Bool) -> String {

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
            return scriptImplicitFlags(active)
        } else {
            return scriptExpicitFlags()
        }
    }


}
