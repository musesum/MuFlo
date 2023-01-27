//  FloEdgeDef.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import Par // ParItem 

public class FloEdgeDef {

    var edgeFlags = FloEdgeFlags()
    var pathVals = FloPathVals()
    var ternVal: FloValTern?
    var edges = [String: FloEdge]() // each edge is also shared by two Flos
    
    init() { }

    init(flags: FloEdgeFlags) {
        self.edgeFlags = flags
    }
    
    init(with fromDef: FloEdgeDef) {
        
        edgeFlags = fromDef.edgeFlags
        for (path,val) in fromDef.pathVals.pathVal { // pathVals = with.pathVal
            switch val {
                case let val as FloValTern:   pathVals.add(path: path, val: val.copy())
                case let val as FloValScalar: pathVals.add(path: path, val: val.copy())
                case let val as FloExprs:     pathVals.add(path: path, val: val.copy())
                default:                      pathVals.add(path: path, val: val)
            }
        }
        ternVal = fromDef.ternVal?.copy()
    }
    
    func copy() -> FloEdgeDef {
        let newEdgeDef = FloEdgeDef(with: self)
        return newEdgeDef
    }
    func addLastPath(_ lastPath: String, val: FloVal) {
        
    }
    func addPath(_ parItem: ParItem) {

        if let path = parItem.nextPars.first?.value {

            if let _ = ternVal {
                FloValTern.ternStack.last?.addPath(path)
            }
            else {
                pathVals.add(path: path, val: nil)
            }
        }
        else {
            print("🚫 FloEdgeDef: \(self) cannot process addPath(\(parItem))")
        }
    }

    static func == (lhs: FloEdgeDef, rhs: FloEdgeDef) -> Bool {
        return lhs.pathVals == rhs.pathVals
    }

    public func printVal() -> String {
        return scriptVal([.parens,.now,.expand])
    }
    
    public func scriptVal(_ scriptFlags: FloScriptFlags) -> String{
        
        var script = edgeFlags.script()
        
        if let tern = ternVal {
            script.spacePlus(tern.scriptVal(scriptFlags))
        }
        else {
            if pathVals.pathVal.count > 1 { script += "(" }
            for (path,val) in pathVals.pathVal {
                script += path
                script += val?.scriptVal(scriptFlags) ?? ""
            }
            if pathVals.pathVal.count > 1 { script += ")" }
        }
        return script
    }
    
}
