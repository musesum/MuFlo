// FloValExprs+set
//
//  Created by warren on 8/21/22.
//

import Foundation
import MuPar

extension FloValExprs { // + set

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
    func evalExprs(_ frExprs: FloValExprs?,
                   _ visit: Visitor) -> Bool {

        var mySetters = ExprSetters()
        var toVal: Any?
        var myVal: Any?
        var myName: String?
        var opNow = FloOp.none

        for i in 0...opVals.count {

            if i==opVals.count {
                endParameter()
                setSetters(mySetters, visit)
                return true
            }
            let expr = opVals[i]

            switch expr.op.opType {
                case .literal   : if !exprLiteral() { return false }
                case .condition : opNow = expr.op
                case .operation : opNow = expr.op
                case .pathName  : if !exprName() { return false }
                case .endop     : endParameter()
                case .none      : break
            }

            /// match from and to parameters
            func exprName() -> Bool {
                
                if let name = expr.val as? String {

                    if myName == nil {
                        myName = name
                        myVal = nameAny[name]
                    }
                    let nameAny = frExprs?.nameAny ?? nameAny
                    if let frVal = nameAny[name] {
                        if opNow != .none {
                            toVal = expr.evaluate(toVal ?? myVal, frVal, opNow)
                            opNow = .none
                            return toVal != nil
                        } else {
                            toVal = frVal
                        }
                    }
                }
                return true
            }

            /// evaluate numbers and strings, return false if should abort expression
            func exprLiteral() -> Bool  {
                let frVal = toVal ?? myVal
                toVal = expr.evaluate(expr.val, frVal, opNow)
                return toVal != nil
            }
        }
        return true

        /// reset current values after comma
        func endParameter() {
            if let myName, let toVal {
                mySetters.append((myName,toVal))
            }
            // reset for next expr parameter
            opNow = .none
            myName = nil
            toVal = nil
        }
    }

    /// execute all deferrred setters
    func setSetters(_ mySetters: ExprSetters,
                    _ visit: Visitor) {
        
        for (name,val) in mySetters {

            switch val {
                case let val as FloValScalar:
                    if let toVal = nameAny[name] as? FloVal {
                        /// `x` in `a(x 1) << b`
                        _ = toVal.setVal(val, visit)
                    } else {
                        /// `x` in `a(x) << b`
                        nameAny[name] = val.copy()
                    }
                case let val as Double:

                    nameAny[name] = FloValScalar(flo, name, val)

                case let val as String:
                    if let toVal = nameAny[name] as? FloVal {
                        if !val.isEmpty {
                            /// `x` in `a(x in 2…4) << b, b(x 3)`
                            _ = toVal.setVal(val, visit)
                        }
                    }
                default : break
            }
        }
    }
}
