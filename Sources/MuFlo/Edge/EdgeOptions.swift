
//  created by musesum on 3/10/19.

import Foundation

public struct EdgeOptions: OptionSet, Sendable {

    public let rawValue: Int

    public static let input   = EdgeOptions(rawValue: 1 << 0) ///  1 `<` in `a <- b,         a <> b`
    public static let output  = EdgeOptions(rawValue: 1 << 1) ///  2 `>` in `a -> b,         a <> b`
    public static let solo    = EdgeOptions(rawValue: 1 << 2) ///  4 `=` in `a <= b, a => b, a <=> b`
    public static let exclude = EdgeOptions(rawValue: 1 << 3) ///  8 `!` in `a <! b, a !> b, a <!> b`
    public static let base    = EdgeOptions(rawValue: 1 << 4) /// 16 a : b
    public static let plugin  = EdgeOptions(rawValue: 1 << 5) /// 32 a ^ b

    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    public init(with str: String) {
        self.init()
        for char in str {
            switch char {
            case "<" : insert(.input)    /// callback
            case ">" : insert(.output)   /// call out
            case "=" : insert(.solo)     /// overwrite
            case "!" : insert(.exclude)  /// remove edge(s) //TODO: test
            case ":" : insert(.base)     /// copy from another base definition
            case "^" : insert(.plugin)   /// plug-in redirects expression vals
            default  : continue
            }
        }
    }
    public init(flipIO: EdgeOptions) {
        self.init(rawValue: flipIO.rawValue)

        // flip inputs and outputs, if have both, then remains the same
        if self.hasInput  { insert(.output) } else { remove(.output) }
        if self.hasOutput { insert(.input)  } else { remove(.input)  }
    }

    var hasInput   : Bool { contains(.input   )}
    var hasOutput  : Bool { contains(.output  )}
    var hasSolo    : Bool { contains(.solo    )}
    var hasExclude : Bool { contains(.exclude )}
    var hasBase    : Bool { contains(.base    )}
    var hasPlugin  : Bool { contains(.plugin  )}
    var hasSync    : Bool { contains([.input, .output])}

    public func script(active: Bool) -> String {
        // is implicit
        if intersection([.solo, .base]) != [] {
            return scriptImplicitOps(active)
        } else {
            return scriptExpicitOps()
        }

        func scriptExpicitOps() -> String {

            switch self {
                case [.input,.output]: return "<>"
                case [.input]: return "<-"
                case [.output]: return "->"
                case [.plugin]: return "^-"
                default: print( "⚠️ unexpected scriptEdgeOps")
            }
            return ""
        }
        func scriptImplicitOps(_ active: Bool) -> String {

            var script = self.hasInput ? "<" : ""

            if      !active        { script += "◇" }
            else if self.hasSolo   { script += "⟡" }
            else if self.hasBase   { script += ":" }
            else if self.hasPlugin { script += "^" }
            if self.hasOutput      { script += ">" }

            return script
        }
    }

}
