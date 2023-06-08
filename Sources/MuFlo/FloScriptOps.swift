//  Created by warren on 11/10/22.

import Foundation


public struct FloScriptOps: OptionSet {

    public let rawValue: Int

    public static let def     = FloScriptOps(rawValue: 1 << 0) ///  1 defined values `0…3=1` in  `a(x 0…3=1)`
    public static let now     = FloScriptOps(rawValue: 1 << 1) ///  2 current value `2` in `a(x 2)` or `a(x 0…3=1:2)`
    public static let edge    = FloScriptOps(rawValue: 1 << 2) ///  4 `>> (b c d)` in `a >> (b c d)`
    public static let compact = FloScriptOps(rawValue: 1 << 3) ///  8 `a.b` instead of `a { b }`
    public static let parens  = FloScriptOps(rawValue: 1 << 4) ///  16 `(1)` in `a(1)` but not `2` in `b(x 2)`
    public static let expand  = FloScriptOps(rawValue: 1 << 5) ///  32 expand edgeDef to full list edges
    public static let comment = FloScriptOps(rawValue: 1 << 6) ///  64 commas (`,`) and `// comment`
    public static let delta   = FloScriptOps(rawValue: 1 << 7) /// 128 only values where `.now != .dflt`
    public static let noLF    = FloScriptOps(rawValue: 1 << 8) /// 256 `no line feed
    public init(rawValue: Int = 0) { self.rawValue = rawValue }

    static var Delta : FloScriptOps { [.delta, .now                 , .parens, .compact, .noLF] }
    static var Now   : FloScriptOps { [        .now, .edge, .comment, .parens, .compact, .noLF] }
    static var Def   : FloScriptOps { [.def,         .edge, .comment, .parens, .compact, .noLF] }
    static var All   : FloScriptOps { [.def,   .now, .edge, .comment, .parens, .compact, .noLF] }
    static var Full  : FloScriptOps { [.def,   .now, .edge, .comment, .parens                 ] }
}
extension FloScriptOps: CustomStringConvertible {

    static public var debugDescriptions: [(Self, String)] = [
        (.def     , "def"     ),
        (.now     , "now"     ),
        (.edge    , "edge"    ),
        (.compact , "compact" ),
        (.parens  , "parens"  ),
        (.expand  , "expand"  ),
        (.comment , "comment" ),
        (.delta   , "delta"   ),
        (.noLF    , "noLF"    ),
    ]

    public var description: String {
        let result: [String] = Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }
        let joined = result.joined(separator: ",")
        return "\(joined)"
    }

    var def     : Bool { contains(.def    ) }
    var now     : Bool { contains(.now    ) }
    var edge    : Bool { contains(.edge   ) }
    var compact : Bool { contains(.compact) }
    var parens  : Bool { contains(.parens ) }
    var expand  : Bool { contains(.expand ) }
    var comment : Bool { contains(.comment) }
    var delta   : Bool { contains(.delta  ) }
    var noLF    : Bool { contains(.noLF   ) }

    var onlyDef : Bool {  def && !now }
    var onlyNow : Bool { !def &&  now }

}

