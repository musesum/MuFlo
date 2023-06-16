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

        if edgeOps.plugin,
           let leftExprs = leftFlo.exprs,
           let rightExprs = rightFlo.exprs {

            if leftExprs.plugin == nil {

                leftExprs.plugin = FloPlugin(leftExprs,rightExprs)
            }
        } else if leftToRight && edgeOps.output ||
                    rightToLeft && edgeOps.input {

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
    }

}

