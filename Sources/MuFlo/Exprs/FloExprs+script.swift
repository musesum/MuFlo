//  Created by warren on 12/26/20.


import MuPar

extension FloExprs {
  
    public func scriptExprs(_ scriptOps: FloScriptOps,
                            _ viaEdge: Bool) -> String {

        var script = ""     // result
        var position = 0
        var assigned = false
        var condition = ""
        var named = ""

        for opAny in opAnys {

            switch opAny.op {
            case .comma: finishExpr()
            case .assign, .In: assigned = true
            case .name: if !assigned, named == "" { named = opAny.any as? String ?? "??" }
            case .IS,.EQ,.LE,.GE,.LT,.GT: condition = opAny.op.rawValue
            default: break
            }

            if scriptOps.def {
                let str = opAny.scriptDefOps(scriptOps, script)
                if str.first == "," {
                    script += str
                } else {
                    script.spacePlus(str)
                }
            } else if scriptOps.now, opAny.op == .comma {
                script += ", "
            }
        }
        finishExpr()
        return script

        func finishExpr() {
            if scriptOps.now,
               position < nameAny.values.count {

                let keyStr = nameAny.keys[position]
                var nameStr = !scriptOps.def ? keyStr : ""
                let scalar =  (named != ""
                               ? nameAny[named] as? FloValScalar
                               : nameAny.values[position] as? FloValScalar)
                // logFinish(scalar, keyStr)

                let numStr = scalar?.scriptScalar(scriptOps, .val) ?? ""
                if numStr == "", scriptOps.notDefNow { nameStr = named }

                if  nameStr.count > 0 && nameStr.first != "_" {
                    let opStr = (numStr.isEmpty ? ""
                                 : condition.isEmpty ? "="
                                 : condition)
                    script.spacePlus(nameStr)
                    script.spacePlus(opStr)
                    script.spacePlus(numStr)

                } else if numStr.count > 0 {
                    if keyStr.first == "_", (script.isEmpty || scalar?.valOps.lit ?? false) {
                        script += numStr
                    } else if !viaEdge {
                        script += script.roundColonSpace() + numStr
                    }
                }
            }
            assigned = false
            named = ""
            condition = ""
            position += 1

            func logFinish(_ scalar: FloValScalar?, _ keyStr: String) {
                guard let scalar else { return }
                var shortOps = scalar.valOps ; shortOps -= .twe
                let padOps = "[\(shortOps.description)]".pad(27)
                let padScript = "\(script)".pad(24)
                let padPath = "\(scalar.flo.path(5))(\(keyStr))".pad(20)
                let valStr = scalar.val.digits(0...2)
                let dfltStr = scalar.dflt.digits(0...2)
                print("🧪\n \(padScript) \(padPath) \(scalar.id) \(padOps) next: \(valStr)  dflt: \(dfltStr)")
            }
        }
    }

}
