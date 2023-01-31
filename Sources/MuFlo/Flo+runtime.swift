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

        /// clean up scaffolding from parsing a Ternary,
        /// todo: scaffolding instead of overloading val
        if val is FloValPath {
            val = nil
        }
        // any is a FloVal
        if let fromVal = any as? FloVal {

            if passthrough {
                // no defined value, so activate will pass fromVal onto edge successors
                val = fromVal
            } else if let val {
                // set my val to fromVal, with rescaling
                if val.setVal(fromVal, visit) == false {
                    // condition failed, so avoid activatating edges, below
                    return
                }
            }
        } else if let val {
            // any is not a FloVal, so pass onto my FloVal if it exists
            if val.setVal(any, visit) == false {
                // condition failed, so avoid activatating edges, below
                return
            }
        } else {
            // I don't have a FloVal yet, so maybe create one for me
            passthrough = false

            switch any {
                case let v as Int:     val = FloValScalar(self, name: name, num: Double(v))
                case let v as Double:  val = FloValScalar(self, name: name, num: v)
                case let v as CGFloat: val = FloValScalar(self, name: name, num: Double(v))
                case let v as CGPoint: val = FloValExprs(self, point: v)
                case let v as [(String, Double)]: val = FloValExprs(self, nameNums: v)
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

    func findEdgeTern(_ edge: FloEdge) -> FloValTern? {
        for edgeDef in edgeDefs.edgeDefs {
            if edgeDef.edges.keys.contains(edge.edgeKey) {
                return edgeDef.ternVal
            }
        }
        return nil
    }

    /// Some nodes have no value of its own, acting as a switch
    /// to merely point to the the value, as it moves through.
    /// If the node has a value of its own, then remap
    /// its value and the range of the incoming value.
    ///
    func setEdgeVal(_ fromVal: FloVal?,
                    _ visit: Visitor) -> Bool {
        
        if visit.wasHere(id) { return false }
        guard let fromVal else { return true }

        if val == nil {
            passthrough = true  // no defined value so pass though
        }
        if passthrough {
            val = fromVal // hold passthrough value, for successors to rescale
        }
        else if let val {
            switch val {

                case let v as FloValExprs:

                    if let fr = fromVal as? FloValExprs {
                        return v.setVal(fr, visit)
                    }
                case let v as FloValScalar:

                    if let fr = fromVal as? FloValScalar {
                        return v.setVal(fr, visit)
                    }
                    else if let frExprs = fromVal as? FloValExprs,
                            let lastExpr = frExprs.nameAny.values.first,
                            let fr = lastExpr as? FloValScalar {

                        return v.setVal(fr, visit)
                    }
                case let v as FloValData:
                    
                    if let fr = fromVal as? FloValData {
                        return v.setVal(fr, visit)
                    }
                default: break
            }
        }
        return true
    }
}
