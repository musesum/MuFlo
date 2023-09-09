//  ParNode.swift
//
//  Created by warren on 6/22/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public typealias ParItemVoid = (_ parItem: Any) -> Void
public typealias ParStrMatch = (_ parStr: ParStr, _ level: Int) -> ParMatching?

/// A node in a parse graph with prefix and suffix edges.
public class ParNode {

    public var id = Visitor.nextId()

    /// name, quote, or regex pattern 
    public var pattern = ""

     /// Kind of operation
     /// - def: namespace declaration only
     /// - or: of alternate choices, take first match in after[]
     /// - and: all Pars in after[] must be true
     /// - rgx: regular expression - true if matches pattern
     /// - quo: quote - true if path matches pattern
     /// - match: function -- false if nil, true when returning a string
    enum ParOp: String { case

        def   = ":",  // namespace declaration only
        or    = "|",  // of alternate choices, take first match in after[]
        and   = "&",  // all Pars in after[] must be true
        rgx   = "'",  // regular expression - true if matches pattern
        quo   = "\"", // quote - true if path matches pattern
        match = "()"  // function - false if nil, true when returning a string
        func isIn(_ elements: [ParOp]) -> Bool {
            return elements.contains(self)
        }
    }
    var parOp = ParOp.quo         // type of operation on parseStr

    public var reps = ParRepetitions() // number of allowed repetitions to be true
    var matchStr: MatchStr?         // call external function to match substring, return any
    var foundCall: ParItemVoid?      // call external function with Found array, when true
    var edgePrevs = [ParEdge]()       // prev edges, sequence is important for maintaining precedence
    var edgeNexts = [ParEdge]()       // next edges, sequence is important for maintaining precedence
    var regx: NSRegularExpression?  // compiled regular expression
    var ignore = false              // node _name has _ prefrefix
    var isName = false              // lValue; name as in `name: what ever`

    func graft(_ node: ParNode) {
        
        parOp     = node.parOp
        matchStr  = node.matchStr
        edgePrevs = node.edgePrevs
        edgeNexts = node.edgeNexts
        regx      = node.regx
        ignore    = node.ignore
        isName    = true
    }
    public init (_ pat: String, _ after: [ParNode]) {
        
        (parOp, reps, pattern) = splitPat(pat)
        
        switch parOp {
        case .rgx:  regx = ParStr.compile(pattern)
        default: break
        }
        
        for node in after {
            let _ = ParEdge(self, node)
        }
        // top node of hierarchy for explicit declarations in code
        // which is declared top down, so includes a list of after Nodes
        // ignore while parsing script
        if parOp == .def {
            connectReferences(Visitor(0))
        }
    }
    
    public init (_ pat: String) {
        
        (parOp, reps, pattern) = splitPat(pat)
        
        switch parOp {
        case .rgx:  regx = ParStr.compile(pattern)
        default: break
        }
    }

     /// Split a pattern into operation, repetitions, string
     ///
    func splitPat(_ pat: String) -> (ParOp, ParRepetitions, String) {
        
        // return values
        var op = ParOp.and
        var rep = ParRepetitions()
        var str = ""
        
        var count = pat.count
        var starti = 0 // starting index
        var hasLeftParen = false
        
        scanning: for char in pat.reversed() {
            
            switch char {
            case ":": op = .def ; count -= 1
            case "&": op = .and ; count -= 1
            case "|": op = .or  ; count -= 1
                
            case ")": hasLeftParen = true
            case "(": if hasLeftParen { op = .match ; count -= 2 ; break scanning}
            case "\"": op = .quo ; count -= 1 ; break scanning
            case "'": op = .rgx ; count -= 1 ; break scanning
                
            case "?": rep = ParRepetitions(.opt)  ; count -= 1
            case "*": rep = ParRepetitions(.any)  ; count -= 1
            case "+": rep = ParRepetitions(.many) ; count -= 1
            case ".": rep = ParRepetitions(.one)  ; count -= 1
            default: break scanning
            }
        }
        
        switch op {
            
        case .rgx:
            scanning: for char in pat {
                switch char {
                case "\\": starti += 1; count -= 1
                case "'": starti += 1; count -= 1
                case "_": starti += 1; count -= 1; ignore = true
                default: break scanning
                }
            }
        case .quo: if pat.first == "\"" { starti += 1; count -= 1}; ignore = true
        default:   if pat.first == "_"  { starti += 1; count -= 1 ; ignore = true }
        }
        
        if count <= pat.count {

            let patStart = pat.index(pat.startIndex, offsetBy: starti)
            let patEnd   = pat.index(patStart, offsetBy: count)
            str = String(pat[patStart ..< patEnd])
            if parOp == .quo {
                str = str.replacingOccurrences(of: "\\\"", with: "\"")
            }
        }
        return (op, rep, str)
    }


    /// Attach a closure to detect a match at beginning of parStr.sub(string)
    ///
    /// - Parameter str: space delimited sequence
    /// - Parameter matchStr: closure to compare substring
    ///
    public func setMatch(_ str: String, _ matchStr: @escaping MatchStr) {
        
        print("\"\(str)\"  ⟹  ", terminator: "")

        if let parItem = findMatch(ParStr(str)).parLast {

            //print(parItem.makeScript())
            
            if let foundParItem = parItem.lastNode(),
                let foundNode = foundParItem.node {
                
                print("\(foundNode.nodeStrId()) = \(String(describing: matchStr))")
                foundNode.matchStr = matchStr
            }
        } else {
            print("⁉️ setMatch couldn't find: \(str)")
        }
    }
    
    public func go(_ parStr: ParStr, _ nodeValCall: @escaping ParItemVoid) {
        if let parItem = findMatch(parStr).parLast {
            nodeValCall(parItem)
        } else {
            print("⁉️ \(#function)(\"\(parStr.str)\") not found")
        }
    }
}

