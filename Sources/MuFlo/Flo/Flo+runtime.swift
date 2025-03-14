//  created by musesum on 4/4/19.

import QuartzCore

extension Flo {

    public func setDoubles(_ nameDoubles: [(String,Double)]) {
        guard let exprs else { return err("exprs == nil")}
        let nameAny = exprs.nameAny

        for (name,double) in nameDoubles {
            guard let val = nameAny[name] else {
                return err("\(name) not found") }
            if let scalar = val as? Scalar {
                scalar.tween = double
                scalar.value = double
            } else {
                nameAny[name] = Scalar(self,name,double)
            }
        }
        func err(_ msg: String) {
            //PrintLog("⁉️ Flo::setDoubles \(path()) \(msg)")
        }
    }

    //TODO: only used by NodeVm:: var spotlight: Bool {...}
    public func setVal(_ name: String,
                       _ value: Double,
                       _ options: SetOptions,
                       _ visit: Visitor = Visitor(0)) {
        if let exprs,
           let scalar = exprs.nameAny[name] as? Scalar {

            if scalar.value != value {

                scalar.value = value
                if options.sneak { return }
                if options.changed { activate(visit) }
            } else if options.fire {
                activate(visit)
            }
        }
    }

    public func setAnyExprs(_ any: Any,
                            _ options: SetOptions,
                            _ visit: Visitor = Visitor(0)) {
        // any is a Expression
        if let fromExprs = any as? Exprs {

            if passthrough {
                // no defined value, so activate will pass fromVal onto edge successors
                exprs = fromExprs
            } else if let exprs {
                // set my val to fromVal, with rescaling
                if exprs.setFromAny(fromExprs, visit) == false {
                    // condition failed, so avoid activatating edges, below
                    return
                }
            }
        } else if let exprs {
            // any is not a FloVal, so pass onto my FloVal if it exists
            if exprs.setFromAny(any, visit) == false {
                // condition failed, so avoid activatating edges, below
                return
            }
        } else {
            // I don't have a FloVal yet, so maybe create one for me
            passthrough = false
            exprs = makeAnyExprs(any)
        }
        // maybe pass along my FloVal to other FloNodes and closures
        if options.fire {
            activate(visit)
        }
    }

    public func activate(from: Flo?) {
        if let from {
            let visitor = Visitor(from: from)
            activateEdges(visitor,0)
        }
    }
    
    public func activate(_ visitor: Visitor = Visitor(0), _ depth: Int = 0) {
        // logDepth(visit.isBlocked(id) ? "⛔️" : visit.wasHere(id) ? "🏁" : "🚥")
        guard visitor.newVisit(id) else { return }
        for closure in closures {
            closure(self, visitor)
        }
         activateEdges(visitor, depth)
    }
    private func activateEdges(_ visitor: Visitor, _ depth: Int) {
        // breadth first follow edges
        var passed = [Flo]()
        for floEdge in floEdges.values {
            if floEdge.active { // ⬦⃣
                if let pass = floEdge.followEdge(self, visitor.via(.model), depth) {
                    passed.append(pass)
                }
            }
        }
        // continue next breadth level with nodes that passed
        for pass in passed {
            pass.activate(visitor, depth+1)
        }
        func logDepth(_ icon: String) {
            #if DEBUG && false
            let visited = exprs?.logVisitedPaths(visit) ?? ""
            print("".pad(depth*3) + "\(id)" + "\(icon) \(path(3)): \(float) " + visited)
            #endif
        }
    }

    /// three examples:
    /// 1. `a(1), b(2) >> a(3)`     // b passes an edge value (3) to a
    /// 2. `a(1), b(2) >> a`        // b passes its value to a
    /// 3. `a(1) >> b, b >> c, c(4)`// b is a passthrough node
    /// activating `b!` for each example
    /// 1a. `a(3), b(2) >> a(3)`     // `a(3)` is set from `b`'s `>> a(3)`
    /// 2a. `a(2), b(2) >> a(3)`     // `a(2)` is set directly from b
    /// 3a. `a(1) >> b, b >> c(4)`   // nothing happens
    /// for example 3, activating a
    /// 3. `a(1) >> b, b >> c(1)`   // `a` passes through `b` to set `a`
    @discardableResult
    func setEdgeVal(_ edgeExprs: Exprs?, /// `(2)` in `b(0…1) >> a(2)`
                    _ fromFlo: Flo,         /// `(0…1)` in `b(0…1) >> a`
                    _ visit: Visitor) -> Bool { 

        if visit.wasHere(id) { return false }

        let fromExprs = fromFlo.exprs

        if let exprs, !exprs.nameAny.isEmpty {
            var passed = false
            if let edgeExprs {
                ///example 1.` b!` for `a(1), b(2, -> a(3))`
                /// first eval `b -> a` edge
                edgeExprs.evalExprs(fromExprs, true, visit)
                /// and then pass `(3)` to `a`
                passed = exprs.setFromAny(edgeExprs, visit)

            } else if let fromExprs {
                /// example 2. `b!` for `a(1), b(2, -> a)`
                passed = exprs.setFromAny(fromExprs, visit)
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
