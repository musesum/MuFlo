//  Flo+runtime.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import MuPar // visit

extension Flo {

    /// combine several expressions into one transaction and activate the callbacks only once
    public func setNameVals(_ nameAnys: [(String,Double)],
                            _ setOps: FloSetOps,
                            _ visit: Visitor) {

        // defer activation until after setting value
        let noActivate = setOps.subtracting(.activate)
        setAny(nameAnys, noActivate, visit)

        // do the deferred activations, if there was one
        if setOps.activate {
            activate(visit)
        }
    }
    public func setAny(_ any: Any,
                       _ options: FloSetOps,
                       _ visit: Visitor = Visitor(0)) {

        // any is a FloVal
        if let fromExprs = any as? FloExprs {

            if passthrough {
                // no defined value, so activate will pass fromVal onto edge successors
                exprs = fromExprs
            } else if let exprs {
                // set my val to fromVal, with rescaling
                if exprs.setVal(fromExprs, visit, [.now_, .val]) == false {
                    // condition failed, so avoid activatating edges, below
                    return
                }
            }
        } else if let exprs {
            // any is not a FloVal, so pass onto my FloVal if it exists
            if exprs.setVal(any, visit, [.now_, .val]) == false {
                // condition failed, so avoid activatating edges, below
                return
            }
        } else {
            // I don't have a FloVal yet, so maybe create one for me
            passthrough = false

            switch any {
            case let v as Int:     exprs = FloExprs(self, [(name, Double(v))])
            case let v as Double:  exprs = FloExprs(self, [(name, v)])
            case let v as CGFloat: exprs = FloExprs(self, [(name, Double(v))])
            case let v as CGPoint: exprs = FloExprs(self, point: v)
            case let v as [(String, Double)]: exprs = FloExprs(self, v)
            default: print("🚫 unknown val(\(any))")
            }
        }
        // maybe pass along my FloVal to other FloNodes and closures
        if options.activate {
            activate(visit)
        }
    }

    public func activate(_ visit: Visitor) {

        if visit.newVisit(id) {
            for closure in closures {
                closure(self, visit)
            }
            for floEdge in floEdges.values {
                
                if floEdge.active {
                    floEdge.followEdge(self, visit.via(.model))
                }
            }
        }
    }

    @discardableResult
    func setEdgeVal(_ fromExprs: FloExprs?,
                    _ viaEdge: Bool, 
                    _ visit: Visitor) -> Bool {

        if visit.wasHere(id) { return false }
        guard let fromExprs else { return true }
        guard let exprs else {
            passthrough = true  // no defined value so pass though
            exprs = fromExprs       // spoof my val as fromVal
            return true
        }
        // first evaluate source expression values
        fromExprs.evalFromExprs(viaEdge, visit)
        return exprs.setVal(fromExprs, visit, [.val])
    }

}
