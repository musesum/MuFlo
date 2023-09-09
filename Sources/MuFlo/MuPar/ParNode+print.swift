//  ParNode+print.swift
//
//  Created by warren on 7/1/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public extension ParNode {
    
    func printGraph(_ visit: Visitor, _ level: Int = 0) {
        
        if visit.newVisit(id) {

            var left = "⦙ " + " ".padding(toLength: level, withPad: " ", startingAt: 0)
            for edgePrev in edgePrevs {
                if let nodePrev = edgePrev.nodePrev {
                    left += nodePrev.nodeOpId() + " "
                }
            }
            left = left.padding(toLength: 32, withPad: " ", startingAt: 0)

            let center = (nodeOpId()+" ").padding(toLength: 24, withPad: " ", startingAt: 0)

            var right = ""
            for edgeNext in edgeNexts {
                if let nodeNext = edgeNext.nodeNext {
                    right += nodeNext.nodeOpId() + " "
                }
            }

            print (left + center + right)

            for edgeNext in edgeNexts {
                edgeNext.nodeNext?.printGraph(visit, level+1)
            }
        }
    }
    /// Text representation of node and its unique ID. Used in graph dump, which includes before and after edges.
    func nodeOpId() -> String {

        let opStr =  (pattern == ""     ? parOp.rawValue :
                        parOp == .or    ? "|" :
                        parOp == .match ? "()" : ".")

        let repStr = (reps.count == .one ? "" : reps.makeScript()) + (reps.surf ? "~" : "")

        switch parOp {
        case .quo:  return "\"\(pattern)\"\(repStr + opStr)\(id)" //+ repStr
        case .rgx:  return "\'\(pattern)\'\(repStr + opStr)\(id)" //+ repStr
        default:    return "\(pattern)\(repStr + opStr)\(id)" //+ parOp.rawValue // + idStr
        }
    }
    /// Text representation of node and its unique ID. Used in graph dump, which includes before and after edges.
    func nodeStrId() -> String {

       switch parOp {
        case .quo:  return "\"\(pattern)\".\(id)"
        case .rgx:  return "\'\(pattern)\'.\(id)"
        default:    return pattern + ".\(id)"
        }
    }
    /// Text representation of node. Often used in generating a script from the graph.
    func makeScript(isLeft: Bool) -> String {
        
        var str = "" // return value

        switch parOp {
        case .quo:  str = "\"" + pattern + "\""
        case .rgx:  str =  "'" + pattern.replacingOccurrences(of: "\"", with: "\\\\\"", options: .regularExpression) + "'"
        default:    str = pattern
        }
        if !isLeft, reps.count != .one {
            str += reps.makeScript()
        }
        return str
    }

    /// Space adding for indenting hierarcical list
    func pad(_ level: Int) -> String {
        let pad = " ".padding(toLength: level*4, withPad: " ", startingAt: 0)
        return pad
    }

    ///
    func makeSuffixs(_ level: Int) -> String {

        /// And edgeNexts
        func makeAnd(_ next: ParNode) -> String {
            
            if next.isName {
                return next.makeScript(isLeft: false)
            }

            var str = "" // return value
            let dels = next.reps.count == .one ? ["", " ", ""] : ["(", " ", ")"]
            var del = dels[0]
            for nextSuffix in next.edgeNexts {

                str += del
                
                if let nodeNext2 = nextSuffix.nodeNext {
                    // As of xcode 9 beta 3, 
                    if      nodeNext2.parOp == .or    { str += makeOr(nodeNext2, inner: false) }
                    else if nodeNext2.parOp == .and   { str += makeAnd(nodeNext2) }
                    else if nodeNext2.parOp == .match { str += nodeNext2.makeScript(level: level) + "()" }
                    else                              { str += nodeNext2.makeScript(level: level+1) }
                }
                del = dels[1]
            }
            str += dels[2] + next.reps.makeScript()
            return str
        }
        
        /// Alternation suffixes
        func makeOr(_ next: ParNode, inner: Bool) -> String {

            var str = "" // return value
            let dels = inner ? ["", " | ", ""] :  [" (", " | ", ")"]
            var del = dels[0]
            for next2 in next.edgeNexts {
                
                str += del
                
                if let next2Node = next2.nodeNext {
                    if      next2Node.parOp == .and { str += makeAnd(next2Node) }
                    else if next2Node.parOp == .or  { str += makeOr(next2Node, inner: true) }
                    else                            { str += next2Node.makeScript(level: level+1) }
                }
                del = dels[1]
            }
            str += dels[2] + next.reps.makeScript() + " "
            return str
        }
        
        /// Definition
        func makeDef(_ next: ParNode) -> String {
            
            var str = " {\n" // return value
            for next2 in next.edgeNexts {
                if let nodeNext = next2.nodeNext {
                    str += nodeNext.makeScript(level: level+1) + "\n"
                }
            }
            str += pad(level) + "}\n"
            return str
        }
        
        // ────────────── begin ──────────────

        // test for a ≈ b | c | d
        var onlyOrs = true
        testOrs: for edgeNext in edgeNexts {
            switch edgeNext.nodeNext?.parOp {
                case .or, .def:
                    continue
                default:
                // otherwise a ≈ b (c | d)
                onlyOrs = false
                break testOrs
            }
        }
        var str = ""
        for edgeNext in edgeNexts {
            
            if let next = edgeNext.nodeNext {
               switch next.parOp {
                case .and:   str += makeAnd(next)
                case .or:    str += makeOr(next, inner: onlyOrs)
                case .def:   str += makeDef(next)
                case .match: str += next.makeScript(isLeft: false) + "() "
                default:     str += next.makeScript(isLeft: false) + " "
                }
            }
        }
        return str
    }
    
    /**
     Print graph as script starting form left side of statement.
     The resulting script should resemble the original script.
     - Parameter level: depth of namespace hierarchy, where some isName nodes are local
     */
    func makeScript(level: Int = 0) -> String {

        var str = "" // return value

        if isName { str += pad(level) + makeScript(isLeft: true) + " ≈ " }
        else      { str +=              makeScript(isLeft: false)  }
        
        str += makeSuffixs(level)
        return str
    }

    ///  [par.end.^([ \n\t,;]*|[/][/][^\n]*)]
    func scriptLineage(_ level: Int) -> String {
    
        if  let edgePrev = edgePrevs.first, level > 0,
            let nodePrev = edgePrev.nodePrev {
            return nodePrev.scriptLineage(level-1) + "." + pattern
        }
        else {
            return pattern
        }
    }

}
