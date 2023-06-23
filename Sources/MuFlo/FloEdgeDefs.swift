//  FloEdgeDefs.swift
//
//  Created by warren on 4/28/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation


typealias EdgeDefs = ArrayClass<FloEdgeDef>

/// define one or more edges
public class FloEdgeDefs {

    var edgeDefs = EdgeDefs()  /// `a <> ˚˚`
    var plugDefs = EdgeDefs()  /// a `<< ˚˚ ^ recorder`

    convenience init(with: FloEdgeDefs) {
        self.init()
        for edgeDef in with.edgeDefs {
            edgeDefs.append(edgeDef.copy())
        }
    }
    func copy() -> FloEdgeDefs {
        let newEdgeDefs = FloEdgeDefs(with: self)
        return newEdgeDefs
    }

    func mergeEdgeDefs(_ merge: FloEdgeDefs) {

        for mergeDef in merge.edgeDefs {
            if isUnique(mergeDef) {
                if mergeDef.edgeOps.hasSolo {
                    edgeDefs = merge.edgeDefs
                }
                else if edgeDefs.first?.edgeOps.hasSolo ?? false {
                    // keep solo from previous definition
                }
                else {
                    edgeDefs.append(mergeDef)
                }
                break
            }
        }
        
        func isUnique(_ mergeDef: FloEdgeDef) -> Bool {
            for edgeDef in edgeDefs {
                if edgeDef == mergeDef { return false }
            }
            return true
        }
    }
   
    /** add exprs to array of edgeDefs
     */
    public func parseEdgeExprs(_ flo: Flo) {
        if let pathVals = edgeDefs.last?.pathVals {
            pathVals.addPathVal("", FloExprs(flo, "edge"))
        } else {
            print("🚫 \(#function) no edgeDefs to add edge")
        }
    }

    public func addEdgeDef(_ edgeOp: String?) {
        if let edgeOp {
            let edgeOps = FloEdgeOps(with: edgeOp)
            let edgeDef = FloEdgeDef(edgeOps)
            edgeDefs.append(edgeDef)
        }
    }
    /// parsing always decorates the last current FloEdgeDef
    /// if there isn't a last FloEdgeDef, then make one
    public func lastEdgeDef() -> FloEdgeDef {
        if edgeDefs.isEmpty {
            let edgeDef = FloEdgeDef()
            edgeDefs.append(edgeDef)
            return edgeDef
        } else {
            return edgeDefs.last!
        }
    }

    /// connect direct edges
    func bindEdges(_ flo: Flo) {
        let bindDefs = ArrayClass<FloEdgeDef>()
        for edgeDef in edgeDefs {
            if edgeDef.edgeOps.hasPlugin {
                plugDefs.append(edgeDef)
            } else {
                bindDefs.append(edgeDef)
            }
        }
        edgeDefs = bindDefs
        for edgeDef in edgeDefs {
            edgeDef.connectEdges(flo, plugDefs)
        }
        for plugDef in plugDefs {
            plugDef.connectEdges(flo, plugDefs)
        }
    }
}
