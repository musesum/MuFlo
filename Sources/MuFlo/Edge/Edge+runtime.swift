//  FloEdge+runtime.swift
//  created by musesum on 5/10/19.

import Foundation

extension Edge {
    
    func followEdge(_ fromFlo: Flo,
                    _ visit: Visitor,
                    _ depth: Int) -> Flo? {

        guard visit.newVisit(id) else { return nil }

        let fromLeft = fromFlo == leftFlo // a(-> b)
        let fromRight = !fromLeft       // a(<- b)
        let destFlo = fromLeft ? rightFlo : leftFlo
        let visitedLeft = visit.wasHere(leftFlo.id)
        let visitedRight = visit.wasHere(rightFlo.id)

        if ((fromLeft && edgeOps.hasOutput && !visitedRight) ||
            (fromRight && edgeOps.hasInput && !visitedLeft )) {

            // logEdge()

            if  destFlo.setEdgeVal(edgeExpress, fromFlo, visit) {
                logDepth("👍")
                return destFlo
            } else {
                logDepth("⛔️")
                visit.block(destFlo.id)
            }
            func logDepth(_ icon: String) {
                //TimeLog("FloEdge::followEdge", interval: 1) { P("".pad(depth*3) + "\(icon) \(destFlo.path(3)): \(destFlo.float)", terminator: "") }
            }
        }
        return nil

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
                       let scalar = any as? Scalar {

                            let valStr = scalar.value.digits(0...2)
                            let tweStr = scalar.tween.digits(0...2)
                            str += del + "\(name): \(valStr)\(plugged)\(tweStr)"
                            del = ", "
                    }
                }
                return "\(str))"
            }
        }
    }

}

