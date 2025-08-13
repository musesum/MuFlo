//  FloVal.swift
//
//  created by musesum on 3/8/19.

import Foundation
import CoreGraphics

open class FloVal {
    var id = Visitor.nextId()
    public var name: String
    public var flo: Flo  // flo that declared and contains this value
    let path: String

    init(_ flo: Flo, _ name: String) {
        self.flo = flo
        self.name = name
        self.path = flo.path(99)
    }
    
    init(with: FloVal) {
        self.flo = with.flo
        self.name = with.name
        self.path = flo.path(99)
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
    public func setVal(_ from: Any?) -> Bool {

        assertionFailure("⁉️ setVal needs override")
        return false
    }

    public func getVal() -> Any {
        assertionFailure("⁉️ getVal needs override")
    }

}

extension FloVal: Comparable {

    public static func == (lhs: FloVal, rhs: FloVal) -> Bool {
        return lhs.path == rhs.path
    }

    public static func < (lhs: FloVal, rhs: FloVal) -> Bool {
        return lhs.id < rhs.id
    }
}
