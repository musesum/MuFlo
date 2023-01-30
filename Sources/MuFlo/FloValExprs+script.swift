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
    
    public func scriptExprs(_ scriptOpts: FloScriptOps) -> String {
        var script = ""
        if scriptOpts.now  {
            
            var lastNamePath = ""
            var assigned = false
            var literals = false
            var hasOp = false
            
            for i in 0...opVals.count {
                if i == opVals.count {
                    /// finish `y` in `a(x,y)`
                    scriptPassthrough()
                    break
                }
                let expr = opVals[i]
                switch expr.op {
                        
                    case .comma:
                        /// finish `x` in `a(x,y)`
                        scriptPassthrough()
                        scriptExpr()
                        // next pararmeter
                        literals = false
                        assigned = false
                        hasOp = false
                        
                    case .name, .path:
                        /// skip `x` and `y` in `a(sum: x + y)`
                        if assigned || hasOp { continue }
                        /// add `x` and `y` in `a (x 1, y 2)`
                        lastNamePath = expr.val as? String ?? "??"
                        scriptExpr()
                        
                    case .quote, .scalar, .num:
                        if hasOp { continue }
                        scriptExpr()
                        literals = true
                        
                    case .EQ, .LE, .GE, .LT, .GT, .In, .add, .sub, .muy, .divi, .div, .mod:
                        hasOp = true
                        
                    case .assign:
                        assigned = true
                        
                    case .none: break
                }
                
                func scriptExpr() {
                    let s = expr.script([.now])
                    script.spacePlus(s)
                }
                /// kludge to accomadate `a(x, y) << b, b(x 0, y 0) -- see testExpr0()
                func scriptPassthrough() {
                    if !literals {
                        if lastNamePath.count > 0,
                           let val = nameAny[lastNamePath] as? FloVal {
                            var scriptOps2 = scriptOpts
                            scriptOps2.remove(.parens)
                            let s = val.scriptVal(scriptOps2)
                            script.spacePlus(s)
                            lastNamePath = ""
                        }
                    }
                }
            }
        } else {
            for opVal in opVals {
                script.spacePlus(opVal.script(scriptOpts))
            }
        }
        return script
    }
    
}
