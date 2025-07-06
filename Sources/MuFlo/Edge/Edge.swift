//  FloEdge.swift
//  created by musesum on 3/10/19.

import Foundation

public class Edge: Hashable {
    var id = Visitor.nextId()
    var edgeKey = "" // created with makeKey()
    var edgeOps = EdgeOptions()
    var active = true
    var leftFlo: Flo
    var rightFlo: Flo
    var edgeExpress: Exprs?
    var plugDefs: EdgeDefArray?  /// reference to EdgePlugin [EdgeDef] array

    public static let LineageDepth = 99 

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeKey)
    }

    public static func == (lhs: Edge, rhs: Edge) -> Bool {
        return lhs.edgeKey == rhs.edgeKey
    }

    convenience init(with: Edge) {

        self.init(with.leftFlo, with.rightFlo, with.edgeOps, with.plugDefs)
        self.active = with.active
        self.edgeExpress = with.edgeExpress
        makeKey()
    }

   init(_ leftFlo: Flo,
        _ rightFlo: Flo,
        _ edgeOps: EdgeOptions,
        _ plugDefs: EdgeDefArray?) {

        self.edgeOps = edgeOps
        self.leftFlo = leftFlo
        self.rightFlo = rightFlo
        self.plugDefs = plugDefs
        makeKey()
    }
    convenience init(_ def: EdgeDef,
                     _ leftFlo: Flo,
                     _ rightFlo: Flo,
                     _ exprs: Exprs?,
                     _ plugDefs: EdgeDefArray?) {

        self.init(leftFlo, rightFlo, def.edgeOps, plugDefs)
        self.edgeExpress = exprs
        makeKey()
    }
    func makeKey() {
        let lhs = "\(leftFlo.id)"
        let rhs = "\(rightFlo.id)"
        let arrow = edgeOps.script(active: false)
        edgeKey = lhs + arrow + rhs
    }
    
}
