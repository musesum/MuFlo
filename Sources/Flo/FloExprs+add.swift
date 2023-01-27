// FloExprs+add
//
//  Created by warren on 8/21/22.

import Foundation
import Par

extension FloExprs {

    func addScalar(_ scalar: FloValScalar) {
        let expr = FloExpr(scalar: scalar)
        exprs.append(expr)
        opSet.insert(.scalar)
    }
    func addDeepScalar(_ scalar: FloValScalar) {
        let expr = FloExpr(scalar: scalar)
        exprs.append(expr)
        nameAny[nameAny.keys.last ?? anonKey] = scalar
        opSet.insert(.scalar)
    }
    func addNameNum(_ name: String, _ num: Double) {
        addName(name)
        addDeepScalar(FloValScalar(flo, name: name, num: num))
    }
    func injectNameNum(_ name: String, _ num: Double) {
        if let val = nameAny[name] as? FloValScalar {
            val.now = num
        } else {
            nameAny[name] = FloValScalar(flo, name: name, num: num)
        }
        opSet.insert(.name)
        opSet.insert(.scalar)
    }

    func addPoint(_ p: CGPoint) {
        opSet = Set<FloExprOp>([.name,.num])
        injectNameNum("x", Double(p.x))
        addOpStr(",")
        injectNameNum("y", Double(p.y))
    }
    func addOpStr(_ opStr: String?) {
        if let opStr = opStr?.without(trailing: " ")  {
            let expr = FloExpr(op: opStr)
            exprs.append(expr)
        }
    }
    func addQuote(_ quote: String?) {
        if let quote = quote?.without(trailing: " ")  {
            let expr = FloExpr(quote: quote)
            exprs.append(expr)
            nameAny[nameAny.keys.last ?? anonKey] = quote
            opSet.insert(.quote)
        }
    }
    func addName(_ name: String?) {

        guard let name else { return }
        let expr = FloExpr(name: name)
        exprs.append(expr)
        opSet.insert(.name)

        if !nameAny.keys.contains(name) {
            nameAny[name] = ""
        }
    }
   
}
