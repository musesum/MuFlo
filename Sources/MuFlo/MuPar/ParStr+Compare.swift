//  ParStr+Compare.swift
//
//  Created by warren on 8/7/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file


import Foundation

public extension ParStr {
    /// compare expected with actual result and print error strings
    /// with ⁉️ marker at beginning of non-matching section
    ///
    /// - parameter script: expected output
    /// - parameter script: actual output
    ///
    static func testCompare(_ expected: String, _ actual: String, echo: Bool = false) -> Int {
        if echo {
            print ("⟹ " + expected, terminator: "")
        }
        // for non-match, compare will insert a ⁉️ into expectedErr and actualErr
        if let (expectedErr, actualErr) = ParStr.compare(expected, actual) {
            print (" ⁉️ mismatch")
            print ("expect ⟹ " + expectedErr)
            print ("actual ⟹ " + actualErr + "\n")
            return 1 // error
        } else {
            print ("🧪 " + expected + " ✓\n")
            return 0 // no error
        }
    }
    
    static func compare(_ str1: String, _ str2: String, removeComments: Bool = false) -> (String, String)? {
        
        let sub1 = Substring(str1)
        let sub2 = Substring(str2)
        var i1 = sub1.startIndex
        var i2 = sub2.startIndex
        
        // advance i1, i2 indexes past whitespace and/or comments
        func eatWhitespace() {
                        
            while i1 < sub1.endIndex && "\n\t ".contains(sub1[i1]) { i1 = sub1.index(after: i1) }
            while i2 < sub2.endIndex && "\n\t ".contains(sub2[i2]) { i2 = sub2.index(after: i2) }

            if removeComments {
                var hasComment = false
                // remove comments
                if sub1[i1 ..< sub1.endIndex].hasPrefix("//") {
                    while i1 < sub1.endIndex && "\n" != str1[i1] { i1 = sub1.index(after: i1) }
                    hasComment = true
                }
                if sub2[i2 ..< sub2.endIndex].hasPrefix("//") {
                    while i2 < sub2.endIndex && "\n" != str2[i2] { i2 = sub2.index(after: i2) }
                    hasComment = true
                }
                if hasComment {
                    // remove trailing whitespace and/or multi-line comments
                    eatWhitespace()
                }
            }
        }
        
        func makeError() -> (String, String)? {
            
            let error1 = str1[..<i1] + "⁉️" + str1[i1..<str1.endIndex]
            let error2 = str2[..<i2] + "⁉️" + str2[i2..<str2.endIndex]
            return (String(error1), String(error2))
        }
        
        // -------------- body --------------
        
        eatWhitespace() // start by removing leading comments
        
        while i1 < str1.endIndex && i2 < sub2.endIndex {
            
            if sub1[i1] != sub2[i2] { return makeError() }
            
            i1 = sub1.index(after: i1)
            i2 = sub2.index(after: i2)
            
            eatWhitespace()
        }
        
        // nothing remaining for either string?
        
        if  i1 == sub1.endIndex,
            i2 == sub2.endIndex {
            return nil
        } else {
            return makeError()
        }
    }
    
    func compare(_ str2: String) -> String? {
        if let (_, error) = ParStr.compare(str, str2) {
            return error
        }
        return nil
    }
    
}

