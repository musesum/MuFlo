
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
    public var opVals = ContiguousArray<FloOpVal>()

    /// set of all ops in exprs
    var opSet = Set<FloOp>()

    /// return _0, _1, ... for anonymous values
    var anonKey: String {
        String(format: "_%i", nameAny.keys.count)
    }
    var plugin: FloPlugin?

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, "_\(flo.name)")
    }
    override init(with floVal: FloVal) {
        super.init(with: floVal)

        if let v = floVal as? FloValExprs {
            
            valOps = v.valOps
            for (name, val) in v.nameAny {
                nameAny[name] = val
            }
            for opVal in v.opVals {
                opVals.append(FloOpVal(from: opVal))
            }
            opSet = v.opSet
        }
    }
    init(_ flo: Flo, point: CGPoint) {
        super.init(flo, "point")
        addPoint(point)
    }
    public init(_ flo: Flo, nameNums: [(String, Double)]) {
        super.init(flo, "nameNums")
        opSet = Set<FloOp>([.name,.num])

        for (name, num) in nameNums {
            if opVals.count > 0 {
                addOpStr(",")
            }
            addNameNum(name, num)
        }
    }

    override func copy() -> FloValExprs {
        return FloValExprs(with: self)
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
    @discardableResult
    public override func setVal(_ any: Any?,
                                _ visit: Visitor) -> Bool {
        guard let any else { return false }

        if !visit.newVisit(self.id) { return false }

        if !visit.from.tween,
           let plugin {

            visit.from += .tween
            setAnyVisit(visit)
            logNextNows(visit.log)
            plugin.startAnimating(id)
            return true

        } else if setAnyVisit(visit) {

            if !visit.from.tween {
                setNow()
            }
            return true
        }
        return false
        
        @discardableResult
        func setAnyVisit(_ visit: Visitor) -> Bool {
            switch any {
            case let v     as Float            : return set(Double(v),visit)
            case let v     as CGFloat          : return set(Double(v),visit)
            case let v     as Double           : return set(Double(v),visit)
            case let v     as CGPoint          : return set(v,visit)
            case let v     as FloValExprs      : return set(v,visit)
            case let n     as [(String,Any)]   : return set(n,visit)
            case let (n,v) as (String,Double)  : return set(n,Double(v),visit)
            case let (n,v) as (String,Float)   : return set(n,Double(v),visit)
            case let (n,v) as (String,CGFloat) : return set(n,Double(v),visit)
            default: print("🚫 mismatched setVal(\(any))"); return false
            }
        }

        func setNow() {

            for val in nameAny.values {
                if let v = val as? FloValScalar {
                    v.now = v.next
                }
            }
        }

        func set(_ fromExprs: FloValExprs,
                 _ visit: Visitor) -> Bool {

            // first evaluate source expression values
            fromExprs.evalExprs(nil,visit)
            // next evalute destination expression result
            let result = evalExprs(fromExprs, visit)
            return result
        }
        @discardableResult
        func set(_ name: String,
                 _ val: Double,
                 _ visit: Visitor) -> Bool {

            if let scalar = nameAny[name] as? FloValScalar {
                scalar.setVal(val, visit)
            } else {
                nameAny[name] = FloValScalar(flo, name, val)
            }
            valOps += .now
            return true
        }
        func set(_ nameVals: [(String,Any)],
                 _ visit: Visitor) -> Bool {

            for (name,any) in nameVals {
                switch any {
                case let v as Double  : set(name, Double(v), visit)
                case let v as Float   : set(name, Double(v), visit)
                case let v as CGFloat : set(name, Double(v), visit)
                case let v as Int     : set(name, Double(v), visit)
                default: break
                }
            }
            return true
        }

        func set(_ v: Double,
                 _ visit: Visitor) -> Bool {

            if let n = nameAny["val"] as? FloValScalar {
                
                n.setVal(v, visit)
                n.valOps += .now

            } else {

                nameAny["val"] = FloValScalar(flo, "val", v) //TODO: remove this kludge for DeepMenu
            }
            return true
        }

        func set(_ p: CGPoint,
                 _ visit: Visitor) -> Bool {

            if opVals.isEmpty {
                // create a new opVal list
                addPoint(p)
                return true
            }
            let copy = copy()
            copy.injectNameNum("x", Double(p.x))
            copy.injectNameNum("y", Double(p.y))
            return evalExprs(copy, visit)
        }
    }
    func bindNows() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.bindNow()
                }
            }
        }
    }
    func setDefaults(_ visit: Visitor) {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.setDefault(visit)
                }
            }
        }
    }

    
    public override func printVal() -> String {
        var script = "("
        for num in nameAny.values {
            script.spacePlus("\(num)")
        }
        return script.with(trailing: ")")
    }
    public override func scriptVal(_ scriptOpts: FloScriptOps) -> String {

        var script = ""
        script = scriptExprs(scriptOpts)
        return script.isEmpty ? "" : scriptOpts.parens ? "(\(script))" : script
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

