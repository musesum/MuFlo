
//  FloValExprs.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import Foundation
import MuPar
import MuTime

public class FloValExprs: FloVal {

    /// `t(x 1, y 2)` ⟹ `["x": 1, "y": 2]`
    public var nameAny: OrderedDictionary<String,Any> = [:]

    /// `t(x/2, y/2) << u(x 1, y 2)` ⟹ `t(x 0.5, y 1.0)` // after u fires
    public var opAnys = ContiguousArray<FloOpAny>()

    /// return _0, _1, ... for anonymous values
    var anonKey: String { String(format: "_%i", nameAny.keys.count) }

    var plugin: FloPlugin?

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, "_\(flo.name)")
        
    }
    init(from: FloValExprs) {
        super.init(with: from)

        valOps = from.valOps
        for (name, val) in from.nameAny {
            switch val {
            case let v as FloValScalar  : nameAny[name] = v.copy()
            case let v as FloValExprs   : nameAny[name] = v.copy()
            case let v as FloVal        : nameAny[name] = v.copy()
            default                     : nameAny[name] = val
            }
        }
        for opVal in from.opAnys {
            opAnys.append(FloOpAny(from: opVal))
        }
    }
    init(_ flo: Flo, point: CGPoint) {
        super.init(flo, "point")
        addPoint(point)
    }
    public init(_ flo: Flo,_ nameNums: [(String, Double)]) {
        super.init(flo, "nameNums")

        for (name, num) in nameNums {
            if opAnys.count > 0 {
                addOpStr(",")
            }
            addOpName(name, false)
            addDeepScalar(FloValScalar(flo, name, num))
        }
    }

    override func copy() -> FloValExprs {
        return FloValExprs(from: self)
    }

    // MARK: - Get
    
    public override func getVal() -> Any {

        if let cgPoint = getCGPoint() { return cgPoint }
        if let nums = getNums() { return nums }

        if nameAny.values.count > 0 { return nameAny.values }
        print("*** unknown expression values")
        return [] as [Double]
    }
    /// used for metal shader in Sky
    public func getValNums() -> [Double] {
        var nums = [Double]()
        for value in nameAny.values {
            switch value {
            case let v as FloValScalar : nums.append(Double(v.now))
            case let v as CGFloat      : nums.append(Double(v))
            case let v as Float        : nums.append(Double(v))
            case let v as Double       : nums.append(v)
            default                    : nums.append(0)
            }
        }
        if nums.isEmpty {
            print("*** unknown expression values")
        }
        return nums
    }
    // MARK: - Set

    func logNextNows(_ suffix: String = "") {
        for val in nameAny.values {
            if let val = val as? FloValScalar {
                val.logNextNows("􁒖 ", suffix)
            }
        }
    }
    func setDefaults(_ visit: Visitor) {
        var nameVals = [(String,Double)]()
        if nameAny.count > 0 {
            for (name,any) in nameAny {
                if let scalar = any as? FloValScalar,
                   scalar.valOps.dflt {
                    let nameVal = (name, scalar.dflt)
                    nameVals.append(nameVal)
                }
            }
            if nameVals.count > 0 {
                setVal(nameVals, visit, [])
            }
        }
    }

    @discardableResult
    public override func setVal(_ fromVal: Any?,
                                _ visit: Visitor,
                                _ _: FloValOps) -> Bool {

        guard let fromVal else { return false }
        if !visit.newVisit(self.id) { return false }

        if !visit.from.tween,
           !visit.from.remote,
           let plugin {

            visit.from += .tween
            setFromVisit(fromVal, visit)
            logNextNows(visit.log)
            plugin.startPlugin(id)
            return true

        } else if setFromVisit(fromVal, visit) {

            if !visit.from.tween {
                setNow()
            }
            return true
        }
        return false
    }
    func setNow() {

        for val in nameAny.values {
            if let v = val as? FloValScalar {
                v.now = v.next
            }
        }
    }

    @discardableResult
    func setFromVisit(_ any: Any,
                     _ visit: Visitor) -> Bool {

        switch any {
        case let v     as Float            : return setNum(Double(v),visit)
        case let v     as CGFloat          : return setNum(Double(v),visit)
        case let v     as Double           : return setNum(Double(v),visit)
        case let v     as Int              : return setNum(Double(v),visit)

        case let v     as CGPoint          : return setPoint(v,visit)
        case let v     as FloValExprs      : return setExprs(v,visit)
        case let n     as [(String,Any)]   : return setNameNums(n,visit)

        case let (n,v) as (String,Double)  : return setNameNum(n,Double(v),visit)
        case let (n,v) as (String,Float)   : return setNameNum(n,Double(v),visit)
        case let (n,v) as (String,CGFloat) : return setNameNum(n,Double(v),visit)
        default: print("🚫 mismatched setVal(\(any))"); return false
        }
    }

    // set expression
    func setExprs(_ fromExprs: FloValExprs,
                  _ visit: Visitor) -> Bool {


        // next evalute destination expression result
        let result = evalExprs(fromExprs, visit)
        if result == false {
            clearCurrentVals()
        }
        return result
    }

    func clearCurrentVals() {
        for key in nameAny.keys {
            if let val = nameAny[key] as? FloVal {
                //.... val.valOps -= [.now_,.next]
                if let scalar = val as? FloValScalar {
                    if val.valOps.lit || val.valOps.dflt {
                        scalar.next = scalar.dflt //...
                    }
                }
            }
        }
    }
    // set name double
    @discardableResult
    func setNameNum(_ name: String,
                    _ val: Double,
                    _ visit: Visitor) -> Bool {

        let ops: FloValOps = (plugin == nil ? [.now_, .next] : [.next])

        if let scalar = nameAny[name] as? FloValScalar {
            scalar.setVal(val, visit, ops)
        } else {
            nameAny[name] = FloValScalar(flo, name, val)
        }
        valOps += .next //??? 
        return true
    }
    // set [(name,any)]
    func setNameNums(_ nameVals: [(String,Any)],
                  _ visit: Visitor) -> Bool {

        for (name,any) in nameVals {
            switch any {
            case let v as Double  : setNameNum(name, Double(v), visit)
            case let v as Float   : setNameNum(name, Double(v), visit)
            case let v as CGFloat : setNameNum(name, Double(v), visit)
            case let v as Int     : setNameNum(name, Double(v), visit)
            default: break
            }
        }
        return true
    }

    // set anonymous ("val", double)
    func setNum(_ v: Double,
                _ visit: Visitor) -> Bool {

        let ops: FloValOps = (plugin == nil ? [.now_, .next] : [.next])

        if let n = nameAny["_0"] as? FloValScalar {

            n.setVal(v, visit, ops)

        } else if let n = nameAny["val"] as? FloValScalar {

            n.setVal(v, visit, ops)

        } else {
            
            nameAny["val"] = FloValScalar(flo, "val", v) //??? TODO: remove this kludge for DeepMenu
        }
        return true
    }

    // set [("x",x), ("y",y)]
    func setPoint(_ p: CGPoint,
                  _ visit: Visitor) -> Bool {

        if opAnys.isEmpty {
            // create a new opVal list
            addPoint(p)
            return true
        }
        let copy = copy()
        copy.injectNameNum("x", Double(p.x))
        copy.injectNameNum("y", Double(p.y))
        let result = evalExprs(copy, visit)
        if result == false {
            clearCurrentVals()
        }
        return result
    }
    // now = dflt, next = dflt
    func bindNexts() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.bindNext()
                }
            }
        }
    }
    // MARK: - Script

    public override func printVal() -> String {
        var script = "("
        for num in nameAny.values {
            script.spacePlus("\(num)")
        }
        return script.with(trailing: ")")
    }
    public override func scriptVal(_ scriptOps: FloScriptOps,
                                   noParens: Bool = false,
                                   viaEdge: Bool = false) -> String {

        let script = scriptExprs(scriptOps, viaEdge: viaEdge)

        return (noParens ? script
                : script.isEmpty ? script
                : scriptOps.parens ? "(\(script))"
                : script)
    }
    override public func hasDelta() -> Bool {
        for val in nameAny.values {
            if let val = val as? FloVal, val.hasDelta() {
                return true
            }
        }
        return false
    }
}

