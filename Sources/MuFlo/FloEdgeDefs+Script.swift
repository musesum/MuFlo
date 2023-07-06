//  Created by warren on 6/16/22.

import Foundation

extension FloEdgeDefs {

    func scriptEdgeVal(_ scriptOps: FloScriptOps,
                       noParens: Bool = false) -> String {

        var script = ""

        for edgeDef in edgeDefs {

            let val = edgeDef.scriptVal(scriptOps)

            script += val
        }
        return script
    }
}
