//  FloEdge+runtime.swift
//
//  Created by warren on 5/10/19.
//  Copyright © 2019 DeepMuse

import Foundation
import MuPar // visit

extension FloEdge {
    
    func followEdge(_ fromFlo: Flo,
                    _ visit: Visitor) {

        let fromLeft = fromFlo == leftFlo // a >> b
        let fromRight = !fromLeft       // a << b
        let destFlo = fromLeft ? rightFlo : leftFlo
        let visitedLeft = visit.wasHere(leftFlo.id)
        let visitedRight = visit.wasHere(rightFlo.id)

        if ((fromLeft && edgeOps.hasOutput && !visitedRight) ||
            (fromRight && edgeOps.hasInput && !visitedLeft )) {

            logEdge() //????  logSync()

            let fromExprs = fromFlo.exprs

            if  destFlo.setEdgeVal(edgeExprs, fromExprs, visit) {

                destFlo.activate(visit)

            } else {
               //???? visit.block(destFlo)
            }
        }
        
        func logSync() {
            if edgeOps.hasSync {
                let leftScript = leftFlo.exprs?.scriptExprs(.Now, false) ?? ""
                let rightScript = rightFlo.exprs?.scriptExprs(.Now, false) ?? ""
                let leftPathScript = leftFlo.path(2) + "(\(leftScript))"
                let rightPathScript = rightFlo.path(2) + "(\(rightScript))"
                print ("sync: \(edgeKey)  \(leftPathScript) <> \(rightPathScript)")
            }
        }
        func logEdge() {
            guard leftFlo.name.contains("repeat") ||
                    rightFlo.name.contains("repeat") else { return }
            let arrow = fromLeft ? " ⫸ " : " ⫷ "
            let op = edgeOps.script(active: true)
            let edge = "\(leftFlo.id) \(op) \(rightFlo.id)".pad(13)
            print (edge + arrow + script(leftFlo) + arrow + script(rightFlo))

            func script(_ flo: Flo) -> String {
                guard let exprs = flo.exprs else { return "()" }
                let plugged = !flo.plugins.isEmpty ? "⚡️" : "/"

                var str = "\(flo.path(3))"
                var del = "("
                for (name,any) in exprs.nameAny {
                    if ["x","y","val"].contains(name),
                       let scalar = any as? FloValScalar {

                            let valStr = scalar.val.digits(0...2)
                            let tweStr = scalar.twe.digits(0...2)
                            str += del + "\(name): \(valStr)\(plugged)\(tweStr)"
                            del = ", "
                    }
                }
                return "\(str))"
            }
        }
    }

}

