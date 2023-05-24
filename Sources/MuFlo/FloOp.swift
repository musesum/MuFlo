//  Created by warren on 8/23/22.

import Foundation

enum FloOp: String {
    
    case none   = ""
    case path   = "path"
    case name   = "name"
    case quote  = "quote"
    case scalar = "scalar"
    case num    = "num"
    
    case IS     = "≈" // << is equal, don't restrict >> when activated
    case EQ     = "=="
    case LE     = "<="
    case GE     = ">="
    case LT     = "<"
    case GT     = ">"
    case In     = "in"
    
    case add    = "+"
    case sub    = "-"
    case muy    = "*"
    case div    = "/"
    case mod    = "%"
    case comma  = ","

    case assign = ":"

    
    init(_ op: String) { self = FloOp(rawValue: op) ?? .none }
    
    enum FloOpType { case none, pathName, literal, condition, operation, endop }
    
    var opType: FloOpType {

        switch self {
        case .quote, .scalar, .num:            return .literal
        case .IS,.EQ,.LE,.GE,.LT,.GT,.In:      return .condition
        case .add,.sub,.muy,.div,.mod,.assign: return .operation
        case .path, .name:                     return .pathName
        case .comma:                           return .endop
        case .none:                            return .none
        }
    }
    
    var literal   : Bool { opType == .literal   }
    var condition : Bool { opType == .condition }
    var operation : Bool { opType == .operation }
    var pathName  : Bool { opType == .pathName  }
}


