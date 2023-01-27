//  FloTernIf.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

extension FloValTern {

    func testCondition(_ prevFlo: Flo,
                       _ act: FloAct) -> Bool {

        // a in `a b w <- (a ? 1: b ? 2)`
        if compareOp == "" {
            
            if let pathFlo = pathFlos.last {

                if let scalarVal = pathFlo.val as? FloValScalar {
                    return scalarVal.now > 0
                }
                if act == .sneak { return false }
                return pathFlo.id == prevFlo.id
            }
        }
        else if pathFlos.count > 0,
            let rightVal = compareRight?.flo.val {

            for pathFlo in pathFlos {
                if let pathVal = pathFlo.val {
                    if bothMatchFlags(pathVal, rightVal, [.now])  {

                        switch compareOp {
                        case "==": return pathVal == rightVal
                        case ">=": return pathVal >= rightVal
                        case ">" : return pathVal >  rightVal
                        case "<=": return pathVal <= rightVal
                        case "<" : return pathVal <  rightVal
                        case "!=": return pathVal != rightVal
                        default: break
                        }
                    }
                }
            }
        }
        return false

        // check if both match and are scalars or quotes
        func bothMatchFlags(_ left: FloVal,
                            _ right: FloVal,
                            _ matchFlags: [FloValFlags]) -> Bool {
            
            for matchFlag in matchFlags {
                if  left.valFlags.contains(matchFlag),
                    right.valFlags.contains(matchFlag) {
                    return true
                }
            }
            return false
        }

    }

}
