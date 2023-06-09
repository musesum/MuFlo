// FloValExprs+set
//
//  Created by warren on 8/21/22.
//

import Foundation
import MuPar

extension FloExprs { // + set

    typealias ExprSetters = ContiguousArray<(String,Any?)>

    /**
     evaluate expression

         // example          setters after a!     script(session=true)
         a(x 1, y 2)         // ("x",1), ("y",2)  a(x 1, y 2)
         b(x + y)      << a  // ("x",3)           b(x 3)
         c(z: x + y)   << a  // ("z",3)           c(z 3)
         d(: x + y)    << a  // ("_0",3)          d(3)
         e(x: x + y)   << a  // ("x",3)           e(3)
         f(x: y, y: x) << a  // ("x",2), ("t",1)  f(x 2, y 1)
         g(x, y)       << a  // ("x",1), ("y",2)  g(x 1, y 2)
         h(x - 1, y*2) << a  // ("x",0), ("y",4)  h(x 0, y 4)
         i(x + y, z:y) << a  // ("x",3), ("z",4)  i(x 3, z 2)
         j(x < 1, y)   << a  // abort all setters j(x, y)
         k(x < 2, y)   << a  // ("x",1), ("y",2)  k(x 2, y 3)
         l(count: + 1) << a  // ("count",1)       l(1), l(2) ... l(∞)
         m(+1)         << a  // ("_0",1)          m(1), m(2) ... m(∞)
         n(1 + 2)
         p(++)

      - note: failed conditional will abort all setters and should abort activate edges
     */

    func evalFromExprs(_ viaEdge: Bool,
                       _ visit: Visitor) {

        let edgeVal = viaEdge ? flo.exprs : nil
        evalExprs(edgeVal, visit) //...
    }

    @discardableResult
    func evalExprs(_ frExprs: FloExprs?,
                   _ visit: Visitor) -> Bool {

        var mySetters = ExprSetters()
        var toAny: Any?
        var myAny: Any?
        var myName: String?
        var opNow = FloOp.none
        var anonId = 0  /// _0:`2` in `a(1) b >> a(2)`

        for i in 0...opAnys.count {

            if i==opAnys.count {
                exprFinish()
                setSetters(mySetters, visit)
                return true
            }
            let opAny = opAnys[i]

            switch opAny.op.opType {
                case .literal   : if !exprLiteral() { return false }
                case .condition : opNow = opAny.op
                case .operation : opNow = opAny.op
                case .pathName  : if !exprName() { return false }
                case .endop     : exprFinish()
                case .none      : break
            }

            /// match from and to parameters
            func exprName() -> Bool {
                
                if let name = opAny.any as? String {

                    if myName == nil {
                        myName = name
                        myAny = nameAny[name]
                    }
                    let nameAny = frExprs?.nameAny ?? nameAny
                    if let frVal = nameAny[name] {
                        if opNow != .none {
                            toAny = opAny.evaluate(toAny ?? myAny, frVal, opNow)
                            opNow = .none
                            return toAny != nil
                        } else {
                            toAny = frVal
                        }
                    }
                }
                return true
            }

            /// evaluate numbers and strings, return false if should abort expression
            func exprLiteral() -> Bool  {
                if toAny == nil, myAny == nil {
                    anonLiteral()
                    return true
                }
                let frVal = toAny ?? myAny
                toAny = opAny.evaluate(opAny.any, frVal, opNow)
                return toAny != nil
            }
            func anonLiteral() {
                if let frExprs,
                   let frAny = frExprs.nameAny["_\(anonId)"] {
                    toAny = frAny
                    myName = "_\(anonId)"
                    anonId += 1
                }
            }
        }
        return true

        func exprFinish() {
            if let myName, let toAny {
                mySetters.append((myName,toAny))
            }
            // reset for next expr parameter
            opNow = .none
            myName = nil
            toAny = nil
            anonId = 0
        }
    }

    /// execute all deferrred setters
    func setSetters(_ mySetters: ExprSetters,
                    _ visit: Visitor) {

        let ops: FloValOps = (plugin == nil ? [.now_, .val] : [.val])
        for (name,val) in mySetters {
            
            switch val {
            case let val as FloValScalar:
                if let toVal = nameAny[name] as? FloVal {
                    /// `x` in `a(x 1) << b`
                    toVal.setVal(val, visit, ops)
                } else {
                    /// `x` in `a(x) << b`
                    nameAny[name] = val.copyEval()
                }
            case let val as Double:
                
                nameAny[name] = FloValScalar(flo, name, val)
                
            case let val as String:
                if let toVal = nameAny[name] as? FloVal {
                    if !val.isEmpty {
                        /// `x` in `a(x in 2…4) << b, b(x 3)`
                        toVal.setVal(val, visit, ops)
                    }
                }
            default : break
            }
        }
    }
}
