//  FloValScalar.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Foundation
import MuPar // visit
import MuTime // NextFrame

public class FloValScalar: FloVal {

    // default scalar value is (0…1 = 1)
    public var now = Double(0) // current value; 2 in 0…3~1:2
    public var val  = Double(0) // target value
    public var min  = Double(0) // minimum value; 0 in 0…3
    public var max  = Double(1) // maximum value; 3 in 0…3
    public var dflt = Double(0) // default value; 1 in 0…3~1

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
        self.name = name
    }

    init(_ flo: Flo,_ name: String,_ num: Double) {
        super.init(flo, name)
        if name == "seg" {
            print("?",terminator: "")
        }
        valOps = [.now_, .val] //?? .now
        self.min = fmin(num, 0.0)
        self.max = fmax(num, 1.0)
        self.now = num
        self.val = num
    }

    init (with scalar: FloValScalar, viaEval: Bool = false) {
        super.init(scalar.flo, scalar.name)
        valOps = scalar.valOps // use default values
        if viaEval { valOps -= .lit }
        min  = scalar.min
        max  = scalar.max
        dflt = scalar.dflt
        now  = scalar.now
        val  = scalar.val
    }

    public func normalized() -> Double {
        if valOps.contains([.min,.max]) {
            let range = max - min
            let ret = (now - min) / range
            return ret
        } else {
            print("🚫 \(flo.name): cannot normalize \(now)")
            return now
        }
    }
    public func range() -> ClosedRange<Double> {
        if min <= max {
            return min...max
        } else {
            return min...(min+1)
        }
    }

    // user may double tap to kickoff defaults with optional animation
    func setNextDefault(_ visit: Visitor) {
        if !valOps.val { //??
            setDefault(visit)
        }
    }

    // startup set values without animation
    func bindVal() { //??

        if !valOps.val {
            setDefault(Visitor(.bind))
            now = val
        }
    }

    func setDefault(_ visit: Visitor) { // was setDefault

        if      valOps.dflt           { val = dflt }
        else if valOps.min, val < min { val = min  }
        else if valOps.max, val > max { val = max  }
        else if valOps.modu           { val = 0    }

        now = val
    }
    static func |= (lhs: FloValScalar, rhs: FloValScalar) {
        
        let mergeOps = lhs.valOps.rawValue |  rhs.valOps.rawValue
        lhs.valOps = FloValOps(rawValue: mergeOps)
        if rhs.valOps.min  { lhs.min = rhs.min }
        if rhs.valOps.max  { lhs.max = rhs.max }
        if rhs.valOps.val { lhs.val = rhs.val } //??
    }

    public static func == (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now == rhs.now }
    public static func >= (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now >= rhs.now }
    public static func >  (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now >  rhs.now }
    public static func <= (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now <= rhs.now }
    public static func <  (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now <  rhs.now }
    public static func != (lhs: FloValScalar,
                           rhs: FloValScalar) -> Bool { return lhs.now != rhs.now }

    public func inRange(from: Double) -> Bool {

        if valOps.modu, from > max { return false }
        if valOps.min , from < min { return false }
        if valOps.max , from > max { return false }
        return true
    }

    public override func printVal() -> String {
        return String(now)
    }

    public override func scriptVal(_ scriptOps: FloScriptOps,
                                   noParens: Bool = false) -> String {
        if scriptOps.delta {
            if !hasDelta() {
                return ""
            }
            print("*** \(flo.name) [\(scriptOps.description)].[\(valOps.description)] : \(val)")
        }

        let script = scriptScalar(scriptOps, scriptOps)
        return (noParens ? script
                : script.isEmpty ? script
                : scriptOps.parens ? "(\(script))"
                : script)
    }

    /// script scalar definition and/or current value
    ///
    ///  - parameters:
    ///     - allOps: all options for all passes and maybe next pass
    ///     - nowOps: only options for this pass
    ///
    ///   - note: maybe called to get definition, current value, or both.
    ///
    func scriptScalar(_ allOps: FloScriptOps,
                      _ nowOps: FloScriptOps) -> String {

        var str = ""
        if valOps.rawValue == 0   { return "" }

        var litNow: Bool { valOps.hasLit && allOps.onlyNow }
        var soloNow: Bool { valOps.val && (!valOps.hasLit || allOps.onlyNow) }

        if nowOps.def {
            if valOps.min    { str += min.digits(0...6) }
            if valOps.thru   { str += "…" } /// `…` is `⌥⃣;` on mac
            if valOps.thri   { str += "_" } /// integer range for midi
            if valOps.modu   { str += "%" } /// modulo
            if valOps.max    { str += max.digits(0...6) }
            if valOps.dflt   { str += "~" + dflt.digits(0...6) }

            if valOps.hasLit { str += val.digits(0...6) }
        } else if litNow     { str += val.digits(0...6)
        } else if soloNow    { str += val.digits(0...6)}
        return str
    }

    override public func hasDelta() -> Bool {
        if valOps.val {
            if valOps.dflt {
                if val != dflt { return true }
            } else {
                return true
            }
        }
        return false
    }

    // MARK: - set

    /// map between scalar ranges
    ///
    /// - parameters:
    ///     - val: scalar with range or number
    ///     - visit: ignored, see FloExprs
    ///     - ops: set .now andor .val
    ///
    ///  - note: plugins set .now in a callback loop from plugin
    ///
    @discardableResult
    public override func setVal(_ any: Any?,
                                _ visit: Visitor,
                                _ ops: FloValOps) -> Bool {
        
        guard let any else { return true }

        switch any {
        case let v as FloValScalar : setFrom(v)
        case let v as Double       : setNextOpNow(v)
        case let v as Float        : setNextOpNow(Double(v))
        case let v as CGFloat      : setNextOpNow(Double(v))
        case let v as Int          : setNextOpNow(Double(v))
        default: print("🚫 setVal unknown type for: from")
        }

        valOps += ops

        // testNextEqualNow()
        return true

        func setFrom(_ v: FloValScalar) {

            if valOps.thrui,
               v.valOps.thrui {

                let toRange = (  max -   min) + (   valOps.thri ? 1.0 : 0.0)
                let frRange = (v.max - v.min) + ( v.valOps.thri ? 1.0 : 0.0)
                if ops.now_ { now  = (v.now - v.min) * (toRange / frRange) + min }
                if ops.val { val = (v.val - v.min) * (toRange / frRange) + min }

            } else if valOps.modu {

                min = 0
                max = Double.maximum(1, max)
                if ops.now_ { now = fmod(v.now, max) }
                if ops.val { val = fmod(v.val, max) }
            } else {
                
                setNextOpNow(v.val)
            }
        }

        func setNextOpNow(_ n: Double) {
            if ops.now_ { now = n }
            if ops.val { val = n }
            setInRange()
        }
        
        func setInRange() {
            if valOps.modu { val = fmod(val, max) }
            if valOps.min, val < min { val = min }
            if valOps.max, val > max { val = max }
        }
    }

    public override func getVal() -> Any {
        return now
    }

    public func deepCopy(_ exprs: FloExprs) -> FloValScalar {
        let scalar = FloValScalar(with: self)
        scalar.flo = exprs.flo
        return scalar
    }
    public func copyEval() -> FloValScalar {
        return FloValScalar(with: self, viaEval: true)
    }
}
extension FloValScalar {

    func animateNowToNext(_ visit: Visitor) {
        if visit.from.tween {
            // already animating
            logNextNows("􀋽⁰")
        } else {
            logNextNows("􀋽⁼")
            now = val
        }
    }
    func testNextEqualNow() {
        if val == now {
            logNextNows("== ")
        }
    }
    func logNextNows(_ prefix: String,
                     _ suffix: String = "") {

        let id = "\(id)".pad(6)
        let path = flo.path(9).pad(-18)
        let valNow = " (next: \(val.digits(2)) - now: \(now.digits(2))) "
        print(prefix + id + path + valNow + suffix)
    }
}
