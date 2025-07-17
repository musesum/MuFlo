//  created by musesum on 4/29/19.

import Foundation

extension EdgeDef { // + connect

    /// batch connect edges - convert from FloEdgeDef to FloEdges
    func connectEdges(_ flo: Flo,
                      _ plugDefs: EdgeDefArray? = nil)  {

        if pathExprs.count > 0 {
            
            for (path,val) in pathExprs {
                if let pathRefs = flo.pathRefs {
                    for pathRef in pathRefs {
                        let rightFlos = pathRef.findPathFlos(path, [.parents, .children])
                        for rightFlo in rightFlos ?? [] {
                            connectNewEdge(pathRef, rightFlo, val, plugDefs)
                        }
                    }
                } else {

                    let rightFlos = flo.findPathFlos(path, [.parents, .children])
                    for rightFlo in rightFlos ?? [] {
                        connectNewEdge(flo, rightFlo, val, plugDefs)
                    }
                }
            }
        }
    }
    func connectNewEdge(_ leftFlo: Flo,
                        _ rightFlo: Flo,
                        _ exprs: Exprs?,
                        _ plugDefs: EdgeDefArray?) {

        let newEdge = Edge(self, leftFlo, rightFlo, exprs, plugDefs)
        let newKey = newEdge.edgeKey

       // print("\(#function) \(leftFlo.path(9)).\(leftFlo.id)  \(rightFlo.path(9)).\(rightFlo.id)  \(newKey)")

        if edgeOps.hasExclude {
            excludeEdge()
        } else if edgeOps.hasBase {
            addEdge()
            connectCopyr(leftFlo, rightFlo, exprs, plugDefs)
        } else {
            addEdge()
        }

        func addEdge() {

            leftFlo.floEdges[newKey] = newEdge
            rightFlo.floEdges[newKey] = newEdge
            leftFlo.plugDefs = plugDefs
            edges[newKey] = newEdge
            addPlugins()
        }
        func addPlugins() {
            guard let plugDefs else { return }
            for plugDef in plugDefs {
                for edge in plugDef.edges.values {
                    if edge.edgeOps.hasPlugin,
                       let plugExprs = edge.rightFlo.exprs,
                       let nextFrame
                    {
                        let plugin = EdgePlugin(edge.leftFlo, nextFrame, plugExprs)
                        leftFlo.plugins.append(plugin)
                    }
                }
            }
        }
        func excludeEdge() {
            if let oldEdge = edges[newKey] {
                oldEdge.edgeOps.remove(edgeOps)
                if oldEdge.edgeOps.isEmpty {
                    edges.removeValue(forKey: newKey)
                }
            }
        }
        func connectCopyr(_ leftFlo: Flo,
                          _ rightFlo: Flo,
                          _ exprs: Exprs?,
                          _ plugDefs: EdgeDefArray?)  {

            var rights = [String: Flo]()
            for rightChild in rightFlo.children {
                rights[rightChild.name] = rightChild
            }
            for leftChild in leftFlo.children {
                if let rightChild = rights[leftChild.name] {
                    EdgeDef(edgeOps)
                        .connectNewEdge(leftChild, rightChild, exprs, plugDefs)
                }
            }
        }
    }

}
