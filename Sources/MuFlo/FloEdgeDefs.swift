//  FloEdgeDefs.swift
//
//  Created by warren on 4/28/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public class FloEdgeDefs {

    var edgeDefs = [FloEdgeDef]()

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

    /// override old ternary with new value
    public func overideEdgeTernary(_ tern_: FloValTern) -> Bool {

        for edgeDef in edgeDefs {
            if let ternPath = edgeDef.ternVal?.path,
                ternPath == tern_.path {

                edgeDef.ternVal = tern_.copy()
                return true
            }
        }
        return false
    }
    func mergeEdgeDefs(_ merge: FloEdgeDefs) {

        func isUnique(_ mergeDef: FloEdgeDef) -> Bool {
            for edgeDef in edgeDefs {
                if edgeDef == mergeDef { return false }
            }
            return true
        }

        // begin ----------------------
        
        for mergeDef in merge.edgeDefs {
            if isUnique(mergeDef) {
                if mergeDef.edgeOps.solo {
                    edgeDefs = merge.edgeDefs
                }
                else if edgeDefs.first?.edgeOps.solo ?? false {
                    // keep solo from previous definition
                }
                else {
                     edgeDefs.append(mergeDef)
                }
                break
            }
            if let mergeTernVal = mergeDef.ternVal {
                if !overideEdgeTernary(mergeTernVal) {
                    addEdgeTernary(mergeTernVal)
                }
            }
        }
    }
    /** add ternary to array of edgeDefs
     */
     public func addEdgeTernary(_ tern_: FloValTern, copyFrom: Flo? = nil) {

         if let lastEdgeDef = edgeDefs.last {

             if let lastTern = lastEdgeDef.ternVal {
                 lastTern.deepAddVal(tern_)
             }
             else {
                 lastEdgeDef.ternVal = tern_
                 FloValTern.ternStack.append(tern_)
             }
         }
             // copy edgeDef from search z in
         else if let copyEdgeDef = copyFrom?.edgeDefs.edgeDefs.last {

             let newEdgeDef = FloEdgeDef(with: copyEdgeDef)
             edgeDefs.append(newEdgeDef)
             newEdgeDef.ternVal = tern_
             FloValTern.ternStack.append(tern_)
         }
         else {
             print("🚫 \(#function) no edgeDefs to add edge")
         }
     }
    /** add exprs to array of edgeDefs
     */
    public func parseEdgeExprs(_ flo: Flo) {
        if let pathVals = edgeDefs.last?.pathVals {
            pathVals.add(val: FloValExprs(flo, "edge")) //?? 
        }
        else {
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
        }
        else {
            return edgeDefs.last!
        }
    }

    /// connect direct or ternary edges
    func bindEdges(_ flo: Flo) {
        for edgeDef in edgeDefs {
            edgeDef.connectEdges(flo)
        }
    }
}
