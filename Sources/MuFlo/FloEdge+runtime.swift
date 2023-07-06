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

        logSync()

        if ((fromLeft && edgeOps.hasOutput && !visitedRight) ||
            (fromRight && edgeOps.hasInput && !visitedLeft )) {

            let fromExprs = fromFlo.exprs

            if  destFlo.setEdgeVal(edgeExprs, fromExprs, visit) {

                destFlo.activate(visit)

            } else {
                /// Did not meet conditionals, so stop.
                /// for example, when cc != 13 for
                /// `repeatX(cc == 13, val 0…127, chan, time)`
            }
        }
        func setEdgeVal(_ destFlo: Flo,
                        _ edgeExprs: FloExprs?,     /// `(2)` in `b(0…1) >> a(2)`
                        _ fromExprs: FloExprs?)  {   /// `(0…1)` in `b(0…1) >> a`
            

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

            var arrow = fromLeft ? " ⫸" : "⫷ "
            arrow += edgeOps.hasPlugin ? "⚡️ " : " "

            print ("\n(" +
                   "\(script(leftFlo))" + arrow +
                   " \(script(rightFlo))"
                   , terminator: ") ")

            func script(_ flo: Flo) -> String {
                guard let exprs = flo.exprs else { return "[]" }
                let plugged = !flo.plugins.isEmpty ? "⚡️" : ""

                var str = "\(flo.path(9)).\(flo.id)\(plugged)["
                var del = ""
                for (name,any) in exprs.nameAny {
                    if let scalar = any as? FloValScalar {
                        let valStr = scalar.val.digits(0...2)
                        let tweStr = scalar.twe.digits(0...2)
                        str += del + "\(name): \(valStr)/\(tweStr)"
                        del = ", "
                    }
                    str += "]"
                }
                return str
            }
        }
    }

}

