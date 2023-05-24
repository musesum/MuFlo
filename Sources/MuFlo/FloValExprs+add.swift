// FloValExprs+add
//
//  Created by warren on 8/21/22.

import Foundation
import MuPar

extension FloValExprs {

    func addScalar(_ scalar: FloValScalar) {
        let opAny = FloOpAny(scalar: scalar)
        opAnys.append(opAny)
        opSet.insert(opAny.op)
    }
    func addDeepScalar(_ scalar: FloValScalar) {
        let opAny = FloOpAny(scalar: scalar)
        opAnys.append(opAny)
        nameAny[nameAny.keys.last ?? anonKey] = scalar
        opSet.insert(opAny.op)
    }
    func addNameNum(_ name: String, _ num: Double) {
        addName(name)
        addDeepScalar(FloValScalar(flo, name, num))
    }
    func injectNameNum(_ name: String, _ num: Double) {
        if let val = nameAny[name] as? FloValScalar {
            val.now = num
            val.next = num //??
        } else {
            nameAny[name] = FloValScalar(flo, name, num)
        }
        opSet.insert(.name)
        opSet.insert(.scalar)
    }

    func addPoint(_ p: CGPoint) {
        opSet = Set<FloOp>([.name,.num])
        injectNameNum("x", Double(p.x))
        addOpStr(",")
        injectNameNum("y", Double(p.y))
    }
    func addOpStr(_ opStr: String?) {
        if let opStr = opStr?.without(trailing: " ")  {
            let opAny = FloOpAny(op: opStr)
            opAnys.append(opAny)
            opSet.insert(opAny.op)
        }
    }
    func addQuote(_ quote: String?) {
        if let quote = quote?.without(trailing: " ")  {
            let opAny = FloOpAny(quote: quote)
            opAnys.append(opAny)
            nameAny[nameAny.keys.last ?? anonKey] = quote
            opSet.insert(opAny.op)
        }
    }
    func addName(_ name: String?) {

        guard let name else { return }
        let opAny = FloOpAny(name: name)
        opAnys.append(opAny)
        opSet.insert(opAny.op)

        if !nameAny.keys.contains(name) {
            nameAny[name] = ""
        }
    }
   
}
