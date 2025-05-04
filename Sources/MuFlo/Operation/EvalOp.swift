//  created by musesum on 8/23/22.

import Foundation

public enum EvalOp: String {
    
    case none    = ""
    case path    = "path"
    case name    = "name"
    case quote   = "quote"
    case tooltip = "tooltip"
    case scalar  = "scalar"
    case num     = "num"

    case EQ      = "=="
    case LE      = "<="
    case GE      = ">="
    case LT      = "<"
    case GT      = ">"
    case In      = "in"

    case add     = "+"
    case sub     = "-"
    case muy     = "*"
    case div     = "/"
    case mod     = "%"
    case comma   = ","
    case assign  = ":"

    public init(_ op: String) { self = EvalOp(rawValue: op) ?? .none }
}


