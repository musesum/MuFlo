//  ParItem+reduce.swift
//
//  Created by warren on 3/18/19.
//  License: Apache 2.0 - see License file

import Foundation

extension ParItem {

    /// when ParItem has a single leaf node with a value,
    /// then promote the leaf value

    public func promoteSingleLeaf() {

        if  value == nil,
            nextPars.count == 1,
            let nextVal = nextPars.first?.value  {

            value = nextVal
            nextPars = []
        }
    }

    /// reduce strand ParItem to only those that match keywords
    public func reduce(_ keywords: [String: Any]) -> [ParItem] {
        
        if value != nil { return [self] }

        var reduction = [ParItem]()

        if isEmptyRgx() {
            return reduction
        }
        for nexti in nextPars {
            let reduced = nexti.reduce(keywords)
            reduction.append(contentsOf: reduced)
        }
        // self's node is a keyword, so keep it
        if let pattern = node?.pattern,
           keywords[pattern] != nil {
            nextPars = reduction
            return [self]
        }
        return reduction

        /// regular expression
        func isRgx(_ node: ParNode) -> Bool {
            if node.parOp == .rgx { return true }
            if node.edgeNexts.count == 1,
               let first = node.edgeNexts.first,
               let nodeNext = first.nodeNext {
                return isRgx(nodeNext)
            }
            return false
        }
        func isEmptyRgx() -> Bool {
            if nextPars.count == 0,
               node?.reps.repMin == 0 {

                if nextPars.first?.value == nil,
                   let node = node,
                   isRgx(node) {
                    return true
                }
            }
            return false
        }
    }

    public func reduceStart(_ keywords: [String: Any]) -> ParItem {

        let reduction = reduce(keywords)
        if reduction.count == 1 {
            return reduction[0]
        }
        return ParItem(ParNode("child"), reduction)
    }
    
}
