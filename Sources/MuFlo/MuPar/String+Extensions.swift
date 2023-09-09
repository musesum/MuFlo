//  String+Extensions.swift
//
//  Created by warren on 6/22/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/// Padding spaces for indentation
public func pad(_ level: Int) -> String {
    let pad = "⦙ " + " ".padding(toLength: level*3, withPad: " ", startingAt: 0)
    return pad
}

/// Divider to separate listings
public func divider(_ length: Int = 30) -> String {
    return "\n" + "─".padding(toLength: 30, withPad: "─", startingAt: 0) + "\n"
}

extension String {
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(from: Int) -> String {
        return self[min(from, count) ..< count]
    }
    
    func substring(from: Int, to: Int) -> String {
        return self[min(from, count) ..< min(to, count)]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let s = index(startIndex, offsetBy: range.lowerBound)
        let e = index(s, offsetBy: range.upperBound - range.lowerBound)
        return String(self[s..<e])
    }
    /// split "a~b" into "a","~","b"
    ///
    public func splitWild(_ wild: String) -> (String, String, String) {
        
        var prefix    = "" // a in a~b
        var wildcard  = "" // ~ in a~b
        var suffix    = "" // b in a~b
        
        // get non wildcard chars for prefix
        var i = 0
        while i < count, !wild.contains(self[i]) { i += 1 }
        if i > 0 {  prefix = self[0 ..< i] }
        
        // get wildcard chars for wildcard
        var j = i
        while j < count, wild.contains(self[j]) { j += 1 }
        if j > i { wildcard = self[i ..< j] }
        
        // get remaining chars for extra
        if count > j { suffix = self[j ..< count] }
        
        return (prefix, wildcard, suffix)
    }
    func matches(pre prefix: String, suf suffix: String) -> Bool {
        return hasPrefix(prefix) && hasSuffix(suffix)
    }
    
    /// add a space if last character is not a space of left paren
    public func parenSpace(delim: String = "") -> String {
        if last == "(" { return "" }
        if last == " " { return "" }
        else           { return delim + " "}
    }
    /// append string to self with spacing
    public mutating func spacePlus(_ str: String?) {
        guard let str else { return }
        if str == "" { return }
        if      str  == "," { self = without(trailing: " ") + str }
        else if last == "(" { self += str }
        else if last == " " { self += str }
        else                { self = isEmpty ? str : with(trailing: " ") + str }
    }
    /// remove trailing spaces before adding character.
    /// often used to insure a single trailing space, instead of two.
    public func with(trailing: String) -> String {
        var trim = self
        while trim.last == " " { trim.removeLast() }
        return trim + trailing
    }
    /// remove trailing spaces 
    /// often used to insure a single trailing space, instead of two.
    public func without(trailing: String) -> String {
        var trim = self
        while let last = trim.last, trailing.contains(last) { trim.removeLast() }
        return trim 
    }
    
    
    static public func * (lhs: String, rhs: Int) -> String {
        var str = ""
        for _ in 0 ..< rhs {
            str += lhs
        }
        return str
    }
    
    public func strHash() -> Int {
        var result = Int (5381)
        let buf = [UInt8](self.utf8)
        for b in buf {
            result = 127 * (result & 0x00ffffffffffffff) + Int(b)
        }
        return result
    }
}
