//  created by musesum on 8/21/22.

import Foundation

extension Exprs { // + add

    func addDeepScalar(_ scalar : Scalar?,
                       _ name   : String? = nil,
                       _ lastOp : EvalOp = .none) {

        guard let scalar else { return }
        let evalAny = EvalAny(scalar: scalar)
        evalAnys.append(evalAny)
        if let name {
            if [.none, .comma, .In, .EQ, .texture, .buffer].contains(lastOp) {
                nameAny[name] = scalar
            }
        } else {
            nameAny[anonKey] = scalar
        }
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
    func addQuotes(_ quotes: [String]) {
        guard !quotes.isEmpty else { return }
        evalAnys.append(EvalAny(quotes: quotes))
        // claim the preceding name only while it holds addOpName's "" placeholder;
        // never clobber a sibling Scalar or prior value
        if let last = nameAny.keys.last, (nameAny[last] as? String) == "" {
            nameAny[last] = quotes
        } else {
            nameAny[anonKey] = quotes
        }
    }
    /// `name` is the first name of the tooltip's comma group, if any:
    /// `x 0…1=0 'opacity'` labels x, and scriptExprs prints it back at the
    /// group's end; a tooltip first in its group (`'help', xyzw` or
    /// `x, 'tip'`) stays an anonymous value, as before
    func addTooltip(_ tip: String?, _ name: String? = nil) {
        guard let tip = tip?.without(trailing: " ") else { return }
        if let name {
            labels[name] = tip
        } else {
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

    /// fold a prior edge target's map in FRONT of this one, comma-joined:
    /// `t(x: w), t(y: z)` ⟹ one exprs `t(x: w, y: z)` — identical to the
    /// single-group form that already evaluates correctly. Prepend (not
    /// append) because the parser attaches an edge Exprs BEFORE filling its
    /// tokens — the newer object must stay live to receive them.
    func prependExprs(_ other: Exprs) {
        guard !other.evalAnys.isEmpty else { return }
        var prefix = other.evalAnys
        prefix.append(EvalAny(str: ","))
        evalAnys.insert(contentsOf: prefix, at: 0)
        for (name, any) in other.nameAny {
            if !nameAny.keys.contains(name) {
                nameAny[name] = any
            }
        }
        for (name, label) in other.labels where labels[name] == nil {
            labels[name] = label
        }
    }
}
