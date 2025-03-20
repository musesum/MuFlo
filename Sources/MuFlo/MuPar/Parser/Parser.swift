//  Parser.swift
//  created by musesum on 6/22/17.

import Foundation
import Collections

/// A node in a parse graph with prefix and suffix edges.
public class Parser: FloId {

    var pattern: String         /// name, quote, or regex pattern
    var type: ParType           /// type of operation on parsin
    var repeats: ParRepeats     /// number of allowed repetitions to be true
    var uberParser: Parser?
    var subParsers = OrderedDictionary<Int,Parser>()

    var regx: NSRegularExpression?  /// compiled regular expression
    var isName = false              /// lValue; name as in `name: what ever`
    var ignore = false              /// ignore quotes and patterns beginning with "_"

    init(_ type: ParType,
         _ pattern: String = "",
         _ parCount: ParCount = .one,
         _ subParsers: [Parser] = []) {

        self.type = type
        self.repeats = ParRepeats(parCount)
        self.pattern = pattern
        super.init()

        if (pattern.count>1 && pattern[0] == "_") {
            self.pattern.removeFirst()
            self.ignore = true
        } else if type == .quote {
            self.ignore = true
        }
        if type == .regx {
            self.pattern = self.pattern.replacingOccurrences(of: "\\\"", with: "\"")
            regx = Parsin.compile(pattern)
        }

        for subParser in subParsers {
            self.subParsers[subParser.id] = subParser
            subParser.uberParser = self
        }
        //  for Par.par, only the top node is type == .def, which
        // during runtime, is instantiated last as the
        if type == .def {
            connectReferences(Visitor(0))
        }
    }

    func graft(_ parser: Parser) {

        type       = parser.type
        uberParser = parser.uberParser
        subParsers = parser.subParsers
        regx       = parser.regx
        isName     = true
    }
}

