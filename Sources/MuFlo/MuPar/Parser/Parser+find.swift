//  Parser+find.swift
//  created by musesum on 7/27/17.

import Foundation

public extension Parser { // + find

    /// Search for pattern matches in substring
    /// ```
    ///    Parser may match the following substring in parsin:
    ///        or    - alternation find first match
    ///        and   - all suffixes must match
    ///        match - external function
    ///        quo   - quoted string
    ///        rgx   - regular expression
    /// ```
    func parseInput(_ parsin: Parsin, _ level: Int=0) -> ParMatch? {

        let snapshot = parsin.getSubstring() // push
        var matching: ParMatch?
        switch type {
        case .def   : matching = repeating(matchAnd)
        case .and   : matching = repeating(matchAnd)
        case .or    : matching = repeating(matchOr)
        case .quote : matching = repeating(matchQuote)
        case .regx  : matching = repeating(matchRegx)
        }

        if let parsed = matching?.parsed {
            parsin.traceMatch(self, parsed, level)
        } else {
            parsin.putSubstring(snapshot) // pop
        }
        return matching

        /// Repeat closure based on repetion range range and closure's result
        func repeating(_ matchFunc: ParMatchFunc) -> ParMatch? {
            parsin.traceMatch(self, nil, level)
            let matching = ParMatch()
            for _ in 0 ..< repeats.repMax {
                if let matched = matchFunc(),
                    matching.add(matched) {
                    continue // on to next repeat
                }
                break // done
            }
            if matching.count < repeats.repMin {
                return nil
            }
            let reduced = matching.reduceFound(self, isName)
            return reduced
        }

        func matchAnd() -> ParMatch? {
            let matching = ParMatch()
            for subParser in subParsers.values {
                // skip namespace
                if subParser.type == .def {
                    continue
                }
                let matched = subParser.parseInput(parsin, level)
                if matching.add(matched) {
                    continue
                }
                return nil
            }
            return matching.reduceFound(self)
        }

        func matchOr() -> ParMatch? {
            let snapshot = parsin.getSubstring() // push
            for subParser in subParsers.values {
                parsin.putSubstring(snapshot) // pop to restart
                if let parsed = subParser.parseInput(parsin, level)?.parsed {
                    return ParMatch(parsed)
                }
            }
            return nil
        }
        /// return empty parsed, when parsin.sub matches keyword
        func matchQuote() -> ParMatch? {
            return parsin.matchQuote(self)
        }
        /// return result, when parsin.sub matches regular expression in pattern
        func matchRegx() -> ParMatch? {
            return parsin.matchRegx(self)
        }
    }

    /// Path must match all node names, ignores and/or/cardinals
    func findPath(_ parsin: Parsin) -> Parser? {
        var match: ParMatch?
        switch type {
        case .regx  : match = parsin.matchRegx(self)
        case .quote : match = parsin.matchQuote(self, withEmpty: true)
        default     : break
        }
        guard let _ = match?.result else { return nil }

        if parsin.isEmpty() {
            return self // finished
        }
        for subParser in subParsers.values {
            if let foundParser = subParser.findPath(parsin) {
                return foundParser
            }
        }
        return self
    }

}
