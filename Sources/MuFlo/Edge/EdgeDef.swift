
//  created by musesum on 3/10/19.

import Foundation

/// Authored wildcard declaration behind a merged EdgeDef.
///
/// A wildcard decl (`*`, `˚algo`, leading `.`) never survives to export;
/// `Flo.merge` copies its edgeDefs onto every matched node instead. The stamp
/// keeps the authored text plus one identity per declaration, so a consumer can
/// rejoin the scattered copies. Ordinary base copies `f : d` stay unstamped.
struct EdgeDefProv {
    let text: String       /// authored decl name, `*` or `˚algo`
    let script: String     /// full decl text, `˚algo(-> ..(on 1))`, no comments
    let declId: Int        /// one identity per declaration, the decl Flo id
    let declType: FloType  /// declaring Flo type, `.path` for wildcards
}

public class EdgeDef {

    var edgeOps = EdgeOptions()
    var pathExprs = PathExprs()
    var edges = [String: Edge]() // each edge is also shared by two Flos
    var declProv: EdgeDefProv?  // set by merge; nil when hand written
    
    init() { }

    init(_ edgeOps: EdgeOptions) {
        self.edgeOps = edgeOps
    }
    
    /// - note: `declProv` is deliberately not carried; a copy of a copy is a
    /// new scope, and only the merge site knows which declaration made it.
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
