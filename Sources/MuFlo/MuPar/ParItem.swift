//  ParItem.swift
//
//  Created by warren on 7/13/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/// A ParNode pattern plus instance of Any, which may be either a String or [ParItem]
public class ParItem {

    public var node: ParNode?   // reference to parse node
    public var value: String?    // either value or next, not both to support
    public var nextPars = [ParItem]() // either a String, ParItem, or [ParItem]

    public var hops = 0
    var time = TimeInterval(0)
    
    init (_ node: ParNode,
          _ value: String?,
          _ hops: Int = 0,
          _ time: TimeInterval = 0) {

        self.node = node
        self.value = value
        self.hops = hops
        self.time = time
    }

    init (_ node: ParNode,
          _ next: [ParItem],
          _ hops: Int = 0,
          _ time: TimeInterval = 0) {

        self.node = node
        self.nextPars = next
        self.hops = hops
        self.time = time
    }

   /// Search a strand of nodeAnys for the last node
    func lastNode() -> ParItem? {
        for reversePar in nextPars.reversed() {
            if reversePar.value != nil ||
                reversePar.nextPars.count > 0 {
                return reversePar.lastNode()
            }
        }
        return self
    }

    public func makeScript(flat: Bool = false) -> String {
        
        var ret = ""

        if !flat, let node = node {

            switch node.parOp {
            case .rgx,.quo: break
            default:
                if node.pattern.count > 0  {
                    ret += node.pattern + ":"
                }
            }
        }

        switch nextPars.count {
        case 0: ret += (value ?? "")
        case 1: ret += nextPars[0].makeScript(flat: flat)
        default:
            var del = "("
            for nextPar in nextPars {
                ret += del + nextPar.makeScript(flat: flat)
                del = ", "
            }
            ret += ")"
        }
        return ret
    }

    static func printScript(_ any: Any?) {

        switch any {

        case let parItem as ParItem:

            print(parItem.makeScript(), terminator: " ")

        case let anys as [Any]:

            for any in anys {
                printScript(any)
            }
        default: print("⁉️ printScript unknown any")
        }
    }

    public func getFirstDouble() -> Double {
        if let value = nextPars.first?.value {

            return Double(value) ?? Double.nan
        }
        if let value = nextPars.first?.nextPars.first?.value  {

            return Double(value) ?? Double.nan
        }
        return Double.nan
    }

    public func getFirstFloat() -> Float {
        if let value = nextPars.first?.value {

            return Float(value) ?? Float.nan
        }
        if let value = nextPars.first?.nextPars.first?.value  {

            return Float(value) ?? Float.nan
        }
        return Float.nan
    }

    public func getFirstValue() -> String? {
        return nextPars.first?.value
    }

    /// Convenience for collecting a tuple of multiple values.
    /// - note: Used by FloGraph.
    public func harvestValues(_ keys: [String]) -> [String] {
        var result = [String]()
        for nextPar in nextPars {
            if let value = nextPar.value {

                result.append(value)

            } else if let pattern = nextPar.node?.pattern,
                keys.contains(pattern) {

                for nextPari in nextPar.nextPars {

                    if let value = nextPari.value {
                        result.append(value)
                    }
                }
            }
        }
        return result
    }

}
