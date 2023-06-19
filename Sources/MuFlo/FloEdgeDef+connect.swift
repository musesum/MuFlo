//  FloEdgeDef+connect.swift
//
//  Created by warren on 4/29/19.


import Foundation

extension FloEdgeDef {

    func connectNewEdge(_ leftFlo: Flo,
                        _ rightFlo: Flo,
                        _ val: FloExprs?,
                        _ plugDefs: EdgeDefs?) {

        let newEdge = FloEdge(self, leftFlo, rightFlo, val, plugDefs)
        let newKey = newEdge.edgeKey

        if edgeOps.hasExclude {
            excludeEdge()
        } else if edgeOps.hasCopyat {
            addEdge()
            connectCopyr(leftFlo, rightFlo, val, plugDefs)
        } else {
            addEdge()
        }

        func addEdge() {
            leftFlo.floEdges[newKey] = newEdge
            rightFlo.floEdges[newKey] = newEdge
            edges[newKey] = newEdge
        }
        func excludeEdge() {
            if let oldEdge = edges[newKey] {
                oldEdge.edgeOps.remove(edgeOps)
                if oldEdge.edgeOps.isEmpty {
                    edges.removeValue(forKey: newKey)
                }
            }
        }
    }
    func connectCopyr(_ leftFlo: Flo,
                      _ rightFlo: Flo,
                      _ floVal: FloExprs?,
                      _ plugDefs: EdgeDefs?)  {

        var rights = [String: Flo]()
        for rightChild in rightFlo.children {
            rights[rightChild.name] = rightChild
        }
        for leftChild in leftFlo.children {
            if let rightChild = rights[leftChild.name] {
                FloEdgeDef(edgeOps)
                .connectNewEdge(leftChild, rightChild, floVal, plugDefs)
            }
        }
    }

    
    /// batch connect edges - convert from FloEdgeDef to FloEdges
    func connectEdges(_ flo: Flo,
                      _ plugDefs: EdgeDefs?)  {
        
        if pathVals.edgeVals.count > 0 {
            
            for (path,val) in pathVals.edgeVals {
                if let pathRefs = flo.pathRefs {
                    for pathRef in pathRefs {
                        let rightFlos = pathRef.findPathFlos(path, [.parents, .children])
                        for rightFlo in rightFlos {
                            connectNewEdge(pathRef, rightFlo, val, plugDefs)
                        }
                    }
                }
                else {
                    let rightFlos = flo.findPathFlos(path, [.parents, .children])
                    for rightFlo in rightFlos {
                        connectNewEdge(flo, rightFlo, val, plugDefs)
                    }
                }
            }
        }
    }
}
