//  Created by warren on 12/26/20.


import MuPar

extension FloExprs {
    
    public func scriptExprs(_ scriptOps: FloScriptOps,
                            viaEdge: Bool) -> String {

        var script = ""     // result
        var position = 0
        var assigned = false
        var named = ""

        for opAny in opAnys {
            switch opAny.op {
            case .comma: finishExpr()
            case .assign: assigned = true
            case .name: if !assigned { named = opAny.any as? String ?? "??" }
            default: break
            }
            if scriptOps.def {
                let str = opAny.scriptDefOps(scriptOps, script)
                if str.first == "," || str.first == ":"  {
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
                if numStr == "", scriptOps.onlyNow { nameStr = named }

                if  nameStr.count > 0 && nameStr.first != "_" {
                    script.spacePlus(nameStr + (numStr.isEmpty ? "" : ": " + numStr))
                } else if numStr.count > 0 {
                    if keyStr.first == "_", (script.isEmpty || scalar?.valOps.lit ?? false) {
                        script += numStr
                    } else {
                        script += script.roundColonSpace() + numStr
                    }
                }
            }
            assigned = false
            named = ""
            position += 1

            func logFinish(_ scalar: FloValScalar?, _ keyStr: String) {
                guard let scalar else { return }
                var shortOps = scalar.valOps ; shortOps -= .now_
                let padOps = "[\(shortOps.description)]".pad(27)
                let padScript = "\(script)".pad(24)
                let padPath = "\(scalar.flo.path(5))(\(keyStr))".pad(20)

                print("🧪 \(padScript) \(padPath) \(scalar.id) \(padOps) next: \(scalar.val.digits(0...2))  dflt: \(scalar.dflt.digits(0...2))")
            }
        }
    }

}
