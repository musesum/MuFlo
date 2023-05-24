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
           let leftExprs = leftFlo.val as? FloValExprs,
           let rightExprs = rightFlo.val as? FloValExprs {
            if leftExprs.plugin == nil {
                leftExprs.plugin = FloPlugin(leftExprs,rightExprs)
            }
        } else if  leftToRight && edgeOps.output ||
                    rightToLeft && edgeOps.input {

            let val = assignNameVals()

            if  destFlo.setEdgeVal(val, visit) {
                destFlo.activate(visit)

            } else {
                /// Did not meet conditionals, so stop.
                /// for example, when cc != 13 for
                /// `repeatX(cc == 13, val 0…127, chan, time)`
            }
        }

        /// apply fromFlo values to edge expressions
        /// such as applyihg `b(v 1)` to `a(x:v),`
        /// for `a(x,y), b(v 0) >> a(x:v)`
        func assignNameVals() -> FloVal? {

            if let defVal {

                if let defExprs = defVal as? FloValExprs,
                   let frExprs = fromFlo.val as? FloValExprs {

                    for (name,val) in defExprs.nameAny {
                        if (val as? String) == "" {
                            if let frVal = frExprs.nameAny[name] {
                                defExprs.nameAny[name] = frVal
                            }
                        }
                    }
                }
                return defVal
            }
            return fromFlo.val
        }
    }
}

