//  FloEdge.swift
//  created by musesum on 3/10/19.

import Foundation

public class FloEdge: Hashable {

    var id = Visitor.nextId()
    var edgeKey = "" // created with makeKey()

    var edgeOps = FloEdgeOps()
    var active = true
    var leftFlo: Flo
    var rightFlo: Flo
    var edgeExprs: FloExprs?
    var plugDefs: EdgeDefs?

    public static var LineageDepth = 99 

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeKey)
    }

    public static func == (lhs: FloEdge, rhs: FloEdge) -> Bool {
        return lhs.edgeKey == rhs.edgeKey
    }

    convenience init(with: FloEdge) {

        self.init(with.leftFlo, with.rightFlo, with.edgeOps, with.plugDefs)
        self.active = with.active
        self.edgeExprs = with.edgeExprs
        makeKey()
    }

   init(_ leftFlo: Flo,
        _ rightFlo: Flo,
        _ edgeOps: FloEdgeOps,
        _ plugDefs: EdgeDefs?) {

        self.edgeOps = edgeOps
        self.leftFlo = leftFlo
        self.rightFlo = rightFlo
        self.plugDefs = plugDefs
        makeKey()
    }
    convenience init(_ def: FloEdgeDef,
                     _ leftFlo: Flo,
                     _ rightFlo: Flo,
                     _ edgeVal: FloExprs?,
                     _ plugDefs: EdgeDefs?
        ) {

        self.init(leftFlo, rightFlo, def.edgeOps, plugDefs)
        self.edgeExprs = edgeVal
        makeKey()
    }
    func makeKey() {
        let lhs = "\(leftFlo.id)"
        let rhs = "\(rightFlo.id)"
        let arrow = edgeOps.script(active: false)
        edgeKey = lhs + arrow + rhs
    }
    
}
