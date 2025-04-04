//  created by musesum on 1/1/21.

import Foundation

@MainActor //_____
public class EvalAny {
    
    public var op = EvalOp.none
    public var any: Any?
    
    public init(op     : EvalOp)  { self.op = op }
    public init(from   : EvalAny) { self.op = from.op ; any = from.any }
    public init(str    : String)  { self.op = EvalOp(str) }
    public init(name   : String)  { self.op = .name    ; any = name }
    public init(path   : String)  { self.op = .path    ; any = path }
    public init(quote  : String)  { self.op = .quote   ; any = quote }
    public init(toolip : String)  { self.op = .tooltip ; any = toolip }
    public init(scalar : Scalar)  { self.op = .scalar  ; any = scalar }

    func copy() -> EvalAny { return EvalAny(from: self) }

    func scriptDefOps(_ scriptOps: FloScriptOps,
                      _ script: String) -> String {

        switch op {
        case .name   : return any as? String ?? ""
        case .quote  : return scriptQuote()
        case .tooltip: return scriptTip()
        case .scalar : return scriptScalar()
        case .comma  : return op.rawValue + " "
        case .EQ     : return op.rawValue + " "
        case .assign : return op.rawValue + " "
        default      : return scriptOps.def ? op.rawValue : ""
        }
        
        func scriptScalar() -> String {
            if let scalar = any as? Scalar {
                return scalar.scriptScalar(scriptOps, .def)
            }
            return ""
        }
        func scriptQuote() -> String {
            if let str = any as? String {
                return "\"\(str)\""
            }
            return ""
        }
        func scriptTip() -> String {
            if let str = any as? String {
                return "'\(str)'"
            }
            return ""
        }
    }
    
}

