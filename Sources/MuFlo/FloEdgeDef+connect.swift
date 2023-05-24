//  FloEdgeDef+connect.swift
//
//  Created by warren on 4/29/19.


import Foundation

extension FloEdgeDef {

    func connectNewEdge(_ leftFlo: Flo, _ rightFlo: Flo, _ floVal: FloVal?) {

        let newEdge = FloEdge(self, leftFlo, rightFlo, floVal)
        let newKey = newEdge.edgeKey

        if edgeOps.exclude {
            excludeEdge()
        } else if edgeOps.copyat {
            addEdge()
            connectCopyr(leftFlo, rightFlo, floVal)
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
    func connectCopyr(_ leftFlo: Flo, _ rightFlo: Flo, _ floVal: FloVal?)  {
        var rights = [String: Flo]()
        for rightChild in rightFlo.children {
            rights[rightChild.name] = rightChild
        }
        for leftChild in leftFlo.children {
            if let rightChild = rights[leftChild.name] {
                FloEdgeDef(edgeOps)
                .connectNewEdge(leftChild, rightChild, floVal)
            }
        }
    }

    /// b in `<- (a ? b)`
    /// Connect results of ternIf. Filter out redundant results in Set.
    ///
    /// in the following example:
    ///
    ///         d {a1 a2}:{b1 b2} e <- (d˚b1 ? d˚b2)
    ///
    /// the results of d˚b2 for both d.a1.b1 and d.a1.b2, will produce
    ///
    ///         (d.a1.b2 d.a2.b2) and (d.a1.b2 d.a2.b2)
    ///
    /// so use a Set<Flo> to filter out redundant flos
    /// before saving filtered results into valPath.pathFlos
    ///
    func connectValPath(_ valPath: FloValPath, _ flo: Flo, _ leftFlos: [Flo]) {

        var foundSet = Set<Flo>()

        for leftFlo in leftFlos {
            let foundFlos = leftFlo.findPathFlos(valPath.path, [.parents, .children])
            for flo in foundFlos {
                foundSet.insert(flo)
            }
        }
        valPath.pathFlos.removeAll()
        valPath.pathFlos.append(contentsOf: foundSet)
        valPath.pathFlos.sort(by:{ $0.scriptLineage(2) < $1.scriptLineage(2) })
    }

    /// batch connect edges - convert from FloEdgeDef to FloEdges
    func connectEdges(_ flo: Flo)  {
        
        // non ternary edges
        if pathVals.pathVal.count > 0 {
            
            for (path,val) in pathVals.pathVal {
                if let pathRefs = flo.pathRefs {
                    for pathRef in pathRefs {
                        let rightFlos = pathRef.findPathFlos(path, [.parents, .children])
                        for rightFlo in rightFlos {
                            connectNewEdge(pathRef, rightFlo, val)
                        }
                    }
                }
                else {
                    let rightFlos = flo.findPathFlos(path, [.parents, .children])
                    for rightFlo in rightFlos {
                        connectNewEdge(flo, rightFlo, val)
                    }
                }
            }
        }
    }
}
