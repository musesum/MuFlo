//  Flo+runtime.swift
//
//  Created by warren on 4/4/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore

extension Flo {

    public func setAny(_ any: Any,
                       _ options: FloSetOps,
                       _ visit: Visitor = Visitor(0)) {

        // any is a FloExprs
        if let fromExprs = any as? FloExprs {

            if passthrough {
                // no defined value, so activate will pass fromVal onto edge successors
                exprs = fromExprs
            } else if let exprs {
                // set my val to fromVal, with rescaling
                if exprs.setFromAny(fromExprs, visit) == false { // 🔷
                    // condition failed, so avoid activatating edges, below
                    return
                }
            }
        } else if let exprs {
            // any is not a FloVal, so pass onto my FloVal if it exists
            if exprs.setFromAny(any, visit) == false { // 🔷
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
            default: print("⁉️ unknown val(\(any))")
            }
        }
        // maybe pass along my FloVal to other FloNodes and closures
        if options.activate {
            activate(visit) // 🚦
        }
    }

    public func activate(_ visit: Visitor, _ depth: Int = 0) { // 🚦

        // logDepth(visit.isBlocked(id) ? "⛔️" : visit.wasHere(id) ? "🏁" : "🚥")
        guard visit.newVisit(id) else { return }

        for closure in closures {
            closure(self, visit)
        }
        // breadth first follow edges
        var passed = [Flo]()
        for floEdge in floEdges.values {
            if floEdge.active { // ⬦⃣
                if let pass = floEdge.followEdge(self, visit.via(.model), depth) {
                    passed.append(pass)
                }
            }
        }
        // continue next breadth level with nodes that passed
        for pass in passed {
            pass.activate(visit, depth+1)
        }

        func logDepth(_ icon: String) {
            #if DEBUG && false
            let visited = exprs?.logVisitedPaths(visit) ?? ""
            print("".pad(depth*3) + "\(id)" + "\(icon) \(path(3)): \(float) " + visited)
            #endif
        }
    }


    /// three examples:
    /// 1. `a(1), b(2) >> a(3)`     // b has an edge value (3)
    /// 2. `a(1), b(2) >> a`        // b has no edge value
    /// 3. `a(1) >> b, b >> c, c(4)`// b is a passthrough node
    /// activating `b!` for each example
    /// 1a. `a(3), b(2) >> a(3)`     // `a(3)` is set from `b`'s `>> a(3)`
    /// 2a. `a(2), b(2) >> a(3)`     // `a(2)` is set directly from
    /// 3a. `a(1) >> b, b >> c(4)`   // nothing happens
    /// for example 3, activating a
    /// 3. `a(1) >> b, b >> c(1)`   // `a` passes through `b` to set `a`
    @discardableResult
    func setEdgeVal(_ edgeExprs: FloExprs?,     /// `(2)` in `b(0…1) >> a(2)`
                    _ fromExprs: FloExprs?,     /// `(0…1)` in `b(0…1) >> a`
                    _ visit: Visitor) -> Bool { // ⬦⃣

        if visit.wasHere(id) { return false }

        if let exprs {
            var passed = false
            if let edgeExprs {
                ///example 1.` b!` for `a(1), b(2) >> a(3)`
                /// first eval `b >> a` edge
                edgeExprs.evalExprs(fromExprs, true, visit) // 🔸
                /// and then pass `(3)` to `a`
                passed = exprs.setFromAny(edgeExprs, visit) // 🔷

            } else if let fromExprs {
                /// example 2. `b!` for `a(1), b(2) >> a`
                passed = exprs.setFromAny(fromExprs, visit) // 🔷
            }
            return passed
        } else { /// example 3.  passthrough
            passthrough = true // does not contain own value
            exprs = edgeExprs ?? fromExprs
        }
        return true
    }

}
