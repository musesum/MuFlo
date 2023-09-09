//  ParNode+find.swift
//
//  Created by warren on 7/27/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public extension ParNode {

    /// return first of alternate choices (boolean or)
    func testOr(_ parStr: ParStr, level: Int) -> ParMatching {

        let matching = ParMatching()

        let snapshot = parStr.getSnapshot() // save start position

        for edgeNext in edgeNexts {

            parStr.putSnapshot(snapshot) // return to start position

            if let parItem = edgeNext.nodeNext?.findMatch(parStr, level).parLast {
                if parItem.hops == 0 {
                    return ParMatching(parItem, ok: true)
                }
                else {
                    matching.add(parItem)
                }
            }
        }
        return matching.bestCandidate()
    }

    /// Return a ParItem when all suffixes match (boolean and),
    /// otherwise, return nil to signify failure.
    ///
    /// A `.def` is not parsed; it defines a namespace.
    /// So, for the following example, b and c are parsed once once,
    /// since the `{` begins a `.def` of local statements.
    ///
    ///     a: b c { b:"bb", c:"cc" }
    ///
    func testAnd(_ parStr: ParStr, level: Int) -> ParMatching {

        let matching = ParMatching()

        for edgeNext in edgeNexts {

            if let nodeNext = edgeNext.nodeNext {
                // skip namespace
                if nodeNext.parOp == .def {
                    continue
                }
                if matching.add(nodeNext.findMatch(parStr, level)) {
                    continue
                }
            }
            return ParMatching(nil, ok: false)
        }
        matching.ok = true
        return matching.reduceFound(self)
    }

    /// return result, when parStr.sub matches external function, if it exists
    func testMatch(_ parStr: ParStr, level: Int) -> ParMatching {
        return parStr.matchMatchStr(self)
    }

    /// return empty parItem, when parStr.sub matches pattern
    func testQuo(_ parStr: ParStr, level: Int) -> ParMatching {
        return parStr.matchQuote(self)
    }

    /// return result, when parStr.sub matches regular expression in pattern
    func testRegx(_ parStr: ParStr, level: Int) -> ParMatching {
        return parStr.matchRegx(self)
    }

    /// Repeat closure based on repetion range range and closure's result
    ///
    ///     - ?: 0 ... 1
    ///     - *: 0 ..< ParEdge.repMax, stop when false
    ///     - +: 1 ..< ParEdge.repMax, stop when false
    ///     - { repMin ..< repMax }
    ///
    internal func forRepeat(_ parStr: ParStr,
                            _ level: Int,
                            _ parStrMatch: ParStrMatch) -> ParMatching {

        let matching = ParMatching()

        for _ in 0 ..< reps.repMax {
            // matched, so add
            if  matching.add(parStrMatch(parStr, level)) {
                matching.count += 1
                continue // to next repeat
            }
            break // unmatched, fail minimum, so false
        }
        matching.ok = (matching.count >= reps.repMin &&
            /**/       matching.count <= reps.repMax)

        return matching.reduceFound(self, isName)
    }

    /**
     Search for pattern matches in substring with by transversing graph of nodes, with behavior:

     - or - alternation find first match
     - and - all suffixes must match
     - match - external function
     - quo - quoted string
     - rgx - regular expression

     - Parameters:
        - parStr: sub(string) of input to match
        - level: depth within graph search
    */
    func findMatch(_ parStr: ParStr, _ level: Int=0) -> ParMatching {

        let snapshot = parStr.getSnapshot() // push
        var matching = ParMatching()

        parStr.trace(self, nil, level)

        switch parOp {
        case .def,
             .and:   matching = forRepeat(parStr, level, testAnd)
        case .or:    matching = forRepeat(parStr, level, testOr)
        case .quo:   matching = forRepeat(parStr, level, testQuo)
        case .rgx:   matching = forRepeat(parStr, level, testRegx)
        case .match: matching = forRepeat(parStr, level, testMatch)
        }

        if let parItem = matching.parLast {
            foundCall?(parItem)
            parStr.trace(self, parItem, level)
        } else {
            parStr.putSnapshot(snapshot) // pop
        }
        return matching
    }

    /// Path must match all node names, ignores and/or/cardinals
    /// - parameter parStr: space delimited sequence of
    func findPath(_ parStr: ParStr) -> ParNode? {

        var val: String?

        switch parOp {
        case .rgx: val = parStr.matchRegx(self).value
        case .quo: val = parStr.matchQuote(self, withEmpty: true).value
        default:   val = ""
        }

        if let _ = val {

            if parStr.isEmpty() {
                return self
            }
            for edgeNext in edgeNexts {
                if let parNode = edgeNext.nodeNext?.findPath(parStr) {
                    return parNode
                }
            }
            return self
        }
        return nil
    }

}
