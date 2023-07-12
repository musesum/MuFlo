//  Created by warren on 6/16/22.

import Foundation

extension FloEdgeDefs {

    func scriptEdgeVal(_ scriptOps: FloScriptOps,
                       noParens: Bool = false) -> String {

        var script = ""

        for edgeDef in edgeDefs {

            script.spacePlus(edgeDef.scriptVal(scriptOps))
        }
        return script
    }
}
