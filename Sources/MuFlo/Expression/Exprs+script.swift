//  created by musesum on 12/26/20.

extension Exprs { // + script

    public func scriptExprs(_ scriptOps: FloScriptOps,
                            _ viaEdge: Bool) -> String {

        var script = ""     // result
        var position = 0
        var assigned = false
        var condition = ""
        var named = ""

        for evalAny in evalAnys {

            switch evalAny.op {
            case .comma: finishExpr()
            case .assign, .In: assigned = true
            case .name:  setName(evalAny)
            case .EQ,.LE,.GE,.LT,.GT: condition = evalAny.op.rawValue
            default: break
            }

            if scriptOps.def {
                let str = evalAny.scriptDefOps(scriptOps, script)
                if str.first == "," {
                    script += str
                } else {
                    script.spacePlus(str)
                }
            } else if scriptOps.now, evalAny.op == .comma {
                script += ", "
            }
        }
        finishExpr()
        script.trimCommaSpace()
        return script

        func setName(_ evalAny: EvalAny) {
            if !assigned,
                named == "" {

                named = evalAny.any as? String ?? "??"
            }
        }
        func finishExpr() {
            if scriptOps.now,
               position < nameAny.values.count {

                let keyStr = nameAny.keys[position]
                var nameStr = !scriptOps.def ? keyStr : ""
                let scalar =  (named != ""
                               ? nameAny[named] as? Scalar
                               : nameAny.values[position] as? Scalar)
                // logFinish(scalar, keyStr)

                let numStr = scalar?.scriptScalar(scriptOps, .now) ?? ""
                if numStr == "", !scriptOps.def, scriptOps.now  {
                    nameStr = named
                }

                if  nameStr.count > 0,
                    nameStr.first != "_" {
                    
                    let opStr = (numStr.isEmpty ? ""
                                 : condition.isEmpty ? ":"
                                 : condition)

                    script.spacePlus(nameStr)
                    script.spacePlus(opStr)
                    script.spacePlus(numStr)

                } else if numStr.count > 0 {
                    if keyStr.first == "_",
                       (script.isEmpty ||
                        scalar?.scalarOps.liter ?? false) {

                        script += numStr

                    } else if !viaEdge {
                        script += script.padColonSign() + numStr
                    }
                }
            }
            assigned = false
            named = ""
            condition = ""
            position += 1

            func logFinish(_ scalar: Scalar?, _ keyStr: String) {
                guard let scalar else { return }
                var shortOps = scalar.scalarOps ; shortOps -= .tween
                let padOps = "[\(shortOps.description)]".pad(27)
                let padScript = "\(script)".pad(24)
                let padPath = "\(scalar.flo.path(5))(\(keyStr))".pad(20)
                let valStr = scalar.value.digits(0...2)
                let dfltStr = scalar.origin.digits(0...2)
                PrintLog("🧪\n \(padScript) \(padPath) \(scalar.id) \(padOps) next: \(valStr)  origin: \(dfltStr)")
            }
        }
    }
   

}
