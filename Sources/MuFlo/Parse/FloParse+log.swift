//  FloParse+log.swift
//  created by musesum on 4/12/19.

import Foundation

extension FloParse {

    func logParse(_ t: Flo?, _ parsed: Parsed, _ i: Int) {
        if !logParsing { return }
        let floName = t?.name ?? "nil"
        let pattern = parsed.parser.pattern
        let nodeId = ""//\(parsed.node!.id)"
        let nodeVal = parsed.result?.without(trailing: " ") ?? ""
        let prePad = " ".padding(toLength: i, withPad: " ", startingAt: 0)
        let nodePad = prePad + ("(" + floName + "," + pattern + nodeId + nodeVal + ")" )
        let nodeCall = nodePad

        // show array of next items
        var nextArray = " ["
        var arrayOp = ""
        for childPar in parsed.subParse {
            if childPar.parser.pattern != "" {

                nextArray += arrayOp + pattern
                arrayOp = ", "

            } else if let value = childPar.result {

                nextArray += arrayOp + value
                arrayOp = ", "
            }
        }
        nextArray += "]"

        print (nodeCall + nextArray)
    }

    func logDefault(_ function: String, _ parsed: Parsed) {
        if logDefaults {
            PrintLog("⁉️ FloParse::\(function) unknown keyword: \"\(parsed.parser.pattern)\"")
        }
    }
}
