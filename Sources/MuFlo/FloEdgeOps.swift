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
    public static let copyat  = FloEdgeOps(rawValue: 1 << 4) // 16 a @ b
    public static let plugin  = FloEdgeOps(rawValue: 1 << 5) // 32 a ^ b

    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    public init(with str: String) {
        self.init()
        for char in str {
            switch char {
            case "<","←": insert(.input)   // callback
            case ">","→": insert(.output)  // call out
            case "⟡"    : insert(.solo)    // overwrite
            case "!"    : insert(.exclude) // remove edge(s) //TODO: test
            case "@"    : insert(.copyat)  // copy from another subtree
            case "^"    : insert(.plugin)  // plug-in redirects expression vals
            default     : continue
            }
        }
    }
    public init(flipIO: FloEdgeOps) {
        self.init(rawValue: flipIO.rawValue)

        // flip inputs and outputs, if have both, then remains the same
        if self.hasInput  { insert(.output) } else { remove(.output) }
        if self.hasOutput { insert(.input)  } else { remove(.input)  }
    }

    var hasInput   : Bool { contains(.input  )}
    var hasOutput  : Bool { contains(.output )}
    var hasSolo    : Bool { contains(.solo   )}
    var hasExclude : Bool { contains(.exclude)}
    var hasCopyat  : Bool { contains(.copyat )}
    var hasPlugin  : Bool { contains(.plugin )}

    public func scriptExpicitOps() -> String {

        switch self {
            case [.input,.output]: return " <> "
            case [.input]: return " <<"
            case [.output]: return " >>"
            case [.plugin]: return " ^"
            default: print( "⚠️ unexpected scriptEdgeOps")
        }
        return ""
    }
    public func scriptImplicitOps(_ active: Bool) -> String {

        var script = self.hasInput ? " ←" : ""

        if      !active        { script += "◇" }
        else if self.hasSolo   { script += "⟡" }
        else if self.hasCopyat { script += "@" }
        else if self.hasPlugin { script += "^" }

        script += self.hasOutput ? "→" : ""

        return script
    }

    var isImplicit: Bool {
        self.intersection([.solo, .copyat]) != []
    }

    public func script(active: Bool = true) -> String {
        if isImplicit {
            return scriptImplicitOps(active)
        } else {
            return scriptExpicitOps()
        }
    }

}
