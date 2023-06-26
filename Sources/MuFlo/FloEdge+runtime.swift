//
//  FloEdge+runtime.swift
//
//  Created by warren on 5/10/19.
//  Copyright © 2019 DeepMuse

import Foundation
import MuPar // visit

extension FloEdge {
    
    func followEdge(_ fromFlo: Flo,
                    _ visit: Visitor) {

        let leftToRight = fromFlo == leftFlo // a >> b
        let rightToLeft = !leftToRight       // a << b
        let destFlo = leftToRight ? rightFlo : leftFlo


        if leftToRight && edgeOps.hasOutput ||
            rightToLeft && edgeOps.hasInput {

            let fromExprs = fromFlo.exprs
            assignNameExprs() // setup exExprs

            if  destFlo.setEdgeVal(edgeExprs, fromExprs, visit) {

                destFlo.activate(visit)

            } else {
                /// Did not meet conditionals, so stop.
                /// for example, when cc != 13 for
                /// `repeatX(cc == 13, val 0…127, chan, time)`

            }
            /// assign b(v) to a(x) in `a(x,y) b(v 0) >> a(x:v)`
            func assignNameExprs() {

                if let edgeExprs,
                   let fromExprs {

                    for (name,val) in edgeExprs.nameAny {
                        if (val as? String) == "",
                           let fromVal = fromExprs.nameAny[name] {
                            edgeExprs.nameAny[name] = fromVal
                        }
                    }
                }
            }
        }
        func logEdge() {

            var arrow = leftToRight ? " ⫸" : "⫷ "
            arrow += edgeOps.hasPlugin ? "⚡️ " : " "

            print ("\n(" +
                   "\(script(leftFlo))" + arrow +
                   " \(script(rightFlo))))"
                   , terminator: ") ")

            func script(_ flo: Flo) -> String {
                if let exprs = flo.exprs {
                    let plugged = !flo.plugins.isEmpty ? "⚡️" : ""
                    if let scalar = exprs.nameAny["val"] as? FloValScalar {
                        return plugged + "\(flo.path(9)).\(flo.id)\(plugged)[val: \(scalar.val.digits(0...2))/\(scalar.val.digits(0...2))]"
                    } else {

                        var str = "\(flo.path(9)).\(flo.id)\(plugged)["
                        var del = ""
                        for (name,any) in exprs.nameAny {
                            if let scalar = any as? FloValScalar {
                                str += del + name + ": \(scalar.val.digits(0...2))/\(scalar.twe.digits(0...2))"
                                del = ", "
                            }
                        }
                        str += "]"
                        return str
                    }
                }
                return "[]"
            }
        }
    }

}

