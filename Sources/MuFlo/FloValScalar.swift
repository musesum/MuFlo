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
    public var now = Double(0) // current value; 2 in 0…3=1:2
    var next = Double(0) // target value
    
    var min  = Double(0) // minimum value; 0 in 0…3
    var max  = Double(1) // maximum value; 3 in 0…3
    var dflt = Double(0) // default value; 1 in 0…3=1

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
        self.name = name
    }

    init(_ flo: Flo,_ name: String,_ num: Double) {
        super.init(flo, name)
        valOps = .now
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
    func setNowDefault(_ visit: Visitor) {

        if !valOps.now {
            setDefault(visit)
        }
    }

    // startup set values without animatin
    func bindNow() { // was setDefault //??

        if !valOps.now {
            setDefault(Visitor(.bind))
            now = next
        }
    }

    func setDefault(_ visit: Visitor) { // was setDefault

         if     valOps.dflt           { next = dflt }
        else if valOps.min, now < min { next = min  }
        else if valOps.max, now > max { next = max  }
        else if valOps.modu           { next = 0    }

        // testNextEqualNow()
    }
    static func |= (lhs: FloValScalar, rhs: FloValScalar) {
        
        let mergeOps = lhs.valOps.rawValue |  rhs.valOps.rawValue
        lhs.valOps = FloValOps(rawValue: mergeOps)
        if rhs.valOps.min  { lhs.min = rhs.min }
        if rhs.valOps.max  { lhs.max = rhs.max }
        if rhs.valOps.now { lhs.now = rhs.now }
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

    public override func scriptVal(_ scriptOpts: FloScriptOps) -> String {

        if scriptOpts.delta {
            if !hasDelta() {
                return ""
            }
            print("*** \(flo.name) [\(scriptOpts.description)].[\(valOps.description)] : \(now)")
        }

        var script = scriptOpts.parens ? "(" : ""
        if valOps.rawValue == 0   { return "" }

        if scriptOpts.def {
            if valOps.min  { script += min.digits(0...6) }
            if valOps.thru { script += "…" } // … is option+semicolon ⌥⃣; on mac keyboard
            if valOps.thri { script += "_" }
            if valOps.modu { script += "%" }
            if valOps.max  { script += max.digits(0...6) }
            if valOps.dflt { script += "=" + dflt.digits(0...6) }
            if valOps.lit  { script += now.digits(0...6) }
            if scriptOpts.now {
                if valOps.lit, now == dflt {
                    /// skip as `dflt` will set `now` anyway
                 } else {
                    script += ":" + now.digits(0...6)
                }
            }
        } else if scriptOpts.now {
            if valOps.lit, now == dflt {
                script += now.digits(0...6)
            } else {
                script += ":" + now.digits(0...6)
            }
        } else if valOps.lit {
            script += now.digits(0...6)
        }
        script += scriptOpts.parens ? ")" : ""
        return script
    }
    
    override public func hasDelta() -> Bool {
        if valOps.now {
            if valOps.dflt {
                if now != dflt { return true }
            } else {
                return true
            }
        }
        return false
    }

    // MARK: - set

    @discardableResult
    public override func setVal(_ val: Any?,
                                _ visit: Visitor) -> Bool {
        
        guard let val else { return true }

        switch val {
        case let v as FloValScalar : setFrom(v)
        case let v as Double       : setNextOpNow(v)
        case let v as Float        : setNextOpNow(Double(v))
        case let v as CGFloat      : setNextOpNow(Double(v))
        case let v as Int          : setNextOpNow(Double(v))
        default: print("🚫 setVal unknown type for: from")
        }
        if !visit.from.tween {
            now = next
        }
        // testNextEqualNow()
        return true


        /// map ranges between doubles and quasi integers
        ///
        ///     0…1 is a double
        ///     0_127 is an integer
        ///
        /// - note: this is a kludge, should use something else for counting integers
        func setFrom(_ v: FloValScalar) {

            if valOps.thrui,
               v.valOps.thrui {

                let toRange = (  max -   min) + (   valOps.thri ? 1.0 : 0.0)
                let frRange = (v.max - v.min) + ( v.valOps.thri ? 1.0 : 0.0)
                now = (v.now - v.min) * (toRange / frRange) + min
                next = (v.next - v.min) * (toRange / frRange) + min
                valOps += .now

            } else if valOps.modu {

                min = 0
                max = Double.maximum(1, max)
                now = fmod(v.now, max) 
                next = fmod(v.next, max)
            } else {
                
                setNextOpNow(v.next)
            }
        }

        func setNextOpNow(_ n: Double) {
            next = n
            valOps += .now
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

    public override func copy() -> FloVal {
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
