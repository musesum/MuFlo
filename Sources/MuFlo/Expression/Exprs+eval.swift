//  created by musesum on 8/21/22.


import Foundation

extension Exprs { // + eval

    typealias ExprSetters = ContiguousArray<(String,Any?)>

    /// evaluate expression
    ///
    /// - Parameters:
    ///     - fromExprs: source exprs values
    ///     - fromNode: `a` in `a (-> b)`, not `b` in `b(<- a)`
    ///     _ visit: break loops
    ///
    /// example before activating `a`:
    ///
    ///      a(x 10, -> b(x/2))
    ///      b(x 0)
    ///
    /// after activating `a`
    ///
    ///     a(x 10, -> b(x/2 = 5))
    ///     b(x 5)
    ///
    /// evaluation happens twice
    ///
    ///     a (-> b) // fromNode == true; eval values from a
    ///     b (<- a) // fromNode == false; send evaluated value to b
    ///
    /// sometimes an expression name is changed
    ///
    ///     c(x 10, -> c(y x/2)) // eval x/2 and send as y
    ///     d(y 5)
    ///
    /// or simply send a literal
    ///
    ///     e { f(on 1, -> g(on 0)) // turn g off
    ///         g(on 0, -> f(on 0)) // turn f off }
    ///

    @discardableResult
    func evalExprs(_ fromExpress: Exprs?,
                   _ fromNode: Bool,
                   _ setOps: SetOps) -> Bool {

        var mySetters = ExprSetters()
        var toAny: Any?
        var myAny: Any?
        var myName: String?
        var opNow = EvalOp.none
        var exprNum = 0 // used for anonymous assignment

        /// for `a(x 0, y/2)`
        ///     `0` in `x 0,` => false
        ///     `2` in `y/2)` => true
        var hasOp = false

        /// `_0:2` in `a(1) b >> a(2)`
        var anonId = 0

        for i in 0...evalAnys.count {

            if i==evalAnys.count {
                exprFinish()
                setSetters(mySetters, fromNode, setOps)
                return true
            }
            let evalAny = evalAnys[i]

            switch evalAny.op {
            case .none,.tooltip:
                break // start here
            case .quote,.scalar,.num:
                if !exprLiteral() { return false }
            case .path,.name:
                if !exprName() { return false }
            case .EQ,.LE,.GE, .LT,.GT,.In,.add,.sub,.muy,.div, .mod, .assign:
                opNow = evalAny.op; hasOp = true
            case .comma:
                exprFinish()
            }


            /// match from and to parameters
            func exprName() -> Bool {

                if let name = evalAny.any as? String {

                    if myName == nil {
                        myName = name
                        myAny = nameAny[name]
                    }
                    if let fromNameAny = fromExpress?.nameAny {

                        if let fromAny = fromNameAny[name] {

                            return evalFromAny(fromAny)

                        } else if fromNameAny.keys.count > exprNum,
                                  fromNameAny.keys[exprNum][0] == "_",
                                  let myName, myName[0] == "_" {
                            // anonymous asignment based on leading "_"
                            // a (_p 1, _q 2, <- b),  b (_r 3, _s 4)
                            // a (_p 3, _q 4, <- b),  b (_r 3, _s 4)
                            return evalFromAny(fromNameAny.values[exprNum])
                        }
                    }
                }
                return true

                func evalFromAny(_ fromAny: Any) -> Bool {
                    if opNow != .none {
                        toAny = evalAny.evalExpression(toAny ?? myAny, fromAny, opNow)
                        opNow = .none // keep hasOp
                        return toAny != nil
                    } else {
                        toAny = fromAny
                    }
                    return true
                }
            }

            /// evaluate numbers and strings, return false if should abort expression
            func exprLiteral() -> Bool  {
                if toAny == nil, myAny == nil {
                    anonLiteral()
                    return true
                } else if fromNode, !hasOp {
                    toAny = myAny
                } else {
                    toAny = evalAny.evalExpression(evalAny.any, toAny ?? myAny, opNow)
                }
                return toAny != nil
            }

            func anonLiteral() {
                if let fromExpress,
                   let frAny = fromExpress.nameAny["_\(anonId)"] {
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
            // reset for next value parameter
            opNow = .none
            hasOp = false
            myName = nil
            toAny = nil
            anonId = 0
            exprNum += 1 // used for anonymous assignment
        }
    }

    /// execute all deferrred setters
    func setSetters(_ mySetters: ExprSetters,
                    _ viaEdge: Bool,
                    _ setOps: SetOps) {

        for (name,val) in mySetters {

            switch val {
            case let scalar as Scalar:
                if let toVal = nameAny[name] as? Scalar {
                    /// `x` in `a(x 1) << b`
                    if name.first == "_",  viaEdge, toVal.scalarOps.liter {
                        // dont set a(2) in  a(1), b(0…1, -> a(2))
                    } else {
                        toVal.setScalarVal(scalar, flo.scalarOps, setOps)
                        toVal.scalarOps |= .value
                    }
                } else {
                    /// `x` in `a(x) << b`
                    nameAny[name] = scalar.copyEval()
                }
            case let double as Double:

                nameAny[name] = Scalar(flo, name, double)

            case let string as String:
                if let toVal = nameAny[name] as? FloVal {
                    if !string.isEmpty {
                        /// `x` in `a(x in 2…4, <- b), b(x 3)`
                        toVal.setVal(string)
                    }
                }
            default:
                // eval MTLTexture, MTLBuffer, etc 
                nameAny[name] = val
            }
        }
    }
}
