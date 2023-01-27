
//  FloExprs.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import Foundation
import MuPar

public class FloExprs: FloVal {

    /// `t(x 1, y 2)` ⟹ `["x": 1, "y": 2]`
    public var nameAny: OrderedDictionary<String,Any> = [:]

    /// `t(x/2, y/2) << u(x 1, y 2)` ⟹ `t(x 0.5, y 1.0)` // after u fires
    public var exprs = ContiguousArray<FloExpr>()

    /// set of all ops in exprs
    var opSet = Set<FloExprOp>()

    /// return _0, _1, ... for anonymous values
    var anonKey: String {
        String(format: "_%i", nameAny.keys.count)
    }

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
    }
    override init(with floVal: FloVal) {
        super.init(with: floVal)

        if let v = floVal as? FloExprs {
            
            valFlags = v.valFlags
            for (name, val) in v.nameAny {
                nameAny[name] = val
            }
            for expr in v.exprs {
                exprs.append(FloExpr(from: expr))
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
        opSet = Set<FloExprOp>([.name,.num])

        for (name, num) in nameNums {
            if exprs.count > 0 {
                addOpStr(",")
            }
            addNameNum(name, num)
        }
    }
    override func copy() -> FloExprs {
        let newFloExprs = FloExprs(with: self)
        return newFloExprs
    }

    // MARK: - Get
    public override func getVal() -> Any {

        if let cgPoint = getCGPoint() { return cgPoint }
        if let nums = getNums() { return nums }

        if nameAny.values.count > 0 { return nameAny.values }
        print("*** unknown expression values")
        return []
    }
    /// used for metal shader in Sky
    public func getValNums() -> [Double] {
        var nums = [Double]()
        for value in nameAny.values {
            switch value {
                case let v as FloValScalar: nums.append(Double(v.now))
                case let v as CGFloat: nums.append(Double(v))
                case let v as Float: nums.append(Double(v))
                case let v as Double: nums.append(v)
                default: nums.append(0)
            }
        }
        if nums.isEmpty {
            print("*** unknown expression values")
        }
        return nums
    }
    // MARK: - Set
    public override func setVal(_ any: Any?, //???
                                _ visitor: Visitor) -> Bool {
        guard let any else { return false }

        switch any {
            case let v as Float:    return setDouble(Double(v), visitor)
            case let v as CGFloat:  return setDouble(Double(v), visitor)
            case let v as Double:   return setDouble(Double(v), visitor)
            case let v as CGPoint:  return setPoint(v, visitor)
            case let v as FloExprs: return setExprs(v, visitor)
            case let (n,v) as (String,Float):   return setNamed(n, Double(v), visitor)
            case let (n,v) as (String,Double):  return setNamed(n, Double(v), visitor)
            case let (n,v) as (String,CGFloat): return setNamed(n, Double(v), visitor)
            default: print("🚫 mismatched setVal(\(any))")
        }
        return false

        func setExprs(_ exprs: FloExprs,
                      _ visitor: Visitor) -> Bool {

            if !visitor.newVisit(id) { return false }
            _ = exprs.evalExprs(nil,visitor)
            return evalExprs(exprs, visitor)
        }
        func setNamed(_ name: String,
                      _ value: Double,
                      _ visitor: Visitor) -> Bool {

            if let scalar = nameAny[name] as? FloValScalar {
                _ = scalar.setVal(value, visitor)
            } else {
                nameAny[name] = FloValScalar(flo, name: name, num: value)
            }
            addFlag(.now)
            return true
        }

        func setDouble(_ v: Double,
                       _ visitor: Visitor) -> Bool {

            if let n = nameAny["val"] as? FloValScalar {
                _ = n.setVal(v, visitor)
                n.addFlag(.now)
            }
            else {
                nameAny["val"] = FloValScalar(flo, name: "val", num: v) //TODO: remove this kludge for DeepMenu
            }
            return true
        }

        func setPoint(_ p: CGPoint,
                      _ visitor: Visitor) -> Bool {

            if exprs.isEmpty {
                // create a new expr list
                addPoint(p)
                return true
            }
            let copy = copy()
            copy.injectNameNum("x", Double(p.x))
            copy.injectNameNum("y", Double(p.y))
            return evalExprs(copy, visitor)
        }
    }
    func setNows() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.setNow()
                }
            }
        }
    }
    func setDefaults() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.setDefault()
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
    public override func scriptVal(_ scriptFlags: FloScriptFlags) -> String {

        var script = ""
        script = scriptExprs(scriptFlags)
        return script.isEmpty ? "" : scriptFlags.parens ? "(\(script))" : script
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
