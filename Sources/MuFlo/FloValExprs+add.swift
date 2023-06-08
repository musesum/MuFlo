// FloValExprs+add
//
//  Created by warren on 8/21/22.

import Foundation
import MuPar

extension FloValExprs {

    func addDeepScalar(_ scalar: FloValScalar?) {
        guard let scalar else { return }
        let opAny = FloOpAny(scalar: scalar)
        opAnys.append(opAny)
        let key = nameAny.keys.last ?? anonKey
        nameAny[key] = scalar
    }
    func addAnonScalar(_ scalar: FloValScalar?) {
        guard let scalar else { return }
        let opAny = FloOpAny(scalar: scalar)
        opAnys.append(opAny)
        nameAny[anonKey] = scalar
    }
   
    func injectNameNum(_ name: String, _ num: Double) {
        if let val = nameAny[name] as? FloValScalar {
            val.now = num
            val.next = num
        } else {
            nameAny[name] = FloValScalar(flo, name, num)
        }
    }

    func addPoint(_ p: CGPoint) {
        injectNameNum("x", Double(p.x))
        addOpStr(",")
        injectNameNum("y", Double(p.y))
    }
    func addOpStr(_ opStr: String?) {
        if let opStr = opStr?.without(trailing: " ")  {
            let opAny = FloOpAny(op: opStr)
            opAnys.append(opAny)
        }
    }
    func addQuote(_ quote: String?) {
        if let quote = quote?.without(trailing: " ")  {
            let opAny = FloOpAny(quote: quote)
            opAnys.append(opAny)
            let key = nameAny.keys.last ?? anonKey
            nameAny[key] = quote
        }
    }
    func addOpName(_ name: String?,
                 _ hasOp: Bool) {

        guard let name else { return }
        let opAny = FloOpAny(name: name)
        opAnys.append(opAny)

        if !hasOp, !nameAny.keys.contains(name) {
            nameAny[name] = ""
        }
    }
   
}
