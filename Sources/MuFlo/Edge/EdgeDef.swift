
//  created by musesum on 3/10/19.

import Foundation

public class EdgeDef {

    var nextFrame: NextFrame?
    var edgeOps = EdgeOptions()
    var pathExprs = PathExprs()
    var edges = [String: Edge]() // each edge is also shared by two Flos
    
    init() { }

    init(_ edgeOps: EdgeOptions) {
        self.edgeOps = edgeOps
    }
    
    init(from: EdgeDef) {
        
        edgeOps = from.edgeOps
        for (path,exprs) in from.pathExprs {
            pathExprs.addPathExprs(path, exprs?.copy())
        }
        pathExprs = from.pathExprs.copy()
    }
    
    func copy() -> EdgeDef {
        let newEdgeDef = EdgeDef(from: self)
        return newEdgeDef
    }
    
    func addPath(_ parsed: Parsed) {

        if let path = parsed.nextResult {

            pathExprs.addPathExprs(path, nil)

        } else {
            PrintLog("⁉️ FloEdgeDef: \(self) cannot process addPath(\(parsed))")
        }
    }

    static func == (lhs: EdgeDef, rhs: EdgeDef) -> Bool {
        return lhs.pathExprs == rhs.pathExprs
    }

    public func printVal(_ flo: Flo) -> String {
        return scriptVal(flo, [.parens, .now, .expand])
    }
    
    public func scriptVal(_ from: Flo,
                          _ scriptOps: FloScriptOps,
                          noParens: Bool = false) -> String {
        
        var script = edgeOps.script(active: true)
        
        if pathExprs.count > 1 { script += "(" }
        var delim = ""
        for (path,val) in pathExprs {
            script += delim+path; delim = ", "
            script += (val?.scriptVal(from, scriptOps, viaEdge: true) ?? "")
        }
        if pathExprs.count > 1 { script += ")" }
        return script
    }
    
}
