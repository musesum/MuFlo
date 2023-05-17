//  FloValTern+runtime.swift
//
//  Created by warren on 4/11/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar // visit

extension FloValTern {

    func changeState(_ state:   FloTernState,
                     _ prevFlo: Flo,
                     _ nextFlo: Flo,
                     _ act:     FloAct,
                     _ visit: Visitor) {

        func setTernEdges(_ val: FloVal?, active: Bool) {

            if let valPath = val as? FloValPath {
                for pathFlo in  valPath.pathFlos  {
                    for pathEdge in pathFlo.floEdges.values {
                        if pathEdge.rightFlo == flo {
                            pathEdge.active = active
                        }
                    }
                }
            }
        }

        func forTernPathVal(_ val: FloVal?, callTern: @escaping CallTern) {

            if let pathFlos = (val as? FloValTern)?.pathFlos {
                for pathFlo in pathFlos {
                    if let tern = pathFlo.val as? FloValTern {
                        callTern(tern)
                    }
                }
            }
        }
        func recalcPathVal(_ val: FloVal?) {

            if  let tern = val as? FloValTern {
                tern.recalc(prevFlo, nextFlo, act, visit)
            } else if act != .sneak {
                flo.setEdgeVal(val, visit)
            }
        }
        func neitherPathVal(_ val: FloVal?) {
            forTernPathVal(val) { tern in
                tern.changeState(.noVal, prevFlo, nextFlo, act, visit)
            }
        }

        // ────────────── begin ──────────────

        ternState = state
        switch ternState {

        case .thenVal:
            // b1, b2, b3 in `x <- (a ? (b1 ? b2 : b3) : c)`
            setTernEdges(thenVal, active: true)
            setTernEdges(elseVal, active: false)
            recalcPathVal(thenVal)
            neitherPathVal(elseVal)

        case .elseVal:
            // c1, c2, c3 in `x <- (a ? b : (c1 ? c2 : c3))`
            setTernEdges(thenVal, active: false)
            setTernEdges(elseVal, active: true)
            neitherPathVal(thenVal)
            recalcPathVal(elseVal)

        case .noVal:

            setTernEdges(thenVal, active: false)
            setTernEdges(elseVal, active: false)
            neitherPathVal(thenVal)
            neitherPathVal(elseVal)
            recalcPathVal(thenVal)
            recalcPathVal(elseVal)

        default: break
        }
    }

    // follow radio linked list to beginnning and change state along the way
    func changeRadio(_ prevFlo: Flo,
                     _ nextFlo: Flo,
                     _ visit: Visitor) {

        for radioFlo in pathFlos {
            if let tern = radioFlo.val as? FloValTern {
                tern.changeState(.noVal, prevFlo, nextFlo, .sneak, visit)
            }
            if let thenPath = thenVal as? FloValPath {
                for thenFlo in thenPath.pathFlos {
                    for edge in thenFlo.floEdges.values {
                        if      edge.leftFlo == thenFlo, edge.rightFlo == nextFlo { edge.active = false }
                        else if edge.leftFlo == nextFlo, edge.rightFlo == thenFlo { edge.active = false }
                    }
                }
            }
            if let elsePath = elseVal as? FloValPath {
                for elseFlo in elsePath.pathFlos {
                    for edge in elseFlo.floEdges.values {
                        if      edge.leftFlo == elseFlo, edge.rightFlo == nextFlo { edge.active = false }
                        else if edge.leftFlo == nextFlo, edge.rightFlo == elseFlo { edge.active = false }
                    }
                }
            }
        }
    }
    // follow radio linked list to beginnning and change state along the way
    func changeRadioPrev(_ prevFlo: Flo,
                         _ nextFlo: Flo,
                         _ visit: Visitor) {

        changeRadio(prevFlo, nextFlo, visit)
        radioPrev?.changeRadioPrev(prevFlo, nextFlo, visit)
    }

    // follow radio linked list to beginnning and change state along the way
    func changeRadioNext(_ prevFlo: Flo,
                         _ nextFlo: Flo,
                         _ visit: Visitor) {

        changeRadio(prevFlo, nextFlo, visit)
        radioNext?.changeRadioNext(prevFlo, nextFlo, visit)
    }

    func recalc(_ prevFlo: Flo?,
                _ nextFlo: Flo?,
                _ act:     FloAct,
                _ visit: Visitor) {

        guard let prevFlo else { print("🚫 prevFlo = nil"); return }
        guard let nextFlo else { print("🚫 nextFlo = nil"); return }
        // a in `w <-(a ? x : y)`
        // a in `w <-(a == b ? x : y)`  when a == b
        if testCondition(prevFlo, act) {

            radioPrev?.changeRadioPrev(prevFlo, nextFlo, visit)
            radioNext?.changeRadioNext(prevFlo, nextFlo, visit)
            changeState(.thenVal, prevFlo, nextFlo, act, visit)
        }
            // during bindTerns, deactivate edges when there is no value or comparison
        else if act == .sneak {
            // deactive both Then, Else edges
            radioPrev?.changeRadioPrev(prevFlo, nextFlo, visit)
            radioNext?.changeRadioNext(prevFlo, nextFlo, visit)
            changeState(.noVal, prevFlo, nextFlo, act, visit) // a ?? b fails comparison
        }
            // when a != b in `w <-(a == b ? x : y)`
        else {
            changeState(.elseVal, prevFlo, nextFlo, act, visit) // a ?? b fails comparison
        }
    }

    /// set destination to source value
    func setFloVal(_ left:    Flo,
                   _ right:   Flo,
                   _ act:     FloAct,
                   _ visit: Visitor) {

        // DebugPrint("dst:%s src:%s \n&src.val:%p \n&event.val:%p\n\n", dst.name.c_str(), src.name.c_str(), src.val, event.val)

        var isOk = true // test if setVal conditionals passed
        if left.passthrough {
            left.val = right.val
        }
        else {
            
            isOk = left.val?.setVal(right.val!, visit, [.now,.next]) != nil
        }
        if act == .activate, isOk {
            left.activate(visit)
        }
    }

}
