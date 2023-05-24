//
//  FloExpr
//  
//
//  Created by warren on 1/1/21.

import Foundation

public class FloOpAny {

    var op = FloOp.none
    var any: Any?
    
    init(op     : String)       { self.op = FloOp(op) }
    init(name   : String)       { self.op = .name   ; any = name }
    init(path   : String)       { self.op = .path   ; any = path }
    init(quote  : String)       { self.op = .quote  ; any = quote }
    init(scalar : FloValScalar) { self.op = .scalar ; any = scalar }
    init(from   : FloOpAny)     { self.op = from.op ; any = from.any }
    func copy() -> FloOpAny     { return FloOpAny(from: self) }

    func scriptOps(_ scriptOps: FloScriptOps,
                   _ script: String) -> String {
        
        switch op {
        case .name   : return any as? String ?? ""
        case .quote  : return "\"\(any as? String ?? "")\""
        case .scalar : return (any as? FloValScalar)?.scriptScalar(scriptOps, script) ?? ""
        case .comma  : return op.rawValue
        default      : return scriptOps.def ? op.rawValue : ""
        }
    }

}

