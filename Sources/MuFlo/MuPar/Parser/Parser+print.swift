//  Parser+print.swift
//  created by musesum on 7/1/17.

import Foundation

public extension Parser { // + print

    /// Text representation of parser node.
    /// Often used in generating a script from the graph.
    func makeScript(isLeft: Bool) -> String {
        var str = "" // return value
        switch type {
        case .quote:  str = "\"" + pattern + "\""
        case .regx:  str =  "'" + pattern.replacingOccurrences(of: "\"", with: "\\\\\"", options: .regularExpression) + "'"
        default:    str = pattern
        }
        if !isLeft, repeats.count != .one {
            str += repeats.makeScript()
        }
        return str
    }

    /// print node values, uber & sub nodes
    func printDetail(_ level: Int = 0, _ visitor: Visitor = Visitor(0)) {
        print(pad(level), terminator: " ")
        if !visitor.newVisit(id) {
            print("🔷 " + uberSubTitle())
        } else {
            print(uberSubTitle())
            for subParser in subParsers.values {
                subParser.printDetail(level+1, visitor)
            }
        }
        func uberSubTitle() -> String {
            var script = scriptTitle() + " ⇡("
            script += uberParser?.scriptTitle() ?? ""
            script += ") ⇣("
            var delim = ""
            for subParser in subParsers.values {
                script += delim;  delim = ", "
                script += subParser.scriptTitle()
            }
            script += ")"
            return script
        }
    }
    func scriptTitle () -> String {
        switch type {
        case .quote : return "\"\(pattern)\"" + ".\(id)"
        case .regx  : return "<regx>.\(id)"
        default:
            if pattern == "" { return "<\(type.rawValue)>.\(id)" }
            else { return pattern + ".\(id)" }
        }
    }

    /// minimal version of printDump
    func printTree(_ level: Int = 0, _ visitor: Visitor = Visitor(0)) {
        print(pad(level), terminator: " ")
        if !visitor.newVisit(id) {
            print(scriptShortTitle())
        } else {
            switch subParsers.count {
            case 0:  print(scriptShortTitle())
            default:
                print(scriptShortTitle() + " {")
                for subParser in subParsers.values {
                    subParser.printTree(level+1, visitor)
                }
                print(pad(level), terminator: " ")
                print("}")
            }
        }
        func scriptShortTitle () -> String {
            switch type {
            case .quote : return "\"\(pattern)\""
            case .regx  : return "<regx>"
            default:
                if pattern == "" { return "<\(type.rawValue)>" }
                else { return pattern }
            }
        }
    }
    /// Space adding for indenting hierarcical list
    func pad(_ level: Int) -> String {
        let pad = " ".padding(toLength: level*3, withPad: " ", startingAt: 0)
        return pad
    }

}
