//  Parsin.swift
//  created by musesum on 7/3/17.

import Foundation

/// Parse a substring `sub` of string `str`
public class Parsin {

    nonisolated(unsafe) static var traceMatch = false

    var whitespace: String
    var str = ""     // original string
    var sub = Substring()   // a substring of str, updated during parse

   init(_ str_: String, _ whitepace: String = "\t\n ") {
        
        self.whitespace = whitepace
        str = str_
        restart() // set sub from str
    }

    // may override to get words, so box with Any
    func getSubstring() -> Any? {
        return (sub)
    }
    // may override to put words, so box with Any
    func putSubstring(_ any: Any?) {
        sub = any as? Substring ?? sub
    }
    func isEmpty() -> Bool {
        return sub.isEmpty
    }

    // restart sub(string) from beginning of str
    func restart() {
        sub = str[str.startIndex ..< str.endIndex]
    }

    /// advance past whitespace and whatever else, such as `()`
    func advanceAfter(_ chars: String) {

        var count = 0;
        for char in sub {
            if chars.contains(char) { count += 1 }
            else                    { break }
        }
        sub = sub.advance(count) ?? sub
    }
    /// match a quoted string and advance past match
    func matchQuote(_ parser: Parser, withEmpty: Bool=false) -> ParMatch? {

        if parser.pattern == "" {
            if withEmpty {
                return ParMatch( Parsed(parser,""))
            }
        } else if parser.pattern.count <= sub.count,
                  sub.hasPrefix(parser.pattern) {
            sub = sub.advance(parser.pattern.count) ?? sub
            advanceAfter(whitespace)
            return ParMatch(Parsed(parser, parser.pattern))
        }
        return nil
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
            .anchorsMatchLines,
            .useUnixLineSeparators,
            .useUnicodeWordBoundaries]

        do {
            let regx = try NSRegularExpression(pattern: pattern, options: options)
            return regx
        } catch {
            PrintLog("⁉️ Parser(pat::) failed regx:\(pattern)")
            return nil
        }
    }

    /// match a regular expression and advance past match
    func matchRegx(_ parser: Parser) -> ParMatch? {

        if  let regx = parser.regx,
            let rangeRegx = matchRegx(regx),
            let advance = rangeRegx.advance,
            let matching = rangeRegx.matching {

            let upperIndex =  advance.upperBound

            sub = (upperIndex < sub.endIndex
                   ? sub[upperIndex ..< sub.endIndex]
                   : Substring())

            advanceAfter(whitespace)

            let result = String(str[matching])
            let parsed = Parsed(parser, result)
            return ParMatch(parsed)
        }
        return nil
    }

}

