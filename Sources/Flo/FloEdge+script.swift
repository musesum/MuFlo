//  FloEdge+script.swift
//
//  Created by warren on 5/18/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

extension FloEdge {
    
    func scriptEdgeVal(_ flo: Flo, _ scriptFlags: FloScriptFlags) -> String {

        var script = ""

        if leftFlo == flo {
            script += rightFlo.scriptLineage(FloEdge.LineageDepth)
        }
        else if rightFlo == flo {
            script += leftFlo.scriptLineage(FloEdge.LineageDepth)
        }
        script += defVal?.scriptVal(scriptFlags) ?? ""
        return script
    }

}
