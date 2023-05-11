//
//  FloEdge+runtime.swift
//
//  Created by warren on 5/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar // visit

extension FloEdge {
    
    func followEdge(_ fromFlo: Flo,
                    _ visit: Visitor) {

        let leftToRight = fromFlo == leftFlo // a >> b
        let rightToLeft = !leftToRight       // a << b
        let destFlo = leftToRight ? rightFlo : leftFlo

        if edgeOps.animate {
            
            if (leftToRight && edgeOps.output ||
                rightToLeft && edgeOps.input) {
                
                let destPath = destFlo.parentPath(9)
                let fromPath = fromFlo.parentPath(9)
                let fromVal  = "(\(fromFlo.val?.scriptVal(.now) ?? "??"))"

                if leftToRight {
                    print("􁒖→\(fromPath)\(fromVal) => \(destPath)")
                } else {
                    print("􁒖←\(destPath) <= \(fromPath)\(fromVal)")
                }
                destFlo.setAnimation(fromFlo)
            }
        } else if edgeOps.ternIf {

            if leftToRight, let ternVal = rightFlo.findEdgeTern(self) {

                ternVal.recalc(leftFlo, rightFlo, .activate , visit)
                rightFlo.activate(visit)
                //print("\(fromFlo.name)◇→\(destFlo?.name ?? "")")

            } else if rightToLeft, let ternVal = leftFlo.findEdgeTern(self) {

                ternVal.recalc(rightFlo, leftFlo, .activate, visit)
                leftFlo.activate(visit)
                //print("\(fromFlo.name)◇→\(destFlo?.name ?? "")")
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

