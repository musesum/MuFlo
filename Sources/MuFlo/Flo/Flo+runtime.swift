//  created by musesum on 4/4/19.

import QuartzCore

extension Flo {

    public func setNameNums(_ nameNums: [(String,Double)],
                            _ setOps: SetOps,
                            _ visit: Visitor = Visitor(0)) {
        if let exprs {

            guard exprs.setFromExprs(Exprs(self, nameNums), setOps, visit) else { return }

        } else {
            // I don't have a FloVal yet, so maybe create one for me
            passthrough = false
            exprs = Exprs(self, nameNums)
        }
        // maybe pass along my FloVal to other FloNodes and closures
        if setOps.fire {
            activate(setOps, visit)
        }
    }
    public func setFromExprs(_ fromExprs: Exprs,
                             _ setOps: SetOps,
                             _ visit: Visitor = Visitor(0)) {
        if passthrough {
            exprs = fromExprs
        } else if let exprs {
            // set my val to fromVal, with rescaling
            guard exprs.setFromExprs(fromExprs, setOps, visit) else  {  return }
        } else {
            exprs = fromExprs
        }

        // maybe pass along my FloVal to other FloNodes and closures
        if setOps.fire {
            activate(setOps, visit)
        }
    }
    public func setVal(_ double: Double,
                       _ setOps: SetOps,
                       _ visit: Visitor = Visitor(0)) {
        if let exprs {
            // any is not a FloVal, so pass onto my FloVal if it exists
            exprs.setNum(double, setOps)

        } else {
            // I don't have a FloVal yet, so maybe create one for me
            passthrough = false
            exprs = Exprs(self, [(name, double)])
        }
        // maybe pass along my FloVal to other FloNodes and closures
        if setOps.fire {
            activate(setOps, visit)
        }
    }

    public func activate(_ setOps: SetOps, from: Flo?) {
        if let from {
            let visit = Visitor(from: from)
            activateEdges(setOps, visit, 0)
        }
    }
    
    public func activate(_ setOps: SetOps, _ visit: Visitor = Visitor(0), _ depth: Int = 0) {
        guard visit.newVisit(id) else { return }
        for closure in closures {
            closure(self, visit)
        }
         activateEdges(setOps, visit, depth)
    }
    private func activateEdges(_ setOps: SetOps, _ visit: Visitor, _ depth: Int) {
        // breadth first follow edges
        var passed = [Flo]()
        for floEdge in floEdges.values {
            if floEdge.active { // ⬦⃣
                if let pass = floEdge.followEdge(self, setOps, visit.via(.model), depth) {
                    passed.append(pass)
                }
            }
        }
        // continue next breadth level with nodes that passed
        for pass in passed {
            pass.activate(setOps, visit, depth+1)
        }
    }

    /// three examples:
    ///  1. `a(1), b(2,-> a(3))`        // b passes an edge value (3) to a
    ///  2. `a(1), b(2,-> a)`           // b passes its value to a
    ///  3. `a(1,-> b), b(-> c), c(4)`  // b is a passthrough node
    /// activating `b!` for 1,2,3
    ///  1a. `a(3), b(2,-> a(3))`       // `a(3)` is set from `b`'s `-> a(3)`
    ///  2a. `a(2), b(2,-> a)`          // `a(2)` is set directly from b
    ///  3a. `a(1,-> b), b(-> c), c(4)` // nothing happens
    /// for example 3, activating a
    ///  3. `a(1,-> b), b(-> c), c(1)`  // `a` passes through `b` to set `a`
    ///
    func setEdgeVal(_ edgeExprs : Exprs?,
                    _ fromFlo   : Flo,
                    _ setOps    : SetOps,
                    _ visit     : Visitor) -> Bool {

        if visit.wasHere(id) { return false }

        let fromExprs = fromFlo.exprs

        if let exprs, !exprs.nameAny.isEmpty {
            var passed = false
            if let edgeExprs {
                ///example 1.` b!` for `a(1), b(2, -> a(3))`
                /// first eval `b -> a` edge
                edgeExprs.evalExprs(fromExprs, true, setOps)
                /// and then pass `(3)` to `a`
                passed = exprs.setFromExprs(edgeExprs, setOps, visit)

            } else if let fromExprs {
                /// example 2. `b!` for `a(1), b(2, -> a)`
                passed = exprs.setFromExprs(fromExprs, setOps, visit)
            }
            return passed

        } else if let tex = fromFlo.texture {

            self.texture = tex

        } else if let buf = fromFlo.buffer {

            self.buffer = buf

        } else { /// example 3.  passthrough
            passthrough = true // does not contain own value
            exprs = edgeExprs ?? fromExprs
        }
        return true
    }

}
