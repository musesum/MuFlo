//  ParWords.swift
//
//  Created by warren on 7/28/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/// Parse a sequential set of words
public class ParWords: ParStr {

    var parRecents = ParRecents()
    var words = [Substring]()
    var found = [Int]() // index of found
    var starti = 0 // where to start searching
    var count = 0
    var time = TimeInterval(0)

    public convenience init(_ str: String) {
        self.init()
        update(str)
    }

    public func update(_ str: String, _ time: TimeInterval = Date().timeIntervalSince1970) {
        
        self.str = str
        self.time = time
        restart() // set sub from str
        starti = 0
        count = 0
        words = sub.split(separator: " ")
        found = [Int](repeating: -1, count: words.count)
        parRecents.forget(time)
    }

    /// Substring of current ParWords state. To all parser to push and pop state.
    struct ParSnapshot {
        var sub: Substring
        var count: Int
        var starti: Int
        var foundi: Int
        init(_ ps: ParWords) {
            sub = ps.sub
            count = ps.count
            starti = ps.starti
            foundi = ps.found.count
        }
    }

    override func getSnapshot() -> Any {
        return ParSnapshot(self)
    }

    override func putSnapshot(_ any: Any?) {
        if let snapshot = any as? ParSnapshot {
            sub = snapshot.sub
            count = snapshot.count
            starti = snapshot.starti
            let trim = found.count - snapshot.foundi
            if trim > 0 {
                found.removeLast(trim)
            }
        }
    }

    override func isEmpty() -> Bool {
        return sub.isEmpty
    }

    /// Advance past match and return parItem with number of hops from normal sequence.
    /// - note: extension of ParStr, for a set of words match in parallel. Only use on a short phrase.
    func advancePar(_ node: ParNode, _ index: Int, _ str: String, _ deltaTime: TimeInterval = 0) -> ParItem? {

        /// matching a recent query is treated as a last resort, which is insured by adding cuttoff time for short term memory
        let penaltyHops = deltaTime > 0 ? Int(deltaTime + ParRecents.shortTermMemory) : 0

        // add from recent or has extra matches, so extend found
        if deltaTime > 0 || count >= found.count {
            found.append(index)
        }
            // could be sequence, which may mean that successor is a -1
        else {
            found[count] = index
        }

        var hops = abs(index-count) // sequence distance
        if index > 0 && found[index-1] > -1 {
            let previ = found[index-1]
            let expected = previ + 1
            hops = min(hops, abs(expected - index))
        }
        if index < found.count-1  && found[index+1] > -1 {
            let nexti = found[index+1]
            let expected = nexti - 1
            hops = min(hops, abs(expected - index))
        }
        count += 1
        starti = (index+1) % words.count

        let parItem = ParItem(node, str, hops + penaltyHops, Date().timeIntervalSince1970)
        parRecents.add(parItem)
        return parItem
    }


    /// match a quoted string and advance past match
    /// - note: extension of ParStr, for a set of words match in parallel. Only use on a short phrase.
    override func matchMatchStr(_ node: ParNode) -> ParMatching {

        func match(_ i: Int) -> String? {
            let word = words[i]
            return node.matchStr?(word)
        }

        // search forward from last match
        if starti < words.count {
            for index in starti ..< words.count {
                if let str = match(index) {
                    let parItem = advancePar(node, index, str)
                    return ParMatching(parItem, ok: true)
                }
            }
        }

        // continue search from leftovers
        if starti > 0 {
            for index in (0 ..< starti).reversed() {
                if let str = match(index) {
                    let parItem = advancePar(node, index, str)
                    return ParMatching(parItem, ok: true)
                }
            }
        }
        // test unclaimed keywords in short term memory
        if parRecents.parItems.count > 0,
          node.reps.repMin >= 1 {

            for parItem in parRecents.parItems.reversed() {
                if  let id = parItem.node?.id, id == node.id,
                    let word = parItem.value {

                    let deltaTime = time - parItem.time
                    let parItem = advancePar(node, words.count, word, deltaTime)
                    return ParMatching(parItem, ok: true)
                }
            }
        }
        return ParMatching(nil, ok: false)
    }


    /// match a quoted string and advance past match
    /// - note: extension of ParStr, for a set of words match in parallel. Only use on a short phrase.
    override func matchQuote(_ node: ParNode, withEmpty: Bool = false) -> ParMatching {

        func match(_ i: Int) -> Bool {
            let word = words[i]
            if word == node.pattern {
                found[i] = abs(starti-i)
                return true
            } else {
                return false
            }
        }

        // for an empty value, maybe return true
        if node.pattern == "" {

            if withEmpty { return ParMatching(ParItem(node,""), ok: true) }
            else         { return ParMatching(nil, ok: false) }
        }
        // search forward from last match
        if starti < words.count {
            for index in starti ..< words.count {
                if match(index) {
                    let parItem = advancePar(node, index, node.pattern)
                    return ParMatching(parItem, ok: true)
                }
            }
        }

        // continue search from leftovers
        if starti > 0 {
            for  index in (0 ..< starti).reversed()  {
                if match(index) {
                    let parItem = advancePar(node, index, node.pattern)
                    return ParMatching(parItem, ok: true)
                }
            }
        }

        // test unclaimed keywords in short term memory
        if parRecents.parItems.count > 0,
           node.reps.repMin >= 1 {

            for parItem in parRecents.parItems.reversed() {
                if  let id = parItem.node?.id, id == node.id {

                    let deltaTime = time - parItem.time
                    let parItem = advancePar(node, words.count, node.pattern, deltaTime)
                    return ParMatching(parItem, ok: true)
                }
            }
        }
        return ParMatching(nil, ok: false)
    }

    /// Match regular expression to beginning of substring
    /// - parameter regx: compiled regular expression
    /// - returns: ranges of inner value and outer match, or nil
    func matchRegxWord(_ regx: NSRegularExpression, _ word: Substring) -> RangeRegx? {

        let nsRange = NSRange( word.startIndex ..< word.endIndex, in: str)
        let match = regx.matches(in: str, options: [], range: nsRange)
        if match.count == 0 { return nil }
        switch match[0].numberOfRanges {
        case 1:  return RangeRegx(match[0].range(at: 0), match[0].range(at: 0), str)
        default: return RangeRegx(match[0].range(at: 1), match[0].range(at: 0), str)
        }
    }

    /// Match regular expression to word
    /// - parameter regx: compiled regular expression
    /// - returns: ranges of inner value and outer match, or nil
    func matchRegxWord(_ regx: NSRegularExpression, _ word: String) -> RangeRegx? {

        let nsRange = NSRange( word.startIndex ..< word.endIndex, in: word)
        let match = regx.matches(in: word, options: [], range: nsRange)
        if match.count == 0 { return nil }
        switch match[0].numberOfRanges {
        case 1:  return RangeRegx(match[0].range(at: 0), match[0].range(at: 0), word)
        default: return RangeRegx(match[0].range(at: 1), match[0].range(at: 0), word)
        }
    }

    /// Nearest match a regular expression and advance past match
    /// - note: extension of ParStr, for a set of words match in parallel. Only use on a short phrase.
    override func matchRegx(_ node: ParNode) -> ParMatching {

        if node.regx == nil {
            return ParMatching(nil, ok: false)
        }
        // search forward from last match
        if starti < words.count {
            for index in starti ..< words.count {
                if let word = match(index) {

                    let parItem = advancePar(node, index, word)
                    return ParMatching(parItem, ok: true)
                }
            }
        }

        // continue search from leftovers
        if starti > 0 {
            for  index in (0 ..< starti).reversed()  {
                if let word = match(index) {

                    let parItem = advancePar(node, index, word)
                    return ParMatching(parItem, ok: true)
                }
            }
        }
        // test unclaimed keywords in short term memory
        if parRecents.parItems.count > 0,
           node.reps.repMin >= 1 {
            
            for parItem in parRecents.parItems.reversed() {
                if  let id = parItem.node?.id, id == node.id,
                    let word = parItem.value,
                    let regx = node.regx,
                    let _ = matchRegxWord(regx, word) {
                    
                    let deltaTime = time - parItem.time
                    let parItem = advancePar(node, words.count, word, deltaTime)
                    return ParMatching(parItem, ok: true)
                }
            }
        }
        return ParMatching(nil, ok: false)
        
        func match(_ i: Int) -> String? {
            let word = words[i]
            if  let regx = node.regx,
                let rangeRegx = matchRegxWord(regx, word),
                let matching = rangeRegx.matching {
                let result = String(str[matching])
                return result
            } else {
                return nil
            }
        }
        
    }
}
