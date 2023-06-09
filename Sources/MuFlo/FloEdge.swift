//
//  FloEdge.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar

public class FloEdge: Hashable {

    var id = Visitor.nextId()
    var edgeKey = "" // created with makeKey()

    var edgeOps = FloEdgeOps()
    var active = true
    var leftFlo: Flo
    var rightFlo: Flo
    var edgeVal: FloExprs?

    public static var LineageDepth = 99 

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeKey)
    }

    public static func == (lhs: FloEdge, rhs: FloEdge) -> Bool {
        return lhs.edgeKey == rhs.edgeKey
    }

    convenience init(with: FloEdge) { // was operator = in c++ version

        self.init(with.leftFlo, with.rightFlo, with.edgeOps)
        self.active = with.active
        self.edgeVal = with.edgeVal
        makeKey()
    }

   init(_ leftFlo: Flo,
        _ rightFlo: Flo,
        _ edgeOps: FloEdgeOps) {

        self.edgeOps = edgeOps
        self.leftFlo = leftFlo
        self.rightFlo = rightFlo
        makeKey()
    }
    convenience init(_ def: FloEdgeDef,
                     _ leftFlo: Flo,
                     _ rightFlo: Flo,
                     _ edgeVal: FloExprs?) {

        self.init(leftFlo, rightFlo, def.edgeOps)
        self.edgeVal = edgeVal
        makeKey()
    }
    func makeKey() {
        let lhs = "\(leftFlo.id)"
        let rhs = "\(rightFlo.id)"
        let arrow = edgeOps.script(active: false)
        edgeKey = lhs + arrow + rhs
    }
    
}
