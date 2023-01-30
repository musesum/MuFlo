//
//  FloExpr
//  
//
//  Created by warren on 1/1/21.

import Foundation

public class FloOpVal {

    var op = FloOp.none
    var val: Any?
    
    init(op     : String)       { self.op = FloOp(op) }
    init(name   : String)       { self.op = .name   ; val = name }
    init(path   : String)       { self.op = .path   ; val = path }
    init(quote  : String)       { self.op = .quote  ; val = quote }
    init(scalar : FloValScalar) { self.op = .scalar ; val = scalar }
    init(from   : FloOpVal)     { self.op = from.op ; val = from.val }
    func copy() -> FloOpVal     { return FloOpVal(from: self) }

    func script(_ scriptOpts: FloScriptOps) -> String {
        
        switch op {
            case .name: return val as? String ?? "??"
            case .quote: return "\"\(val as? String ?? "??")\""
            case .scalar:
                if let v = val as? FloValScalar {
                    var scriptOps2 = scriptOpts
                    scriptOps2.remove(.parens)
                    scriptOps2.insert(.expand)
                    return v.scriptVal(scriptOps2)
                }
            case .comma: return op.rawValue
            default : break
        }
        return scriptOpts.now ? "" : op.rawValue
        
    }

}

