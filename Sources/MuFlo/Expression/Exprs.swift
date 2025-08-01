//  Express.swift
//  created by musesum on 4/4/19.

import QuartzCore
import Collections
import Foundation

public class Exprs: FloVal {

    nonisolated(unsafe) public static var IdExprs = [Int: Exprs]()

    /// `t(x 1, y 2)` ⟹ `["x": 1, "y": 2]`
    public var nameAny = NameAny()

    /// `t(x/2, y/2) << u(x 1, y 2)` ⟹ `t(x 0.5, y 1.0)` // after u fires
    public var evalAnys = EvalAnys()

    var hasValue: Bool { return !nameAny.isEmpty || !evalAnys.isEmpty }

    public func normalize(_ name: String, _ normOp: ScalarOps) -> Double? {
        if let scalar = nameAny[name] as? Scalar {
            return scalar.normalized(normOp)
        }
        return nil
    }

    /// return _0, _1, ... for anonymous values
    var anonKey: String { String(format: "_%i", nameAny.keys.count) }

    public func includesOp(_ op: EvalOp) -> Bool {
        for evalAny in evalAnys {
            if evalAny.op == op { return true }
        }
        return false
    }
    public subscript(_ subName: String, _ scalarOps: ScalarOps) -> Double? {
        if let scalar = nameAny[subName] as? Scalar {
            switch scalarOps {
            case .value: return scalar.value
            case .tween: return scalar.tween
            default: return err("\(#function) unknown return")
            }
        }
        return err("name: \(name)(\(subName)) not found")
        func err(_ msg: String) -> Double? {
            PrintLog("⁉️ \(msg) scalarOps: [\(scalarOps.description)]");
            return nil
        }
    }

    public init(_ flo: Flo) {
        super.init(flo, "_\(flo.name)")
    }
    public init(_ flo: Flo, _ name: String, _ any: Any? = nil) {
        super.init(flo, "_\(flo.name)")
        if let any {
            nameAny[name] = any
        }
    }
    init(from: Exprs) {
        
        super.init(with: from)
        Exprs.IdExprs[id] = self

        //options = from.options
        for (name, val) in from.nameAny {
            switch val {
            case let v as Scalar : nameAny[name] = v.deepCopy(self)
            default              : nameAny[name] = val
            }
        }
        for fromAny in from.evalAnys {
            if fromAny.op == .scalar,
               let opScalar = fromAny.any as? Scalar {
                if let nameScalar = nameAny[opScalar.name] as? Scalar {
                    evalAnys.append(EvalAny(scalar: nameScalar))
                } else {
                    evalAnys.append(EvalAny(scalar: opScalar.deepCopy(self)))
                }
            } else {
                evalAnys.append(EvalAny(from: fromAny))
            }
        }
    }
    init(_ flo: Flo, _ point: CGPoint) {
        super.init(flo, "_" + flo.name)
        Exprs.IdExprs[id] = self
        addPoint(point)
    }
    init(_ flo: Flo, _ size: CGSize) {
        super.init(flo, "_" + flo.name)
        Exprs.IdExprs[id] = self
        addSize(size)
    }
    public init(_ flo: Flo, _ rect: CGRect) {
        super.init(flo, "_" + flo.name)
        Exprs.IdExprs[id] = self
        addRect(rect)
    }
    
    public init(_ flo: Flo,_ nameNums: [(String, Double)]) {
        super.init(flo, "nameNums")
        Exprs.IdExprs[id] = self
        for (name, num) in nameNums {
            if evalAnys.count > 0 {
                addOpStr(",")
            }
            addOpName(name, false)
            addDeepScalar(Scalar(flo, name, num), name)
        }
    }

    override func copy() -> Exprs {
        return Exprs(from: self)
    }

    func copy(_ flo: Flo) -> Exprs {
        let exprs = Exprs(from: self)
        exprs.flo = flo
        return exprs
    }

    // MARK: - Get
    
    public override func getVal() -> Any {

        if let cgPoint = getCGPoint() { return cgPoint }
        if let nums = getNums() { return nums }

        if nameAny.values.count > 0 { return nameAny.values }
        PrintLog("⁉️ unknown expression values for \(flo.path(9))")
        return [] as [Double]
    }
    /// used for metal shader in Sky
    public func getValFloats() -> [Float] {
        var nums = [Float]()
        for value in nameAny.values {
            switch value {
            case let v as Scalar : nums.append(Float(v.tween))
            case let v as CGFloat      : nums.append(Float(v))
            case let v as Float        : nums.append(v)
            case let v as Double       : nums.append(Float(v))
            default : continue // skip strings, tec
            }
        }
        return nums
    }

    // MARK: - Set

    func logValTweens(_ suffix: String = "") {
        for any in nameAny.values {
            if let scalar = any as? Scalar {
                let opsStr = " [\(scalar.scalarOps.description)]"
                scalar.logValTweens("􁒖", opsStr + suffix)
            }
        }
    }

    func setDefaults(_ setOps: SetOps, _ visit: Visitor, _ withPrior: Bool) {
        var nameVals = [(String,Double)]()
        if nameAny.count > 0 {
            for (name,any) in nameAny {
                if let scalar = any as? Scalar {
                    if scalar.scalarOps.origin, scalar.value != scalar.origin {
                        nameVals.append((name, scalar.origin))
                    } else if withPrior,
                              scalar.prior != scalar.value {
                        nameVals.append((name, scalar.prior))
                    }
                }
            }
            if nameVals.count > 0 {
                setFromAny(nameVals, setOps, visit)
            }
        }
    }

    public func setOrigin(_ visit: Visitor) {
        var nameVals = [(String,Double)]()
        if nameAny.count > 0 {
            for (name,any) in nameAny {
                if let scalar = any as? Scalar {
                    nameVals.append((name, scalar.origin))
                }
            }
            if nameVals.count > 0 {
                setFromAny(nameVals, [], visit)
            }
        }
    }

    public func setPrior(_ visit: Visitor) {
        var nameVals = [(String,Double)]()
        if nameAny.count > 0 {
            for (name,any) in nameAny {
                if let scalar = any as? Scalar {
                    nameVals.append((name, scalar.prior))
                }
            }
            if nameVals.count > 0 {
                setFromAny(nameVals, [], visit)
            }
        }
    }

    @discardableResult
    public func setFromAny(_ fromAny: Any,
                           _ setOps: SetOps,
                           _ visit: Visitor) -> Bool {

        guard visit.newVisit(id) else { return false }

        if updateValues(setOps) {
            if newTween() {
                pluginTween()
            }
            return true
        }
        return false

        func updateValues(_ setOps: SetOps) -> Bool {
            switch fromAny {
            case let v     as Float              : setNum(Double(v),setOps,visit)
            case let v     as CGFloat            : setNum(Double(v),setOps,visit)
            case let v     as Double             : setNum(Double(v),setOps,visit)
            case let v     as Int                : setNum(Double(v),setOps,visit)
            case let n     as [(String,Float)]   : setNameNums(n,setOps,visit)
            case let n     as [(String,CGFloat)] : setNameNums(n,setOps,visit)
            case let n     as [(String,Double )] : setNameNums(n,setOps,visit)
            case let n     as [(String,Int    )] : setNameNums(n,setOps,visit)
            case let (n,v) as (String,Double)    : setNameNum(n,Double(v),setOps,visit)
            case let (n,v) as (String,Float)     : setNameNum(n,Double(v),setOps,visit)
            case let (n,v) as (String,CGFloat)   : setNameNum(n,Double(v),setOps,visit)
            case let (n,a) as (String,Any)       : setNameAnys([(n,a)])
            case let n     as [(String,Any)]     : setNameAnys(n)
            //TODO: the next three are overloading setValues with an evaluation test
            case let v     as CGPoint            : return evalPoint(v,setOps,visit)
            case let v     as CGRect             : return evalRect (v,setOps,visit)
            case let v     as CGSize             : return evalSize (v,setOps,visit)
            case let v     as Exprs              : return evalExprs(v,false,setOps,visit)
            default: PrintLog("⁉️ mismatched setVal(\(fromAny))"); return false
            }
            return true

            func setNameAnys(_ nameAnys: [(Name,Any)]) { //... no setOps?
                for (name,any) in nameAnys {
                    nameAny[name] = any
                }
            }
            func setNameNum(_ name: String, _ num: Double, _ setOps: SetOps, _ visit: Visitor) {
                if let scalar = nameAny[name] as? Scalar {
                    scalar.setScalarVal(num, flo.scalarOps, setOps)
                } else {
                    nameAny[name] = Scalar(flo, name, num)
                }
            }
            func setNameNums(_ nameAnys: [(String,Any)], _ setOps: SetOps, _ visit: Visitor) {
                for (name,any) in nameAnys {
                    switch any {
                    case let v as Double  : setNameNum(name, Double(v), setOps, visit)
                    case let v as Float   : setNameNum(name, Double(v), setOps, visit)
                    case let v as CGFloat : setNameNum(name, Double(v), setOps, visit)
                    case let v as Int     : setNameNum(name, Double(v), setOps, visit)
                    default: break
                    }
                }
            }
            func setNum(_ num: Double, _ setOps: SetOps, _ visit: Visitor) {

                if let scalar = nameAny["_0"] as? Scalar {

                    scalar.setScalarVal(num, flo.scalarOps, setOps)

                } else {

                    for any in nameAny.values {
                        if let scalar = any as? Scalar {
                            scalar.setScalarVal(num, flo.scalarOps, setOps)
                        }
                    }
                }
                if nameAny.isEmpty {
                    let name = "_" + flo.name
                    nameAny["_0"] = Scalar(flo, name, num)
                }
            }
            func evalPoint(_ point: CGPoint, _ setOps: SetOps, _ visit: Visitor) -> Bool {

                if evalAnys.isEmpty {
                    // create a new opVal list
                    addPoint(point)
                    return true
                }
                let copy = copy()
                copy.injectNameNum("x", Double(point.x))
                copy.injectNameNum("y", Double(point.y))
                return evalExprs(copy, false, setOps, visit)
            }
            func evalSize(_ size: CGSize, _ setOps: SetOps, _ visit: Visitor) -> Bool {

                if evalAnys.isEmpty {
                    // create a new opVal list
                    addSize(size)
                    return true
                }
                let copy = copy()
                copy.injectNameNum("w", Double(size.width))
                copy.injectNameNum("h", Double(size.height))

                return evalExprs(copy, false, setOps, visit)
            }
            func evalRect(_ rect: CGRect, _ setOps: SetOps, _ visit: Visitor) -> Bool {

                if evalAnys.isEmpty {
                    // create a new opVal list
                    addRect(rect)
                    return true
                }
                let copy = copy()
                copy.injectNameNum("x", Double(rect.minX))
                copy.injectNameNum("y", Double(rect.minY))
                copy.injectNameNum("w", Double(rect.width))
                copy.injectNameNum("h", Double(rect.height))

                return evalExprs(copy, false, setOps, visit)
            }
        }
        func newTween() -> Bool {
            if flo.hasPlugDefs,
               flo.hasPlugins,
               !visit.type.has(.tween) {
                return true
            }
            return false
        }
        func pluginTween() {
            // logValTweens(logVisitedPaths(visit))
            for plugin in flo.plugins {
                plugin.startPlugin(flo.id, visit)
            }
        }
    }
    // val = origin, twe = origin
    func bindVals() {
        if nameAny.count > 0 {
            for value in nameAny.values {
                if let scalar = value as? Scalar {
                    scalar.bindVal()
                }
            }
        }
    }
    // MARK: - Script

    public override func printVal(_ flo: Flo) -> String {
        var script = "("
        for num in nameAny.values {
            script.spacePlus("\(num)")
        }
        return script.with(trailing: ")")
    }

    public override func scriptVal(_ from: Flo,
                                   _ scriptOps: FloScriptOps,
                                   viaEdge: Bool,
                                   noParens: Bool = false) -> String {

        var script = scriptExprs(scriptOps, viaEdge)

        if !viaEdge, scriptOps.edge {

            let edgeScript = from.scriptEdgeDefs(scriptOps)
            script.commaPlus(edgeScript)
        }

        return (noParens ? script
                : script.isEmpty ? script
                : scriptOps.parens ? "(\(script))"
                : script)
    }
    override public func hasDelta() -> Bool { //TODO: refactor scalarOp into Scalar
        for val in nameAny.values {
            if let val = val as? FloVal, val.hasDelta() {
                return true
            }
        }
        return false
    }
}

