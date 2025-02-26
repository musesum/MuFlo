//  Scalar.swift
//  created by musesum on 4/4/19.

import QuartzCore
import Foundation

public class Scalar: FloVal {

    public static let blank = Scalar(Flo(), "blank")
    public var options = ScalarOptions(rawValue: 0)
    public var prior = Double(0) // prevous value; for animating twe
    public var tween = Double(0) // current value; 2 in 0…3~1=2
    public var value = Double(0) // target value
    public var mini = Double(0) // minimum value; 0 in 0…3
    public var maxi = Double(1) // maximum value; 3 in 0…3
    public var dflt = Double(0) // default value; 1 in 0…3~1

    override init(_ flo: Flo, _ name: String?) {
        let name = name ?? "_"
        super.init(flo, name)
        self.name = name
    }

    init(_ flo: Flo,_ name: String,_ num: Double) {
        super.init(flo, name)
        options = [.value]
        self.mini = fmin(num, 0.0)
        self.maxi = fmax(num, 1.0)
        self.value = num
        self.tween = num
        self.prior = value
    }

    init (with scalar: Scalar, viaEval: Bool = false) {
        super.init(scalar.flo, scalar.name)
        options = scalar.options // use default values
        if viaEval { options -= .liter }
        mini  = scalar.mini
        maxi  = scalar.maxi
        dflt  = scalar.dflt
        tween = scalar.tween
        value = scalar.value
        prior = value
    }

    public func normalized(_ normOp: ScalarOptions) -> Double {
        if options.contains([.mini,.maxi]) {
            let range = maxi - mini
            if normOp.tween {
                let ret = (tween - mini) / range
                return ret
            } else if normOp.value {
                let ret = (value - mini) / range
                return ret
            }
        }
        return value
    }
    public func range() -> ClosedRange<Double> {
        if mini <= maxi { return mini...maxi }
        else          { return mini...(mini+1) }
    }

    // startup set values without animation
    func bindVal() {

        if !options.value {
            let visit = Visitor(0,.bind)
            setDefault(visit, /* withPrior */ false)
            tween = value
        }
    }

    func setDefault(_ visit: Visitor, _ withPrior: Bool) { // was setDefault
        prior = tween
        if      options.dflt               { value = dflt  }
        else if options.mini, value < mini { value = mini  }
        else if options.maxi, value > maxi { value = maxi  }
        else if options.modu               { value = 0     }
        tween = value
    }
    static func |= (lhs: Scalar, rhs: Scalar) {
        
        let mergeOps = lhs.options.rawValue |  rhs.options.rawValue
        lhs.options = ScalarOptions(rawValue: mergeOps)
        if rhs.options.mini { lhs.mini = rhs.mini }
        if rhs.options.maxi { lhs.maxi = rhs.maxi }
        if rhs.options.value { lhs.value = rhs.value } 
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

        if options.modu, from > maxi { return false }
        if options.mini, from < mini { return false }
        if options.maxi, from > maxi { return false }
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
            PrintLog("⁉️ \(flo.name) [\(scriptOps.description)].[\(options.description)] : \(value)")
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
        if options.rawValue == 0   { return "" }

        if nowOps.def {
            if options.mini { str += mini.digits(0...6) }
            if options.thru { str += "…" } /// `…` is `⌥⃣;` on mac
            if options.thri { str += "_" } /// integer range for midi
            if options.modu { str += "%" } /// modulo
            if options.maxi { str += maxi.digits(0...6) }
            if options.dflt { str += "~" + dflt.digits(0...6) }
            if options.isLit{ str += value.digits(0...6) }
        }
        else if !scriptOps.def, scriptOps.now {
            if      options.isLit { str += value.digits(0...6) } // litNow
            else if options.value { str += value.digits(0...6) } // soloNow
        } else if !options.isLit, options.value { str += value.digits(0...6) } // soloNow

        return str
    }

    public func hasPrior() -> Bool {
        return options.value && value != prior
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
                             _ ops: ScalarOptions) -> Bool {

        guard let any else { return true }

        prior = tween

        switch any {
        case let v as Scalar : setFrom(v)
        case let v as Double       : setTween(v)
        case let v as Float        : setTween(Double(v))
        case let v as CGFloat      : setTween(Double(v))
        case let v as Int          : setTween(Double(v))
        default: PrintLog("⁉️ setVal unknown type for: from")
        }

        options += ops

        return true

        func setFrom(_ v: Scalar) {

            /// both have a range
            if (  options.thru ||   options.thri),
               (v.options.thru || v.options.thri)  {

                let toRange = (  maxi -   mini) + (   options.thri ? 1.0 : 0.0)
                let frRange = (v.maxi - v.mini) + ( v.options.thri ? 1.0 : 0.0)

                if ops.tween { tween = (v.tween - v.mini) * (toRange / frRange) + mini }
                if ops.value { value = (v.value - v.mini) * (toRange / frRange) + mini }

            } else if options.modu {

                mini = 0
                maxi = Double.maximum(1, maxi)

                if ops.tween { tween = fmod(v.tween, maxi) }
                if ops.value { value = fmod(v.value, maxi) }
                
            } else {
                
                setTween(v.value)
            }
        }

        func setTween(_ num: Double) {

            if ops.tween { tween = num }
            if ops.value { value = num }

            if options.modu { value = fmod(value, maxi) }
            if options.mini, value < mini { value = mini }
            if options.maxi, value > maxi { value = maxi }
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
