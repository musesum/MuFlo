//  ParItem+reduce.swift
//
//  created by musesum on 3/18/19.

import Foundation

extension Parsed {

    /// reduce strand ParItem to only those that match keywords
    public func reduce() {

        for subParse in subParse {
            subParse.reduce()
        }
        var reduced = [Parsed]()
        for subParse in subParse {
            if subParse.isEmpty {
                reduced.append(contentsOf: subParse.subParse)
            } else if subParse.result == nil, subParse.subParse.isEmpty {
                // skip unfilled
            } else {
                reduced.append(subParse)
            }
        }
        subParse = reduced
    }
    func printAll(_ level: Int = 0) {

        var script = parser.pattern
        if script.count > 0 { script += "_\(level)"}
        if let result {
            if script.count > 0 { script += " " }
            script += result + "_\(level)"
        } else if script.isEmpty {
            script = "∅" // isEmpty
        }
        print(script, terminator: " ⫶ ")

        for subParse in subParse {
            subParse.printAll(level+1)
        }
        if level == 0 { print() }
    }
}
