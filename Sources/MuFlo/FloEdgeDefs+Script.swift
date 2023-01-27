//
//  File.swift
//  
//
//  Created by warren on 6/16/22.
//

import Foundation

extension FloEdgeDefs {

    func printVal() -> String {
        return scriptVal([.now])
    }

    func scriptVal(_ scriptFlags: FloScriptFlags) -> String {

        var script = ""

        for edgeDef in edgeDefs {

            let val = edgeDef.scriptVal(scriptFlags)

            script += val
        }
        return script
    }
}
