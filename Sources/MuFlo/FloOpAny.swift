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
    
    func scriptDefOps(_ fullOps: FloScriptOps,
                      _ script: String) -> String {
        
        switch op {
        case .name   : return any as? String ?? ""
        case .quote  : return scriptQuote()
        case .scalar : return scriptScalar()
        case .comma  : return op.rawValue + " "
        case .EQ     : return op.rawValue
        case .assign : return op.rawValue + " "
        default      : return fullOps.def ? op.rawValue : ""
        }
        
        func scriptScalar() -> String {
            if let scalar = any as? FloValScalar {
                return scalar.scriptScalar(fullOps, .def)
            }
            return ""
        }
        func scriptQuote() -> String {
            if let str = any as? String {
                return "\"\(str)\""
            }
            return ""
        }
    }
    
}

