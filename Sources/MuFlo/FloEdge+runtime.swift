//
//  FloEdge+runtime.swift
//
//  Created by warren on 5/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar // visitor

extension FloEdge {
    
    func followEdge(_ fromFlo: Flo,
                    _ visitor: Visitor) {

        let leftToRight = fromFlo == leftFlo // a >> b
        let rightToLeft = !leftToRight       // a << b
        let destFlo = leftToRight ? rightFlo : leftFlo

        if edgeFlags.animate {

            if  (leftToRight && edgeFlags.output ||
                 rightToLeft && edgeFlags.input) {

                let destPath = destFlo.parentPath(9)
                let fromPath = fromFlo.parentPath(9)
                let fromVal  = "(\(fromFlo.val?.scriptVal(.now) ?? "??"))"

                if leftToRight {
                    print("􁒖\(fromPath)\(fromVal) ~> \(destPath)")
                } else {
                    print("􁒖\(destPath) <~ \(fromPath)\(fromVal)")
                }
                destFlo.setAnimation(fromFlo)
            }
        } else if edgeFlags.ternIf {

            if leftToRight, let ternVal = rightFlo.findEdgeTern(self) {

                ternVal.recalc(leftFlo, rightFlo, .activate , visitor)
                rightFlo.activate(visitor)
                //print("\(fromFlo.name)◇→\(destFlo?.name ?? "")")
            }
            else if rightToLeft, let ternVal = leftFlo.findEdgeTern(self) {

                ternVal.recalc(rightFlo, leftFlo, .activate, visitor)
                leftFlo.activate(visitor)
                //print("\(fromFlo.name)◇→\(destFlo?.name ?? "")")
            }
        }
        else {

            if  leftToRight && edgeFlags.output ||
                rightToLeft && edgeFlags.input {

                let val = assignNameVals()
                if  destFlo.setEdgeVal(val, visitor) {
                    destFlo.activate(visitor)
                } else {
                    /// Did not meet conditionals, so stop.
                    /// for example, when cc != 13 for
                    /// `repeatX(cc == 13, val 0…127, chan, time)`
                }
            }
        }

        /// apply fromFlo values to edge expressions
        /// such as applyihg `b(v 1)` to `a(x:v),`
        /// for `a(x,y), b(v 0) >> a(x:v)`
        func assignNameVals() -> FloVal? {

            if let defVal {

                if let defExprs = defVal as? FloExprs,
                   let frExprs = fromFlo.val as? FloExprs {

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

