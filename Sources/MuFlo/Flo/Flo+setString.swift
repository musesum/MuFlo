// created by musesum on 9/11/26

extension Flo {
    /// replace the quoted value(s) and fire closures; strings parse into EvalAny entries, not nameAny
    public func setStringValue(_ value: String, _ visit: Visitor) {
        guard let exprs else { return }
        for evalAny in exprs.evalAnys where evalAny.op == .quote {
            evalAny.any = value
        }
        activate(.fire, visit)
    }
    /// replace the string-array value and fire closures
    public func setStrings(_ strs: [String], _ visit: Visitor) {
        guard let exprs else { return }
        for evalAny in exprs.evalAnys where evalAny.op == .quotes {
            evalAny.any = strs
        }
        activate(.fire, visit)
    }

    /// the quoted value's script default, as parsed; nil without a quote
    public var stringOrigin: String? {
        exprs?.evalAnys.first { $0.op == .quote }?.origin as? String
    }
    /// the string array's script default, as parsed; nil without one
    public var stringsOrigin: [String]? {
        exprs?.evalAnys.first { $0.op == .quotes }?.origin as? [String]
    }
    /// the quote back to its script default, firing closures; no-op without one
    public func setStringOrigin(_ visit: Visitor) {
        guard let s = stringOrigin else { return }
        setStringValue(s, visit)
    }
    /// the string array back to its script default, firing closures
    public func setStringsOrigin(_ visit: Visitor) {
        guard let strs = stringsOrigin else { return }
        setStrings(strs, visit)
    }
}
