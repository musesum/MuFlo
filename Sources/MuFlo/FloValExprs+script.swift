//  Created by warren on 12/26/20.


import MuPar

extension FloValExprs {
    
    private func scriptNames(_ scriptOps: FloScriptOps) -> String {

        var script = ""
        var delim = ""
        for (name,val) in nameAny {
            
            script.spacePlus(delim) ; delim = ", "
            if name.first != "_" {
                script.spacePlus(name)
            }
            
            switch val {
            case let v as FloValScalar:
                
                script.spacePlus(v.scriptVal(scriptOps))
                
            case let v as String:
                
                script.spacePlus(v)
                
            default: break
            }
        }
        return script
    }
    
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
            } else if scriptOps.current, opAny.op == .comma {
                script += ", "
            }

        }
        finishExpr()
        return script

        func finishExpr() {
            if scriptOps.current,
               position < nameAny.values.count {

                let keyStr = nameAny.keys[position]
                let nameStr = !scriptOps.def ? keyStr : ""
                let scalar =  (named != ""
                               ? nameAny[named] as? FloValScalar
                               : nameAny.values[position] as? FloValScalar)
                logFinish(scalar, keyStr)

                let numStr = scalar?.scriptScalar(scriptOps, .current) ?? ""

                if  nameStr.count > 0 && nameStr.first != "_" {
                    script.spacePlus(nameStr + (numStr.isEmpty ? "" : ": " + numStr))
                } else if numStr.count > 0 {
                    if keyStr.first == "_", script.isEmpty {
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
                print("🧪 \"\(script)\"  \(keyStr).\(scalar.id): [\(scalar.valOps.description ?? "")] now:\(scalar.now) next:\(scalar.next) dflt:\(scalar.dflt) named:\(named)")
            }
        }
    }

}
