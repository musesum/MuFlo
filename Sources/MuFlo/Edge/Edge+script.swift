//  FloEdge+script.swift
//  created by musesum on 5/18/19.


import Foundation

extension Edge {

    func scriptEdgeVal(_ flo: Flo,
                       _ scriptOpts: FloScriptOps) -> String {

        var script = ""
        if flo.id == leftFlo.id {
            script = rightFlo.scriptLineage(up: leftFlo) ?? ""
            if script == "", rightFlo.name == "√" {
                script = "√"
            }
        } else {
            script = leftFlo.scriptLineage(up: rightFlo) ?? ""
        }
        if script != "" {
            script += edgeExpress?.scriptVal(flo, scriptOpts, viaEdge: true) ?? ""
        }
        // debugScripts()
        return script

        func debugScripts() {
            let scripts: [String] = [
                leftFlo.scriptLineage(down: rightFlo) ?? "",
                leftFlo.scriptLineage(up: rightFlo) ?? "",
                rightFlo.scriptLineage(down: leftFlo) ?? "",
                rightFlo.scriptLineage(up: leftFlo) ?? "",
            ]
            print("\(flo.name):\(flo.children.count); \(leftFlo.name):\(leftFlo.children.count) \(rightFlo.name):\(rightFlo.children.count) \(scripts) \(script)")

        }

    }
}
