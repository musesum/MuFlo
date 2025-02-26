//  created by musesum on 6/16/22.

import Foundation

extension EdgeDefs { // + script

    func scriptEdgeVal(_ from: Flo,
                       _ scriptOps: FloScriptOps,
                       noParens: Bool = false) -> String {

        var script = ""

        for edgeDef in edgeDefs {

            script.spacePlus(edgeDef.scriptVal(from,scriptOps))
        }
        return script
    }
}
