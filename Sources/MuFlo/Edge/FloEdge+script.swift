//  FloEdge+script.swift
//  created by musesum on 5/18/19.


import Foundation

extension FloEdge {
    
    func scriptEdgeVal(_ flo: Flo,
                       _ scriptOpts: FloScriptOps) -> String {

        let depth = FloEdge.LineageDepth
        var script = (leftFlo == flo
                      ? rightFlo.scriptLineage(depth)
                      : leftFlo.scriptLineage(depth))

        if let edgeExprs {
            let viaEdge = true
            script += edgeExprs.scriptVal(scriptOpts, viaEdge)
        }
        return script
    }

}
