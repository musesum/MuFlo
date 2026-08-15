//  created by musesum on 4/28/19.

import Foundation

/// class reference to [EdgeDef]
typealias EdgeDefArray = ArrayClass<EdgeDef>

/// define one or more edges
public class EdgeDefs {

    var edgeDefs = EdgeDefArray()  /// `a <> ˚˚`
    var plugDefs = EdgeDefArray()  /// a `<- ˚˚ ^ recorder`

    /// on a wildcard decl only: its authored stamp, read once while the decl
    /// still types `.path` — `merge` flips it to `.remove` on the first match,
    /// and every later match still needs the same identity. Never copied.
    var declProv: EdgeDefProv?

    convenience init(with: EdgeDefs) {
        self.init()
        for edgeDef in with.edgeDefs {
            edgeDefs.append(edgeDef.copy())
        }
    }
    func copy() -> EdgeDefs {
        let newEdgeDefs = EdgeDefs(with: self)
        return newEdgeDefs
    }
   
    /** add exprs to array of edgeDefs
     */
    public func addExpress(_ exprs: Exprs) {
        guard edgeDefs.count > 0 else { return }
        if let pathExpress = edgeDefs.last?.pathExprs {
            pathExpress.addExprs(exprs)
            
        } else {
            PrintLog("⁉️ \(#function) no edgeDefs to add edge")
        }
    }

    /// mark every def as merged from one authored wildcard declaration
    func stampProv(_ prov: EdgeDefProv) {
        for edgeDef in edgeDefs {
            edgeDef.declProv = prov
        }
    }

    public func addEdgeDef(_ edgeOp: String?) {
        if let edgeOp {
            let edgeOps = EdgeOptions(with: edgeOp)
            let edgeDef = EdgeDef(edgeOps)
            edgeDefs.append(edgeDef)
        }
    }
    /// parsing always decorates the last current FloEdgeDef
    /// if there isn't a last FloEdgeDef, then make one
    public func addPath(_ parsed: Parsed) {
        guard let path = parsed.nextResult else {
            return PrintLog("⁉️ FloEdgeDefs::\(#function) cannot process addPath(\(parsed))")
        }
        if edgeDefs.isEmpty {
            let edgeDef = EdgeDef()
            edgeDefs.append(edgeDef)
            edgeDef.pathExprs.addPathExprs(path, nil)
            //addPath(parsed)
        } else {
            edgeDefs.last!.addPath(parsed)
        }
    }

    /// connect direct edges
    func bindEdges(_ flo: Flo) {
        let edgeOnlyDefs = EdgeDefArray()
        for edgeDef in edgeDefs {
            if edgeDef.edgeOps.hasPlugin {
                plugDefs.append(edgeDef)
            } else {
                edgeOnlyDefs.append(edgeDef)
            }
        }
        edgeDefs = edgeOnlyDefs
        for edgeDef in edgeDefs {
            edgeDef.connectEdges(flo)
        }
        for plugDef in plugDefs {
            plugDef.connectEdges(flo, plugDefs)
        }
    }
}
