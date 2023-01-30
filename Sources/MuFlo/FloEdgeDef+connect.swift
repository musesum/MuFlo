//  FloEdgeDef+connect.swift
//
//  Created by warren on 4/29/19.


import Foundation

extension FloEdgeDef {

    func connectNewEdge(_ leftFlo: Flo, _ rightFlo: Flo, _ floVal: FloVal?) {

        let newEdge = FloEdge(self, leftFlo, rightFlo, floVal)
        let newKey = newEdge.edgeKey

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
        // begin -----------------------------
        if edgeOps.exclude {
            excludeEdge()
        } else if edgeOps.copyat {
            addEdge()
            connectCopyr(leftFlo, rightFlo, floVal)
        } else {
            addEdge()
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

    /// find d.a1 relative to h
    func connectTernCondition(_ tern: FloValTern, _ flo: Flo, _ ternPathFlos: [Flo]) {

        /// input to Ternary is output from pathFlo
        func connectTernIfEdge(_ ternPathFlo: Flo, _ pathFlo: Flo) {

            //print(pathFlo.scriptLineage(2) + " ◇→ " + ternPathFlo.scriptLineage(2))
            let edge = FloEdge(pathFlo, ternPathFlo, [.output, .ternIf])
            pathFlo.floEdges[edge.edgeKey] = edge

            for edgeDef in ternPathFlo.edgeDefs.edgeDefs {
                if edgeDef == self { return edgeDef.edges[edge.edgeKey] = edge }
            }
            let edgeDef = FloEdgeDef(with: self)
            edgeDef.edges[edge.edgeKey] = edge
            ternPathFlo.edgeDefs.edgeDefs.append(edgeDef)
        }

        // ────────────── begin ──────────────

        tern.pathFlos.removeAll()

        let found = flo.findPathFlos(tern.path, [.parents, .children])
        if found.isEmpty {
            // find b1 relative to d.a1 and c1 relative to d.a1.b1
            // paths with a˚b may produce duplicates so filter out with foundSet
            var foundSet = Set<Flo>()
            for ternPathFlo in ternPathFlos {
                let foundThen = ternPathFlo.findPathFlos(tern.path, [.parents, .children])
                for flo in foundThen {
                    foundSet.insert(flo)
                }
            }
            tern.pathFlos.removeAll()
            tern.pathFlos.append(contentsOf: foundSet)
            // sorting by triplet (a.b.c) is unnecessary for runtime, but nice for debugging
            tern.pathFlos.sort(by:{ $0.scriptLineage(2) < $1.scriptLineage(2) })
        }
        else {
            tern.pathFlos = found
        }
        for pathFlo in tern.pathFlos {
            connectTernIfEdge(flo, pathFlo)
            if tern.compareOp != "",  let compareRight = tern.compareRight {
                compareRight.pathFlos = pathFlo.findPathFlos(compareRight.path, [.parents, .children])
                for rightFlo in compareRight.pathFlos {
                    connectTernIfEdge(flo, rightFlo)
                }
            }
        }
    }

    /// output from ternary is input to pathFlo
    func connectTernPathEdge(_ ternFlo: Flo, _ pathFlo: Flo) {
        //print(pathFlo.scriptLineage(3) + " ◇→ " + pathFlo.scriptLineage(2))
        let flipOps = FloEdgeOps(flipIO: edgeOps)
        let edge = FloEdge(pathFlo, ternFlo, flipOps)
        
        edge.edgeOps.insert(.ternGo)
        
        pathFlo.floEdges[edge.edgeKey] = edge
        if flipOps.input {
            ternFlo.floEdges[edge.edgeKey] = edge
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
        for pathFlo in valPath.pathFlos {
            connectTernPathEdge(flo, pathFlo)
        }
    }

    /// b1 in `<- (a1 ? b1 ? c1 : 1)` Connect inner ternary.
    ///
    /// Location of b1 maybe relative a1, for example:
    ///
    ///     d {a1 a2}:{b1 b2}:{c1 c2} h <- (d.a1 ? b1 ? c1 : 1)
    ///
    /// will find b1 as child of d.a1
    ///
    func connectValTern(_ tern: FloValTern, _ flo: Flo, _ foundFlos: [Flo]) {
        // IF
        connectTernCondition(tern, flo, foundFlos) // f.i
        // THEN
        switch tern.thenVal {
        case let thenTern as FloValTern: connectValTern(thenTern, flo, tern.pathFlos)
        case let thenPath as FloValPath: connectValPath(thenPath, flo, tern.pathFlos)
        default: break
        }
        // ELSE
        switch tern.elseVal {
        case let elseTern as FloValTern: connectValTern(elseTern, flo, tern.pathFlos)
        case let elsePath as FloValPath: connectValPath(elsePath, flo, tern.pathFlos)
        default: break
        }
        // RADIO
        if let radioNext = tern.radioNext {
            connectValTern(radioNext, flo, [])
        }
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
        // ternary
        else if let tern = ternVal {
            // a˚z <- (...)
            if flo.type == .path {
                let found =  flo.findAnchor(flo.name, [.parents, .children])
                if found.count > 0 {
                    for foundi in found {
                        let foundTern = FloValTern(with: tern)
                        if !foundi.edgeDefs.overideEdgeTernary(foundTern) {
                            foundi.edgeDefs.addEdgeTernary(foundTern, copyFrom: flo)
                            connectValTern(foundTern, foundi, [])
                        }
                    }
                    return
                }
            }
            // a <- (...) single instance
            connectValTern(tern, flo, [])
        }
    }
}
