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
        var exprName: String?  // comma will reset
        var exprAny: Any?

        for opAny in opAnys {
            switch opAny.op {
            case .comma                 : finishExpr()
            case .name, .path           : exprName = exprName ?? opAny.any as? String
            case .quote, .scalar, .num  : exprAny = exprAny ?? opAny.any
            default                     : break
            }
            if scriptOps.def {
                script += opAny.scriptOps(scriptOps.onlyDef, script)
            }
        }
        finishExpr()

        return script

        func finishExpr() {
            if scriptOps.current,
               position < nameAny.values.count {
                if let val = nameAny.values[position] as? FloValScalar {
                    
                    let str = val.scriptScalar(scriptOps.onlyCurrent, script)
                    script += str
                }
            }
            exprName = nil
            position += 1
        }
    }

}
