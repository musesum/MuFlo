//  created by musesum on 8/21/22.

import Foundation

extension Exprs { // + add

    func addDeepScalar(_ scalar: Scalar?,_ name: String? = nil,_ lastOp: EvalOp = .none) {
        guard let scalar else { return }
        let evalAny = EvalAny(scalar: scalar)
        evalAnys.append(evalAny)
        if let name {
            if [.none,.comma, .In, .EQ].contains(lastOp) {
                nameAny[name] = scalar
            } 
        } else {
            nameAny[anonKey] = scalar
        }
    }
    
    func injectNameNum(_ name: String, _ num: Double) {
        if let val = nameAny[name] as? Scalar {
            val.tween = num
            val.value = num
        } else {
            nameAny[name] = Scalar(flo, name, num)
        }
    }

    func addPoint(_ point: CGPoint) {
        injectNameNum("x", Double(point.x))
        addOpStr(",")
        injectNameNum("y", Double(point.y))
    }
    func addSize(_ size: CGSize) {
        injectNameNum("w", Double(size.width))
        addOpStr(",")
        injectNameNum("h", Double(size.height))
    }
    public func addRect(_ rect: CGRect) {
        injectNameNum("x", Double(rect.minX))
        addOpStr(",")
        injectNameNum("y", Double(rect.minY))
        addOpStr(",")
        injectNameNum("w", Double(rect.width))
        addOpStr(",")
        injectNameNum("h", Double(rect.height))
    }
    @discardableResult
    func addOpStr(_ opStr: String?) -> EvalOp {
        if let opStr = opStr?.without(trailing: " ")  {
            let evalAny = EvalAny(str: opStr)
            evalAnys.append(evalAny)
            return evalAny.op
        }
        return .none
    }
    func addQuote(_ quote: String?) {
        if let quote = quote?.without(trailing: " ")  {
            evalAnys.append(EvalAny(quote: quote))
            let key = nameAny.keys.last ?? anonKey
            nameAny[key] = quote
        }
    }
    func addTooltip(_ tip: String?) {
        if let tip = tip?.without(trailing: " ")  {
            evalAnys.append(EvalAny(toolip: tip))
            nameAny[anonKey] = tip
        }
    }
    func addOpName(_ name: String?,
                   _ hadName: Bool) {

        guard let name else { return }
        evalAnys.append(EvalAny(name: name))

        if hadName {
            return
        }
        if !nameAny.keys.contains(name) {
            nameAny[name] = ""
        }
    }
}
