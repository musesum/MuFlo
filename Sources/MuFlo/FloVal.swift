//  FloVal.swift
//
//  Created by warren on 3/8/19.

import Foundation
import CoreGraphics
import MuTime
import MuPar

protocol FloValProtocal {

    func copy() -> FloVal
    func setVal(_ from: Any?, _ option: FloSetOps?) -> Bool
    func getVal() -> Any
}

open class FloVal: Comparable {

    var id = -Visitor.nextId()
    var valOps = FloValOps(rawValue: 0) // which combination of the following?
    var name: String

    public var flo: Flo  // flo that declared and contains this value

    public static func == (lhs: FloVal, rhs: FloVal) -> Bool {
        return lhs.valOps == rhs.valOps
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
        self.valOps = with.valOps
    }
    func parse(string: String) -> Bool {
        print("FloVal parsing:" + string)
        return true
    }

    // print current state "2" in `a:(0…9=2)`
    public func printVal() -> String {
        return ""
    }
   // print internal connections "a╌>w", "b╌>w", "c╌>w" in  `w<-(a ? 1 : b ? 2 : c ? 3)`
  public func scriptVal(_ scriptOpts: FloScriptOps = [.parens]) -> String {
       return " "
   }

    public func hasDelta() -> Bool {
        return false
    }


    func copy() -> FloVal {
        return FloVal(with: self)
    }
    public func setVal(_ from: Any?,
                       _ visit: Visitor) -> Bool {

        assertionFailure("🚫 setVal needs override")
        return false
    }

    public func getVal() -> Any {
        assertionFailure("🚫 getVal needs override")
    }

}
