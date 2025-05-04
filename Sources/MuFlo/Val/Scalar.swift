//  Scalar.swift
//  created by musesum on 4/4/19.

import QuartzCore
import Foundation

public class Scalar: FloVal {

    public static let blank = Scalar(Flo(), "blank")
    public var scalarOps = ScalarOps(rawValue: 0)
    public var scalarState: ScalarState { ScalarState(self) }

    public var tween = Double(0) // current value; 2 in 0…3=1=2
    public var value = Double(0) // target value
    public var minim = Double(0) // minimum value; 0 in 0…3
    public var maxim = Double(1) // maximum value; 3 in 0…3
    public var origin = Double(0) // default value; 1 in 0…3=1
    public var prior = Double(0) // prevous value; for animating tween

    override init(_ flo: Flo, _ name: String?) {
        let name = name ?? "_"
        super.init(flo, name)
        self.name = name
    }

    init(_ flo: Flo,_ name: String,_ num: Double) {
        super.init(flo, name)
        scalarOps = [.value]
        self.minim = fmin(num, 0.0)
        self.maxim = fmax(num, 1.0)
        self.value = num
        self.tween = num
        self.prior = value
    }

    init (with scalar: Scalar, viaEval: Bool = false) {
        super.init(scalar.flo, scalar.name)
        scalarOps = scalar.scalarOps // use default values
        if viaEval { scalarOps -= .liter }
        minim  = scalar.minim
        maxim  = scalar.maxim
        origin  = scalar.origin
        tween = scalar.tween
        value = scalar.value
        prior = value
    }

    public func normalized(_ normOps: ScalarOps) -> Double {
        if scalarOps.contains([.minim,.maxim]) {
            let range = maxim - minim
            if normOps.tween {
                let ret = (tween - minim) / range
                return ret
            } else if normOps.value {
                let ret = (value - minim) / range
                return ret
            }
        }
        return value
    }
    public func range() -> ClosedRange<Double> {
        if minim <= maxim { return minim...maxim }
        else          { return minim...(minim+1) }
    }

    // startup set values without animation
    func bindVal() {

        if !scalarOps.value {
            let visit = Visitor(0,.bind)
            setDefault(visit, /* withPrior */ false)
            tween = value
        }
    }

    func setDefault(_ visit: Visitor, _ withPrior: Bool) { // was setDefault
        prior = tween
        if      scalarOps.origin             { value = origin  }
        else if scalarOps.minim, value < minim { value = minim  }
        else if scalarOps.maxim, value > maxim { value = maxim  }
        else if scalarOps.modulo             { value = 0     }
        tween = value
    }
    static func |= (lhs: Scalar, rhs: Scalar) {
        
        let mergeOps = lhs.scalarOps.rawValue |  rhs.scalarOps.rawValue
        lhs.scalarOps = ScalarOps(rawValue: mergeOps)
        if rhs.scalarOps.minim { lhs.minim = rhs.minim }
        if rhs.scalarOps.maxim { lhs.maxim = rhs.maxim }
        if rhs.scalarOps.value { lhs.value = rhs.value } 
    }

    public static func == (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween == rhs.tween }
    public static func >= (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween >= rhs.tween }
    public static func >  (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween >  rhs.tween }
    public static func <= (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween <= rhs.tween }
    public static func <  (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween <  rhs.tween }
    public static func != (lhs: Scalar,
                           rhs: Scalar) -> Bool { return lhs.tween != rhs.tween }

    public func inRange(from: Double) -> Bool {

        if scalarOps.modulo, from > maxim { return false }
        if scalarOps.minim, from < minim { return false }
        if scalarOps.maxim, from > maxim { return false }
        return true
    }

    public override func printVal(_ flo: Flo) -> String {
        return String(tween)
    }

    public override func scriptVal(_ from: Flo,
                                   _ scriptOps: FloScriptOps,
                                   viaEdge: Bool,
                                   noParens: Bool = false) -> String {
        if scriptOps.delta {
            if !hasDelta() {
                return ""
            }
            PrintLog("⁉️ \(flo.name) [\(scriptOps.description)].[\(scalarOps.description)] : \(value)")
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
    func scriptScalar(_ scriptOps: FloScriptOps,
                      _ nowOps: FloScriptOps) -> String {

        var str = ""
        if scalarOps.rawValue == 0   { return "" }

        if nowOps.def {
            if scalarOps.minim  { str += minim.digits(0...6) }
            if scalarOps.ranged { str += "…" } /// `…` is `⌥⃣;` on mac
            if scalarOps.rangei { str += "_" } /// integer range for midi
            if scalarOps.rangea { str += "~" } /// autoranged min max
            if scalarOps.modulo { str += "%" } /// modulo
            if scalarOps.maxim  { str += maxim.digits(0...6) }
            if scalarOps.origin { str += "=" + origin.digits(0...6) }
            if scalarOps.liter  { str += value.digits(0...6) }
        }
        else if !scriptOps.def, scriptOps.now {
           str += value.digits(0...6)
        } else if !scalarOps.liter, scalarOps.value { str += value.digits(0...6) } // soloNow

        return str
    }

    public func hasPrior() -> Bool {
        return scalarOps.value && value != prior
    }

    // MARK: - set

    /// map between scalar ranges
    ///
    /// - parameters:
    ///     - val: scalar with range or number
    ///     - visit: ignored, see Express
    ///     - ops: set .now andor .val
    ///
    ///  - note: plugins set .now in a callback loop from plugin
    ///
    @discardableResult
    public func setScalarVal(_ any: Any?,
                             _ scalarOps: ScalarOps,
                             _ setOps: SetOps) -> Bool {

        guard let any else { return true }

        prior = tween

        switch any {
        case let v as Scalar  : setFrom(v, setOps)
        case let v as Double  : setTween(v)
        case let v as Float   : setTween(Double(v))
        case let v as CGFloat : setTween(Double(v))
        case let v as Int     : setTween(Double(v))
        default: PrintLog("⁉️ setVal unknown type for: from")
        }

        self.scalarOps |= scalarOps

        return true

        func setFrom(_ from: Scalar, _ setOps: SetOps) {

            if setOps.ranging {
                if from.scalarOps.rangea {
                    from.minim = min(from.minim, from.value)
                    from.maxim = max(from.maxim, from.value)

                }
                if self.scalarOps.rangea {
                    self.minim = min(self.minim, from.minim)
                    self.maxim = max(self.maxim, from.maxim)
                }
                PrintLog("*** from: \(from.minim.digits(-2)) …\(from.maxim.digits(-2)) = \(from.value.digits(-2)) [\(from.scalarOps.description)] name: \(from.flo.name) id: \(from.flo.id)")
                PrintLog("*** self: \(self.minim.digits(-2)) …\(self.maxim.digits(-2)) = \(self.value.digits(-2)) [\(self.scalarOps.description)] name: \(flo.name) id: \(flo.id)")
            }
            /// both have a range
            if self.scalarOps.hasRange, from.scalarOps.hasRange {

                let frOffset = (from.scalarOps.rangei ? 1.0 : 0.0)
                let toRange = (maxim - minim) + (scalarOps.rangei ? 1.0 : 0.0)
                let frRange = (from.maxim - from.minim) + frOffset

                if scalarOps.tween {
                    tween = (from.tween - from.minim) * (toRange / frRange) + minim
                }
                if scalarOps.value {
                    value = (from.value - from.minim) * (toRange / frRange) + minim
                }

            } else if scalarOps.modulo {

                minim = 0
                maxim = Double.maximum(1, maxim)

                if scalarOps.tween { tween = fmod(from.tween, maxim) }
                if scalarOps.value { value = fmod(from.value, maxim) }

            } else {

                setTween(from.value)
            }
        }

        func setTween(_ num: Double) {

            if scalarOps.tween { tween = num }
            if scalarOps.value { value = num }

            if scalarOps.modulo { value = fmod(value, maxim) }
            if scalarOps.minim, value < minim { value = minim }
            if scalarOps.maxim, value > maxim { value = maxim }
        }
    }

    public override func getVal() -> Any {
        return tween
    }

    public func deepCopy(_ exprs: Exprs) -> Scalar {
        let scalar = Scalar(with: self)
        scalar.flo = exprs.flo
        return scalar
    }
    public func copyEval() -> Scalar {
        return Scalar(with: self, viaEval: true)
    }
    
    //TODO: put this into refactored Scalar
    override public func hasDelta() -> Bool {
        if      scalarOps.origin { return value != origin }
        else if scalarOps.minim  { return value != minim }
        else                     { return value != prior }
    }
}
extension Scalar {

    func logValTweens(_ prefix: String,
                      _ suffix: String = "") {
        if value == tween { return }
        // let id = "\(id)".pad(6)
        let path = flo.path(9).pad(-18) + "(\(name))"
        let vals = " value/tween/prior: \(value.digits(3))/\(tween.digits(3))/\(prior.digits(3)) "
        print(prefix + path + vals + suffix)
    }
}
