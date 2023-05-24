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
    var next = Double(0) // target value
    var min  = Double(0) // minimum value; 0 in 0…3
    var max  = Double(1) // maximum value; 3 in 0…3
    var dflt = Double(0) // default value; 1 in 0…3~1

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
        self.name = name
    }

    init(_ flo: Flo,_ name: String,_ num: Double) {
        super.init(flo, name)
        valOps = [.now_, .next] //?? .now
        self.min = fmin(num, 0.0)
        self.max = fmax(num, 1.0)
        self.now = num
        self.next = num
    }

    init (with scalar: FloValScalar) {
        super.init(scalar.flo, scalar.name)
        valOps = scalar.valOps // use default values
        min    = scalar.min
        max    = scalar.max
        dflt   = scalar.dflt
        now    = scalar.now
        next   = scalar.next
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
        if !valOps.next { //??
            setDefault(visit)
        }
    }

    // startup set values without animatin
    func bindNext() { //??

        if !valOps.next {
            setDefault(Visitor(.bind))
            now = next
        }
    }

    func setDefault(_ visit: Visitor) { // was setDefault

        if      valOps.dflt            { next = dflt }
        else if valOps.min, next < min { next = min  }
        else if valOps.max, next > max { next = max  }
        else if valOps.modu            { next = 0    }

        now = next
    }
    static func |= (lhs: FloValScalar, rhs: FloValScalar) {
        
        let mergeOps = lhs.valOps.rawValue |  rhs.valOps.rawValue
        lhs.valOps = FloValOps(rawValue: mergeOps)
        if rhs.valOps.min  { lhs.min = rhs.min }
        if rhs.valOps.max  { lhs.max = rhs.max }
        if rhs.valOps.next { lhs.next = rhs.next } //??
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
                                   noParens: Bool = false,
                                   viaEdge: Bool = false) -> String {
        if scriptOps.delta {
            if !hasDelta() {
                return ""
            }
            print("*** \(flo.name) [\(scriptOps.description)].[\(valOps.description)] : \(next)")
        }

        let script = scriptScalar(scriptOps)
        return (noParens ? script
                : script.isEmpty ? script
                : scriptOps.parens ? "(\(script))"
                : script)
    }

    func scriptScalar(_ scriptOps: FloScriptOps,
                      _ script: String = "") -> String {
        var str = ""
        if valOps.rawValue == 0   { return "" }
       
        if scriptOps.def {
            if valOps.min  { str += min.digits(0...6) }
            if valOps.thru { str += "…" } /// `…` is `⌥⃣;` on mac
            if valOps.thri { str += "_" } /// integer range for midi
            if valOps.modu { str += "%" } /// modulo
            if valOps.max  { str += max.digits(0...6) }
            if valOps.dflt { str += "~" + dflt.digits(0...6) }
        }
        if scriptOps.current && (valOps.next || valOps.lit) {
            str += (valOps == .lit || str.isEmpty && script.isEmpty) ? "" : "="
            str += next.digits(0...6)
        }
        if str.isEmpty, scriptOps.current {
            str += next.digits(0...6)
        }
        return str
    }
    override public func hasDelta() -> Bool {
        if valOps.next {
            if valOps.dflt {
                if next != dflt { return true }
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
    ///     - visit: ignored, see FloValExprs
    ///     - ops: set .now andor .next
    ///
    ///  - note: plugins set .now in a callback loop from plugin
    ///
    @discardableResult
    public override func setVal(_ val: Any?,
                                _ visit: Visitor,
                                _ ops: FloValOps) -> Bool {
        
        guard let val else { return true }

        switch val {
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
                if ops.next { next = (v.next - v.min) * (toRange / frRange) + min }

            } else if valOps.modu {

                min = 0
                max = Double.maximum(1, max)
                if ops.now_ { now = fmod(v.now, max) }
                if ops.next { next = fmod(v.next, max) }
            } else {
                
                setNextOpNow(v.next)
            }
        }

        func setNextOpNow(_ n: Double) {
            if ops.now_ { now = n }
            if ops.next { next = n }
            setInRange()
        }
        
        func setInRange() {
            if valOps.modu { next = fmod(next, max) }
            if valOps.min, next < min { next = min }
            if valOps.max, next > max { next = max }
        }
    }

    public override func getVal() -> Any {
        return now
    }

    public override func copy() -> FloValScalar {
        return FloValScalar(with: self)
    }
}
extension FloValScalar {

    func animateNowToNext(_ visit: Visitor) {
        if visit.from.tween {
            // already animating
            logNextNows("􀋽⁰")
        } else {
            logNextNows("􀋽⁼")
            now = next
        }
    }
    func testNextEqualNow() {
        if next == now {
            logNextNows("== ")
        }
    }
    func logNextNows(_ prefix: String,
                     _ suffix: String = "") {

        let id = "\(id)".pad(6)
        let path = flo.path(9).pad(-18)
        let nextNow = " (next: \(next.digits(2)) - now: \(now.digits(2))) "
        print(prefix + id + path + nextNow + suffix)
    }
}
