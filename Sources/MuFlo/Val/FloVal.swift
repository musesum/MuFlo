//  FloVal.swift
//
//  created by musesum on 3/8/19.

import Foundation
import CoreGraphics

open class FloVal: Comparable {

    public var id = -Visitor.nextId()
    public var name: String
    public var flo: Flo  // flo that declared and contains this value
	
    public static func == (lhs: FloVal, rhs: FloVal) -> Bool {
        return lhs.flo.path(9) == rhs.flo.path(9)
    }

    public static func < (lhs: FloVal, rhs: FloVal) -> Bool {
        return lhs.id < rhs.id
    }

    init(_ flo: Flo, _ name: String) {
        self.flo = flo
        self.name = name
    }
    
    init(with: FloVal) {
        self.flo = with.flo
        self.name = with.name
    }

    // "2" in `a:(0…9=2)`
    public func printVal(_ flo: Flo) -> String {
        return ""
    }
    // print internal connections "a╌>w", "b╌>w", "c╌>w" in  `w<-(a ? 1 : b ? 2 : c ? 3)`
    public func scriptVal(_ from: Flo,
                          _ scriptOps: FloScriptOps = [.parens],
                          viaEdge: Bool,
                          noParens: Bool = false) -> String {
        return " "
    }

    public func hasDelta() -> Bool {
        return false
    }

    func copy() -> FloVal {
        return FloVal(with: self)
    }

    @discardableResult
    public func setVal(_ from: Any?,
                       _ visit: Visitor) -> Bool {

        assertionFailure("⁉️ setVal needs override")
        return false
    }

    public func getVal() -> Any {
        assertionFailure("⁉️ getVal needs override")
    }

}
