//  Created by warren on 6/16/22.

import Foundation

extension FloEdgeDefs {

    func printVal() -> String {
        return scriptVal([.now])
    }

    func scriptVal(_ scriptOpts: FloScriptOps) -> String {

        var script = ""

        for edgeDef in edgeDefs {

            let val = edgeDef.scriptVal(scriptOpts)

            script += val
        }
        return script
    }
}
