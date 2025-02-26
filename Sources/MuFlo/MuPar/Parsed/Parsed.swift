//  ParItem.swift
//  created by musesum on 7/13/17.

import Foundation

/// A Parser pattern plus instance of Any, which may be either a String or [ParItem]
public class Parsed {

    internal var parser: Parser   // reference to parse node
    internal var result: String?    // either value or child, not both to support
    internal var subParse = [Parsed]() // either a String, ParItem, or [ParItem]
    internal var nextResult: String? { subParse.first?.result }
    internal var isEmpty: Bool { parser.pattern == "" && result == nil }

    init (_ parser: Parser,
          _ value: String?) {
        self.parser = parser
        self.result = value
    }

    init (_ parser: Parser,
          _ subParsed: [Parsed]) {
        self.parser = parser
        self.subParse = subParsed
    }

   /// Search a strand of nodeAnys for the last node
    func lastNode() -> Parsed? {
        for reversePar in subParse.reversed() {
            if reversePar.result != nil ||
                reversePar.subParse.count > 0 {
                return reversePar.lastNode()
            }
        }
        return self
    }

    public func firstDouble() -> Double {
        if let value = nextResult ?? subParse.first?.nextResult  {
            return Double(value) ?? Double.nan
        }
        return Double.nan
    }

    func reducePars() {
        reducePar(self)
    }
    func reducePar(_ parent: Parsed?) {
        if let parent,
           parser.pattern == "",
           result == nil,
           parent.subParse.count == 1 {

            parent.subParse = subParse
        }
        for subParse in subParse {
            subParse.reducePar(self)
        }
    }

    func printTokens() {
        var script = ""
        scriptTokens(&script)
        print(script)
    }

    func scriptTokens(_ script: inout String) {
        var str = parser.pattern
        if let result {
            if str.count > 0 { str += ":" }
            str += "(\"\(result)\")"
        } else if str.count > 0, script.count > 0, script.last != " " {
            str = "." + str
        }
        script += str
        switch subParse.count {
        case 0: break
        case 1:
            //script += "."
            subParse.first?.scriptTokens(&script)

        default:
            var delim = ""
            script += " { "
            for subParse in subParse {
                script += delim
                subParse.scriptTokens(&script)
                delim = " ⫶ "
            }
            if script.last != " " { script += " " }
            script += "}"
        }
        
    }
    func printKeywords() {
        if parser.pattern != "" {
            print(parser.pattern, terminator: " ⫶ ")
        }
        for subParse in subParse {
            subParse.printKeywords()
        }
    }

}
