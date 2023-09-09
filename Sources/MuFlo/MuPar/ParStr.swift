//  ParStr.swift
//
//  Created by warren on 7/3/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/// Parse a substring `sub` of string `str`
public class ParStr {
    
    public static var tracing = false

    public var whitespace = "\t "
    public var str = ""     // original string
    var sub = Substring()   // a substring of str, updated during parse
    
    public convenience init(_ str_: String) {
        
        self.init()
        str = str_
        restart() // set sub from str
    }
    
    // may override to get words, so box with Any
    func getSnapshot() -> Any? {
        return (sub)
    }
    // may override to put words, so box with Any
    func putSnapshot(_ any: Any?) {
        if let any = any as? Substring {
            sub = any
        }
    }
    func isEmpty() -> Bool {
        return sub.isEmpty
    }
    
    // restart sub(string) from beginning of str
    func restart() {
        sub = str[str.startIndex ..< str.endIndex]
    }
    
    public func read(_ filename: String, _ ext: String) -> String {
        
        let resource = BundleResource(name: filename, type: ext)
        do {
            let resourcePath = resource.path
            return try String(contentsOfFile: resourcePath) }
        catch {
            print("⁉️ ParStr::\(#function) error:\(error) loading contents of:\(resource.path)")
        }
        return ""
    }
    
    /// advance past whitespace and whatever else, such as `()`
    func advancePastChars(_ chars: String) {
        
        var count = 0;
        for char in sub {
            if chars.contains(char) { count += 1 }
            else                    { break }
        }
        if count > 0 {
            sub = count < sub.count ? sub[ sub.index(sub.startIndex, offsetBy: count) ..< sub.endIndex] : Substring()
        }
    }
    
    /// match a quoted string and advance past match
    func matchQuote(_ node: ParNode, withEmpty: Bool=false) -> ParMatching {
        
        let pat = node.pattern
        
        if pat == "" {
            if withEmpty {
                return ParMatching( ParItem(node,""), ok: true)
            }
        } else if pat.count <= sub.count, sub.hasPrefix(pat) {
            
            sub = pat.count < sub.count
                ? sub[ sub.index(sub.startIndex, offsetBy: pat.count) ..< sub.endIndex]
                : Substring()
            
            advancePastChars(whitespace)
            return ParMatching(ParItem(node, pat), ok: true)
        }
        return ParMatching(nil, ok: false)
    }
    
    /// Any word followed by parens `()` is a special match type
    /// where runtime searches and attaches a closure to provide more
    /// word to compare. For example:
    ///
    ///     events : 'event' eventList()
    ///
    /// Creates node `events` that has two child nodes: `'event'` and `eventList()`
    /// After parsing the script, the runtime searches for the node `eventList()`
    /// and attaches as `eventListChecker`, which returns a list a words to check.
    ///
    /// This is very useful for dynamic data which changes ofen, such as a Calendar
    ///
    func matchMatchStr(_ node: ParNode) -> ParMatching {
        // closure has already been set, so execute it
        if let matchStr = node.matchStr,
            let str = matchStr(sub) {
            
            sub = str.count < sub.count
                ? sub[ sub.index(sub.startIndex, offsetBy: str.count) ..< sub.endIndex ]
                : Substring()
            advancePastChars(whitespace+"()")
            return ParMatching(ParItem(node, str), ok: true)
        }
            // closure has not been set, so test name match
        else {
            let matching = matchQuote(node)
            if matching.ok {
                advancePastChars(whitespace+"()")
                return matching
            }
        }
        return ParMatching(nil, ok: false)
    }
    
    static func makeSlice(_ sub: Substring, del: String = "⦙", length: Int = 10) -> String {
        
        if sub.count <= 0 {
            return del.padding(toLength: length, withPad: " ", startingAt: 0) + del + " "
        } else {
            let endIndex = min(length, sub.count)
            let subEnd = sub.index(sub.startIndex, offsetBy: endIndex)
            let subStr = sub.count > 0 ? String(sub[sub.startIndex ..< subEnd]) : " "
            return del + subStr
                .replacingOccurrences(of: "\n", with: "↲")
                .padding(toLength: length, withPad: " ", startingAt: 0) + del + " "
        }
    }
    // ----------------------------------------
    
    /// result range for regular expression
    struct RangeRegx {
        var matching: Range<String.Index>?
        var advance: Range<String.Index>?
        init(_ matching_: NSRange, _ advance_: NSRange, _ str: String) {
            matching = Range(matching_, in: str)
            advance = Range(advance_, in: str)
        }
    }
    
    /// Match regular expression to beginning of substring
    ///
    /// - parameter regx: compiled regular expression
    /// - returns: ranges of inner value and outer match, or nil
    func matchRegx(_ regx: NSRegularExpression) -> RangeRegx? {
        
        let nsRange = NSRange( sub.startIndex ..< sub.endIndex, in: str)
        let match = regx.matches(in: str, options: [.anchored], range: nsRange)
        if match.count == 0 { return nil }
        let range0 = match[0].range(at: 0)
        switch match[0].numberOfRanges {
            case 1:
                return RangeRegx(range0, range0, str)
            default:
                let range1 = match[0].range(at: 1)
                if range1.length > 0 {
                    return RangeRegx(range1, range0, str)
                } else {
                    return RangeRegx(range0, range0, str)
                }
        }
    }
    
    /// compile a regular expression to be used later, during parse
    static func compile (_ pattern: String) -> NSRegularExpression? {
        
        let options: NSRegularExpression.Options = [
            //.caseInsensitive,
            //.allowCommentsAndWhitespace,
            //.ignoreMetacharacters,
            //.dotMatchesLineSeparators,
            .anchorsMatchLines,
            .useUnixLineSeparators,
            .useUnicodeWordBoundaries]
        
        do { let regx = try NSRegularExpression(pattern: pattern, options: options)
            return regx
        }
        catch {
            print("⁉️ ParNode(pat::) failed regx:\(pattern)")
            return nil
        }
    }
    
    /// match a regular expression and advance past match
    func matchRegx(_ node: ParNode) -> ParMatching {
        
        if  let regx = node.regx,
            let rangeRegx = matchRegx(regx),
            let advance = rangeRegx.advance,
            let matching = rangeRegx.matching {
            
            let upperIndex =  advance.upperBound
            
            sub = upperIndex < sub.endIndex
                ? sub[upperIndex ..< sub.endIndex]
                : Substring()
            
            advancePastChars(whitespace)
            
            let result = String(str[matching])
            let parItem = ParItem(node, result)
            return ParMatching(parItem, ok: true)
        }
        return ParMatching(nil, ok: false)
    }
    
    func trace(_ node: ParNode?, _ any: Any?, _ level: Int) {
        
        // ignore if not tracing
        if !ParStr.tracing { return }

        func getName(_ node: ParNode) -> String? {
             let suffix =  node.isName ?  node.pattern : ""

            if let prevNode = node.edgePrevs.first?.nodePrev,
               let name = getName(prevNode) {
                return suffix.isEmpty ? name : name + "." + suffix
            }
            return suffix
        }

        // add a value if there is one
        if let parItem = any as? ParItem,
            let parValue = parItem.value,
            let node = node {
            // indent predecessors based on level
            let pad = " ".padding(toLength: level*2, withPad: " ", startingAt: 0)
            let slice = ParStr.makeSlice(sub) + pad
            let reps = node.reps.makeScript()
            let val = parValue.replacingOccurrences(of: "\n", with: "")
            let title = getName(node) ?? node.pattern
            print(slice + " \(title).\(node.id) \(reps) \(val)")
        }
    }
    
}

