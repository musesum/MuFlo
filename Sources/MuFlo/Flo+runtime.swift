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
                if exprs.setExprsVal(fromExprs, visit) == false {
                    // condition failed, so avoid activatating edges, below
                    return
                }
            }
        } else if let exprs {
            // any is not a FloVal, so pass onto my FloVal if it exists
            if exprs.setExprsVal(any, visit) == false {
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
                    floEdge.followEdge(self, visit.via(.model)) //... add via(.edge
                }
            }
        }
    }


    /// three examples:
    /// 1. `a(1), b(2) >> a(3)`     // b has an edge value (3)
    /// 2. `a(1), b(2) >> a`        // b has no edge value
    /// 3. `a(1) >> b, b >> c, c(4)`// b is a passthrough node
    /// activating `b!` for each example
    /// 1. `a(3), b(2) >> a(3)`     // `a(3)` is set from `b`'s `>> a(3)`
    /// 2. `a(2), b(2) >> a(3)`     // `a(2)` is set directly from
    /// 3. `a(1) >> b, b >> c(4)`   // nothing happens
    /// for example 3, activating a
    /// 3. `a(1) >> b, b >> c(1)`   // `a` passes through `b` to set `a`
    @discardableResult
    func setEdgeVal(_ edgeExprs: FloExprs?,     /// `(2)` in `b(0…1) >> a(2)`
                    _ fromExprs: FloExprs?,     /// `(0…1)` in `b(0…1) >> a`
                    _ visit: Visitor) -> Bool {

        if visit.wasHere(id) { return false }

        // example 3. passthrough
        if exprs == nil {
            // runtime setup as passthrough
            passthrough = true
        }
        if passthrough {
            if let edgeExprs {
                /// for `a >> b(1), b >> c
                /// `b` forwards`>>`'s `(1)` to `c`
                edgeExprs.evalExprs(fromExprs, true, visit)
                exprs = edgeExprs

            } else if let fromExprs {
                /// for `a(2) >> b, b >> c
                /// `b` forwards `a`'s `(2)` to `c`
                exprs = fromExprs
            }
            return true
        } else {
            guard let exprs else { return true }

            if let edgeExprs {
                /// example 1. first eval edge via from value
                edgeExprs.evalExprs(fromExprs, true, visit)
                /// and then pass the result as a new from value
                return exprs.setExprsVal(edgeExprs, visit)

            } else if let fromExprs {
                // example 2. pass the from value directly
                return exprs.setExprsVal(fromExprs, visit)
            }
        }
        return true
    }

}
