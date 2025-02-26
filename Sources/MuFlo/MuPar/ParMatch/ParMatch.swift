//  ParMatching.swift
//  created by musesum on 8/5/17.

import Foundation

public typealias ParMatchFunc = ()->ParMatch?

/// An array of `[Parsed]`, which can reduce a single suffix
public class ParMatch {

    public var found = [Parsed]()
    var count = 0
    var parsed: Parsed? { found.last }
    var result: String? { found.last?.result }

    init(_ parsed: Parsed? = nil) {
        guard let parsed else { return }

        if parsed.subParse.isEmpty,
           parsed.parser.repeats.repMin == 0 {
        }
        found.append(parsed)
    }

    init(_ found: [Parsed]) {
        self.found = found
    }

    /// add a sub ParMatching to this ParMatching
    func add(_ match: ParMatch?) -> Bool {
        if let parsed = match?.parsed {
            add(parsed)
            count += 1
            return true
        }
        return false
    }

    /// add a parsed to this ParMatching
    func add(_ parsed: Parsed) {
        if !parsed.parser.ignore {
            found.append(parsed)
        }
    }

    /// Reduce anys
    func reduceFound(_ parser: Parser, _ isName: Bool = false) -> ParMatch? {

        return matched() ?? promoting()

        func matched() -> ParMatch? {
            switch found.count {
            case 0:
                let parsed = Parsed(parser, nil)
                let matching = ParMatch(parsed)
                return matching

            case 1:
                guard let parsed = found.first else { return nil }
                switch parsed.parser.type  {
                case .def, .and, .or:

                    if isName, parsed.parser.id != parser.id {
                        return ParMatch(Parsed(parser, [parsed]))
                    } else {
                        return ParMatch(parsed)
                    }
                case .quote, .regx:
                    return ParMatch(Parsed(parser, parsed.result))
                }
            default: return nil
            }
        }

        func promoting() -> ParMatch {
            var promotions = [Parsed]()
            for parsed in found {
                if let promotePars = promoteParsed(parsed) {
                    promotions.append(contentsOf: promotePars)
                } else {
                    promotions.append(parsed)
                }
            }
            let parsed = Parsed(parser, promotions)
            return ParMatch(parsed)
        }

        func promoteParsed(_ parsed: Parsed) -> [Parsed]? {
            if  parsed.parser.pattern == "",
                parsed.result == nil {
                return parsed.subParse
            }
            return nil
        }
    }
}
