//  Parsin+Compare.swift
//  created by musesum on 8/7/17.

import Foundation

public extension Parsin { // + compare

    /// compare expected with actual result and print error strings
    /// with ⁉️ marker at beginning of non-matching section
    ///
    static func testCompare(_ expect: String,
                            _ actual: String,
                            strict: Bool = false,
                            echo: Bool = false) -> Int {
        if echo {
            print ("⟹ " + expect, terminator: "")
        }
        // for non-match, compare will insert a ⁉️ into expectedErr and actualErr
        if let (expectedErr, actualErr) = Parsin.compare(expect, actual, strict) {
            print (" ⁉️ mismatch")
            print ("expect ⟹ " + expectedErr)
            print ("actual ⟹ " + actualErr.divider())
            return 1 // error
        } else {
            print (expect + " 🧪")
            return 0 // no error
        }
    }
    private static func compare(_ expect: String,
                                _ actual: String,
                                _ strict: Bool = false,
                                skipComments: Bool = true) -> (String, String)? {

        let expectSub = Substring(expect)
        let actualSub = Substring(actual)
        var expecti = expectSub.startIndex
        var actuali = actualSub.startIndex

        // start by removing leading comments
        eatWhitespace()
        while expecti < expect.endIndex && actuali < actualSub.endIndex {
            if expectSub[expecti] != actualSub[actuali] { return makeError() }
            expecti = expectSub.index(after: expecti)
            actuali = actualSub.index(after: actuali)
            eatWhitespace()
        }
        // nothing remaining for either string?
        if  expecti == expectSub.endIndex,
            actuali == actualSub.endIndex {
            return nil
        } else {
            return makeError()
        }

        // advance i1, i2 indexes past whitespace and/or comments
        func eatWhitespace() {
            let eat = strict ? "\t " : "\n\t "
            while expecti < expectSub.endIndex &&
                    eat.contains(expectSub[expecti]) {
                expecti = expectSub.index(after: expecti)
            }
            while actuali < actualSub.endIndex &&
                    eat.contains(actualSub[actuali]) {
                actuali = actualSub.index(after: actuali)
            }
            if skipComments {
                removeComments()
            }
        }
        func removeComments() {
            var hasComment = false
            if expectSub[expecti ..< expectSub.endIndex].hasPrefix("//") {
                while expecti < expectSub.endIndex &&
                        "\n" != expect[expecti] {
                    expecti = expectSub.index(after: expecti)
                }
                hasComment = true
            }
            if actualSub[actuali ..< actualSub.endIndex].hasPrefix("//") {
                while actuali < actualSub.endIndex &&
                        "\n" != actual[actuali] {
                    actuali = actualSub.index(after: actuali)
                }
                hasComment = true
            }
            if hasComment {
                // remove trailing whitespace and/or multi-line comments
                eatWhitespace()
            }
        }
        func makeError() -> (String, String)? {
            
            let error1 = expect[..<expecti] + "⁉️" + expect[expecti..<expect.endIndex]
            let error2 = actual[..<actuali] + "⁉️" + actual[actuali..<actual.endIndex]
            return (String(error1), String(error2))
        }
    }
    
    func compare(_ str2: String) -> String? {
        if let (_, error) = Parsin.compare(str, str2) {
            return error
        }
        return nil
    }
    
}

