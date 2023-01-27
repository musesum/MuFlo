//
//  File.swift
//  
//
//  Created by warren on 8/23/22.
//

import Foundation

enum FloExprOp: String {

    case none   = ""
    case path   = "path"
    case name   = "name"
    case quote  = "quote"
    case scalar = "scalar"
    case num    = "num"

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
    case divi   = "_/" // pythonic floor of div, while avoiding comment // symbol
    case mod    = "%"
    case assign = ":"  // assign value
    case comma  = ","

    init(_ op: String) { self = FloExprOp(rawValue: op) ?? .none }
    static let pathNames: Set<FloExprOp> = [.path, .name]
    static let literals: Set<FloExprOp> = [.path, .name, .quote, .scalar, .num]
    static let conditionals: Set<FloExprOp> = [.EQ, .LE, .GE, .LT, .GT, .In]
    static let operations: Set<FloExprOp> = [.add,.sub,.muy,.divi,.div,.mod,.assign]

    func hasConditionals(_ test: Set<FloExprOp> ) -> Bool {
        return !test.isDisjoint(with: FloExprOp.conditionals)
    }
    func hasOperations(_ test: Set<FloExprOp> ) -> Bool {
        return !test.isDisjoint(with: FloExprOp.operations)
    }
    func isPathName() -> Bool {
        return FloExprOp.pathNames.contains(self)
    }
    func isLiteral() -> Bool {
        return FloExprOp.literals.contains(self)
    }
    func isConditional() -> Bool {
        return FloExprOp.conditionals.contains(self)
    }
    func isOperation() -> Bool {
        return FloExprOp.operations.contains(self)
    }
}
