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
        var firstName = ""  // comma will rese
        var firstAny: Any?  // comma will reset
        var firstOp = false
        var assigned = false
        
        for i in 0...opAnys.count {
            if i == opAnys.count {
                
                scriptFinish() /// finish `y` in `a(x, y)`
                break
            }
            let opAny = opAnys[i]
            switch opAny.op {
                
            case .comma:
                
                scriptFinish()  /// finish `x` in `a(x, y)`
                script += opAny.op.rawValue + " "

            case .name, .path:

                if script.def {
                   scriptOps(scriptOps,script)
                } else if assigned || hasOp {
                    /// skip `x` and `y` in `a(sum: x + y)`
                } else {
                    /// add `x` and `y` in `a (x 1, y 2)`
                    firstName = opAny.any as? String
                    scriptExpr()
                }

            case .quote, .scalar, .num:
                if firstAny == nil {
                    firstAny = opAny.any
                }
                let str = opAny.scriptOps(scriptOps,script)
                scriptColonStr(str)

            case .quote, .scalar, .num:
                if scriptOps.def {
                } else if !hasOp {
                    scriptExpr()
                    literals = true
                }

            case .In:

                let str = opAny.scriptOps(scriptOps, script)
                if str.count > 0 {
                    script += " " + opAny.scriptOps(scriptOps, script) + " "
                }

            case .mod:

                script += opAny.scriptOps(scriptOps, script)

                // is only an op for
                if firstName.count > 0 {
                    firstOp = true /// `a(b % 2)`
                } else {
                    /// `a(%2)` where `%2` is really a scalar
                }

            case .IS, .EQ, .LE, .GE, .LT, .GT, .add, .sub, .muy, .div:

                script += opAny.scriptOps(scriptOps, script)
                firstOp = true

            case .assign:
                if scriptOps.current {
                    script += opAny.op.rawValue
                }
                assigned = true

            case .none: break
            }
            
            func scriptColonStr(_ str: String) {
                if str.count > 0 {
                    
                    if firstOp || script.isEmpty || firstName.isEmpty || script.last == ":"
                    {
                        script += str
                    } else {
                        script += ":" + str
                    }
                }
            }
            
            /// kludge to accomadate `a(x, y) << b, b(x 0, y 0) -- see testExpr0()
            func scriptFinish() {
                if firstName != "",
                   !viaEdge,
                   let any = nameAny[firstName] as? FloVal,
                   any != (firstAny as? FloVal), // shared valOps and nameAny.values
                   any.valOps.next {
                    
                    if !scriptInScalar(any) {
                        
                        let str = any.scriptVal(scriptOps, noParens: true)
                        script += str
                    }
                }
                firstName = ""
                firstAny = nil
                firstOp = false
                assigned = false
            }

            func scriptInScalar(_ any: Any?) -> Bool {
                if let val = any as? FloValScalar {

                    if opSet.contains(.In) {
                        let str = val.scriptScalar(scriptOps.onlyCurrent)
                        scriptColonStr(str)
                        return true
//                    } else {
//                        let str = val.scriptScalar(scriptOps)
//                        scriptColonStr(str)
//                        return true
                    }
                }
                return false
            }
        }
        return script
    }

}
