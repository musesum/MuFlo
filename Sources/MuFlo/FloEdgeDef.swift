//  FloEdgeDef.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar // ParItem 

public class FloEdgeDef {

    var edgeOps = FloEdgeOps()
    var pathVals = FloPathVals()
    var edges = [String: FloEdge]() // each edge is also shared by two Flos
    
    init() { }

    init(_ edgeOps: FloEdgeOps) {
        self.edgeOps = edgeOps
    }
    
    init(with fromDef: FloEdgeDef) {
        
        edgeOps = fromDef.edgeOps
        for (path,val) in fromDef.pathVals.edgeVals { // pathVals = with.pathVal

                pathVals.addPathVal(path, val?.copy()) 
        }
    }
    
    func copy() -> FloEdgeDef {
        let newEdgeDef = FloEdgeDef(with: self)
        return newEdgeDef
    }
    func addLastPath(_ lastPath: String, val: FloVal) {
        
    }
    func addPath(_ parItem: ParItem) {

        if let path = parItem.nextPars.first?.value {

            pathVals.addPathVal(path, nil)
            
        } else {
            print("🚫 FloEdgeDef: \(self) cannot process addPath(\(parItem))")
        }
    }

    static func == (lhs: FloEdgeDef, rhs: FloEdgeDef) -> Bool {
        return lhs.pathVals == rhs.pathVals
    }

    public func printVal() -> String {
        return scriptVal([.parens, .val, .expand])
    }
    
    public func scriptVal(_ scriptOps: FloScriptOps,
                          noParens: Bool = false) -> String {
        
        var script = edgeOps.script()
        
        if pathVals.edgeVals.count > 1 { script += "(" }
        for (path,val) in pathVals.edgeVals {
            script += path
            script += val?.scriptVal(scriptOps) ?? ""
        }
        if pathVals.edgeVals.count > 1 { script += ")" }
        return script
    }
    
}
