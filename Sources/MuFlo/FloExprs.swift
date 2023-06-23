
//  FloExprs.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import Foundation
import MuPar
import MuTime

public typealias NameAny = OrderedDictionaryClass<String,Any>
public class FloExprs: FloVal {

    static var IdExprs = [Int:FloExprs]()

    /// `t(x 1, y 2)` ⟹ `["x": 1, "y": 2]`
    public var nameAny = NameAny()

    /// `t(x/2, y/2) << u(x 1, y 2)` ⟹ `t(x 0.5, y 1.0)` // after u fires
    public var opAnys = ContiguousArray<FloOpAny>()

    /// return _0, _1, ... for anonymous values
    var anonKey: String { String(format: "_%i", nameAny.keys.count) }

    var plugDefs: EdgeDefs?
    var plugins = [FloPlugin]()

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, "_\(flo.name)")
    }

    init(from: FloExprs) {
        
        super.init(with: from)
        FloExprs.IdExprs[id] = self

        valOps = from.valOps
        for (name, val) in from.nameAny {
            switch val {
            case let v as FloValScalar : nameAny[name] = v.deepCopy(self)
            default                    : nameAny[name] = val
            }
        }
        for fromOpAny in from.opAnys {
            if fromOpAny.op == .scalar,
               let opScalar = fromOpAny.any as? FloValScalar {
                if let nameScalar = nameAny[opScalar.name] as? FloValScalar {
                    let opAny = FloOpAny(scalar: nameScalar)
                    opAnys.append(opAny)
                } else {
                    let opAny = FloOpAny(scalar: opScalar.deepCopy(self))
                    opAnys.append(opAny)
                }
            } else {
                let opAny = FloOpAny(from: fromOpAny)
                opAnys.append(opAny)
            }
        }
    }
    init(_ flo: Flo, point: CGPoint) {
        super.init(flo, "point")
        FloExprs.IdExprs[id] = self
        addPoint(point)
    }
    public init(_ flo: Flo,_ nameNums: [(String, Double)]) {
        super.init(flo, "nameNums")
        FloExprs.IdExprs[id] = self
        for (name, num) in nameNums {
            if opAnys.count > 0 {
                addOpStr(",")
            }
            addOpName(name, false)
            addDeepScalar(FloValScalar(flo, name, num))
        }
    }

    override func copy() -> FloExprs {
        return FloExprs(from: self)
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
            case let v as FloValScalar : nums.append(Double(v.twe))
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

    func logValTwees(_ suffix: String = "") {
        print()
        for (name,any) in nameAny {
            if let scalar = any as? FloValScalar {
                scalar.logValTweens("􁒖 \(name)".pad(8), suffix+"[\(scalar.valOps.description)]")
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
                setExprsVal(nameVals, visit)
            }
        }
    }
    
    @discardableResult
    public func setExprsVal(_ fromExprs: Any?,
                            _ visit: Visitor) -> Bool {

        guard let fromExprs else { return false }
        if !visit.newVisit(self.id) { return false }

        if visitPlugins(visit) {
            return true
        } else {
            return setFromVisit(fromExprs, visit)
        }


        func visitPlugins(_ visit: Visitor) -> Bool {

            guard let plugDefs else { return false }
            if plugDefs.isEmpty { return false }

            if plugins.isEmpty {
                setupPlugins()
            }

            if !visit.from.tween,
               !visit.from.remote,
               plugins.count > 0 {

                visit.from += .tween
                setFromVisit(fromExprs, visit)

                logValTwees(visitedPaths(visit)) //??? (visit.log)
                for plugin in plugins {
                    plugin.startPlugin(id)
                }
                return true
            }
            return false

            func setupPlugins() {

                for plugDef in plugDefs {
                    for edge in plugDef.edges.values {
                        if let leftExprs = edge.leftFlo.exprs,
                           let rightExprs = edge.rightFlo.exprs {
                            let plugin = FloPlugin(leftExprs,rightExprs)
                            plugins.append(plugin)
                        }
                    }
                }
            }
        }
    }
    func visitedPaths(_ visit: Visitor) -> String {

        var str = "("
        var del = ""
        for vid in visit.visited {
            if let flo = Flo.IdFlo[vid] {

                let path = flo.path(99)
                str += del + path + ":\(vid)"
                del = ", "
            } else if let exprs = FloExprs.IdExprs[vid] {

                let path = exprs.flo.path(99)
                str += del + path + "(\(exprs.name):\(vid))"
                del = ", "
            }

        }
        str += ")"
        return str
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
        case let v     as FloExprs         : return setExprs(v,visit)
        case let n     as [(String,Any)]   : return setNameNums(n,visit)

        case let (n,v) as (String,Double)  : return setNameNum(n,Double(v),visit)
        case let (n,v) as (String,Float)   : return setNameNum(n,Double(v),visit)
        case let (n,v) as (String,CGFloat) : return setNameNum(n,Double(v),visit)
        default: print("🚫 mismatched setVal(\(any))"); return false
        }
    }

    // set expression
    func setExprs(_ fromExprs: FloExprs,
                  _ visit: Visitor) -> Bool {

        // next evalute destination expression result
        let result = evalExprs(fromExprs, false, visit)
        if result == false {
            clearCurrentVals()
        }
        return result
    }

    /// when match fails, clear out current values set next to default
    func clearCurrentVals() {
        for key in nameAny.keys {
            if let val = nameAny[key] as? FloVal {
                val.valOps -= [.twe,.val]
                if let scalar = val as? FloValScalar {
                    if val.valOps.lit || val.valOps.dflt {
                        scalar.val = scalar.dflt
                    }
                }
            }
        }
    }
    // set name double
    @discardableResult
    func setNameNum(_ name: String,
                    _ num: Double,
                    _ visit: Visitor) -> Bool {

        let ops: FloValOps = (plugins.isEmpty ? [.twe, .val] : [.val])

        if let scalar = nameAny[name] as? FloValScalar {
            scalar.setScalarVal(num, ops)
        } else {
            nameAny[name] = FloValScalar(flo, name, num)
        }
        valOps += .val //??? op?
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
    func setNum(_ val: Double,
                _ visit: Visitor) -> Bool {

        let ops: FloValOps
        if plugins.isEmpty {
            print("¬⃣", terminator: "")
            ops = [.twe, .val]
        } else {
            print("+⃣", terminator: "")
            ops = [.val]
        }

        if let scalar = nameAny["_0"] as? FloValScalar {

            scalar.setScalarVal(val, ops)
            return true

        } else {

            for any in nameAny.values {
                if let scalar = any as? FloValScalar {
                    scalar.setScalarVal(val, ops)
                    return true
                }
            }

        }
        if nameAny.isEmpty {
            let name = "_" + flo.name
            nameAny["_0"] = FloValScalar(flo, name, val)
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
        let result = evalExprs(copy, false, visit)
        if result == false {
            clearCurrentVals()
        }
        return result
    }
    // now = dflt, next = dflt
    func bindVals() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? FloValScalar {
                    scalar.bindVal()
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
    public func script(_ scriptOps: FloScriptOps = .All) -> String {
        return scriptVal(scriptOps)
    }
    public override func scriptVal(_ scriptOps: FloScriptOps,
                                   noParens: Bool = false) -> String {

        let script = scriptExprs(scriptOps)

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

