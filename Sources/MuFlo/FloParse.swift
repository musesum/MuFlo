//  FloParse.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar

public class FloParse {

    public static let shared = FloParse()
    private var rootParNode: ParNode
    private var floKeywords = [String: FloPriorParItem]()

    public init() {
        if let floRoot = Par.shared.parse(script: FloPar) {
            rootParNode = floRoot
            rootParNode.reps.repMax = Int.max
            makeParFlo()
        } else {
            rootParNode = ParNode("",[])
            print("🚫 Flo3Parse::init could not parse FloPar")
        }

        // make a dispatch dictionary of parsing closures
        func makeParFlo() {

            func dispatchFunc(_ fn: @escaping FloPriorParItem, from keywords: [String]) {
                for keyword in keywords { floKeywords[keyword] = fn }
            }
            dispatchFunc(parseNamePath, from: ["name", "path"])

            dispatchFunc(parseComment, from: ["comment"])

            dispatchFunc(parseTree, from: ["child", "many", "copyall", "copyat"])

            dispatchFunc(parseValue, from: ["scalar", "thru", "thri",
                                            "modu", "dflt", "now", "num",
                                            "quote", "expr"])

            dispatchFunc(parseEdge, from: ["edges", "edgeOp"])

            dispatchFunc(parseExprs, from: ["exprs"])
        }
    }

    // MARK: - names paths comments

    ///  Dispatched: parse lvalue name, paths to Flo, FloEdges, but not Exprs
    ///
    ///  - Parameters:
    ///      - flo     : current Flo
    ///      - prior   : prior keyword
    ///      - parItem : node in parse graph
    ///      - level   : Level depth
    ///
    ///
    ///   a, b, c, d, e, f.g but not x y in
    ///
    ///      a { b << (c ? d : e) } f.g(x y)
    ///
    func parseNamePath(_ flo     : Flo     ,
                       _ prior   : String  ,
                       _ parItem : ParItem ,
                       _ level   : Int     ) -> Flo {

        switch prior {

        case "edges":

            flo.edgeDefs.lastEdgeDef().addPath(parItem)

        case "copyall":

            flo.addChild(parItem, .copyall)

        case "copyat":

            flo.addChild(parItem, .copyat)

        case "expr":
            if let edgeDef = flo.edgeDefs.edgeDefs.last,
               let edgePath = edgeDef.pathVals.edgeExprs.keys.last,
               let edgeVal = edgeDef.pathVals.edgeExprs[edgePath],
               let edgeVal {

                parseNextExpr(flo, edgeVal, parItem, prior)
            }
            else if let val = flo.exprs {

                parseNextExpr(flo, val, parItem, prior)
            }

        default:
            let pattern = parItem.node?.pattern
            switch pattern {
            case "comment": flo.comments.addComment(flo, parItem, prior)
            case "name": return flo.addChild(parItem, .name)
            case "path": return flo.addChild(parItem, .path)
            default: break
            }
        }
        return flo
    }



    /// Dispatched: Parse a comment or comma (which is a micro comment)
    ///
    func parseComment(_ flo     : Flo     ,
                      _ prior   : String  ,
                      _ parItem : ParItem ,
                      _ level   : Int     ) -> Flo {

        if parItem.node?.pattern == "comment" {
            flo.comments.addComment(flo, parItem, prior)
        }
        return flo
    }

    // MARK: - values

    /// decorate current value with attributes
    ///
    func parseDeepVal(_ flo     : Flo     ,
                      _ floVal  : FloExprs? ,
                      _ parItem : ParItem ) {

        if let floVal,
           let pattern = parItem.node?.pattern {
            parseNextExpr(flo, floVal, parItem, pattern)
        }
    }

    /// decorate current scalar with min, …, max, num, dflt
    ///
    func parseDeepScalar(_ scalar  : FloValScalar,
                         _ parItem : ParItem,
                         _ parset  : FloParset)  {

        let pattern = parItem.node?.pattern ?? ""

        switch pattern {
        case "thru" : scalar.valOps += .thru // double range
        case "thri" : scalar.valOps += .thri // integer range
        case "modu" : scalar.valOps += .modu // modulo
        case "num"  : scalar.parseNum(parItem.getFirstDouble(),parset)
        case "dflt" : scalar.parseDflt(parItem.getFirstDouble())
        case "now"  : scalar.parseNow(parItem.getFirstDouble())
        default     : break
        }
        for nextPar in parItem.nextPars {
            parseDeepScalar(scalar, nextPar, parset)
        }
    }

    /// parse next expression
    ///
    /// exprs ≈ "(" expr+ ("," expr+)* ")" {
    ///     expr   ≈ (exprOp | name | scalar | quote)
    ///     exprOp ≈ '^(<=|>=|==|≈|<|>|\*|\/|\%|\:|=|in|\,)|(\+)|(\-)[ ]'
    ///
    func parseNextExpr(_ flo     : Flo         ,
                       _ exprs   : FloExprs ,
                       _ parItem : ParItem     ,
                       _ prior   : String      ) {

        var parset = FloParset()
        var scalar: FloValScalar?
        var name: String?

        for nextPar in parItem.nextPars {
            let pattern = nextPar.node?.pattern
            switch pattern {
            case ""       : addOpExpr(nextPar)
            case "name"   : addOpName(nextPar)
            case "quote"  : addOpQuote(nextPar)
            case "scalar" : addOpScalar(nextPar)
            default       : break
            }
        }
        finishExpr()

        func finishExpr() {
            scalar = nil
            name = nil
            parset.removeAll()
        }
        func addOpScalar(_ nextPar: ParItem) {

            if parset.isIn || parset.equal, let name {

                scalar = FloValScalar(flo, name)
                exprs.addDeepScalar(scalar)
            }
            else if parset.match {
                scalar = FloValScalar(flo, exprs.anonKey)
                exprs.addAnonScalar(scalar)

            } else {
                switch parset & [.name, .expr, .scalar] {
                case [],                        // 1 in a(1) or a(:1)
                    [.scalar],                  // 2 in a(1 2)
                    [.expr],                     // 3 in b(/3) or b(:/3)
                    [.expr, .scalar],           // 4 in e(/2+5) or e(2+5)
                    [.name, .expr, .scalar]:    // 5 in f(g:h/2+5) or f(x/2+5)
                    
                    scalar = FloValScalar(flo, exprs.anonKey)
                    exprs.addAnonScalar(scalar)
                    
                case [.name],                   // 6 in i(j:6) or i(j 6)
                    [.name, .expr]:             // t in k(m/7)
                    
                    if let name {
                        scalar = FloValScalar(flo, name)
                        exprs.addDeepScalar(scalar)
                    }
                    
                default:
                    print("⁉️ addOpScalar: uncaught parset: \(parset.description)")
                    break
                }
            }
            if let scalar {
                parset += .scalar
                for deepPar in nextPar.nextPars {
                    parseDeepScalar(scalar, deepPar, parset)
                }
            }
        }
        func addOpName(_ nextPar: ParItem)  {
            name = nextNextVal(nextPar)
            exprs.addOpName(name, parset.expr)
            parset += .name
        }
        func addOpQuote(_ nextPar: ParItem)  {
            exprs.addQuote(nextNextVal(nextPar))
            parset += .quote
        }

        func addOpExpr(_ nextPar: ParItem)  {

            guard let val = nextPar.value else { return }
            let op = FloOp(val)
            exprs.addOpStr(val)

            switch op {
            case .comma:            finishExpr()
            case .In:               parset += [.isIn]
            case .IS,.EQ:           parset += [.equal]
            case .LE,.GE,.LT,.GT:   parset += [.match]
            default:                parset += .expr
            }
        }
        func nextNextVal(_ nextPar: ParItem) -> String? {
            if let str = nextPar.nextPars.first?.value {
                return str
            } else {
                print("🚫 \(#function) unexpected value for \(nextPar.node?.pattern.description ?? "")")
            }
            return nil
        }
    }

    /// Dispatched: parse first expression in left value or edge
    ///
    func parseExprs(_ flo     : Flo     ,
                    _ prior   : String  ,
                    _ parItem : ParItem ,
                    _ level   : Int     ) -> Flo {
        switch prior {
        case "many",
            "child":

            flo.exprs = FloExprs(flo, prior)

        case "edges":

            flo.edgeDefs.parseEdgeExprs(flo)

        default: print("🚫 unknown prior: \(prior)")
        }
        let pattern = parItem.node?.pattern ?? ""
        let nextFlo = parseNext(flo, pattern, parItem, level+1)
        return nextFlo
    }

    ///  Dispatched: Parse a FloVal
    ///
    ///  Will always parse `Flo.val` before a `Flo.edgeDef.val`.
    ///  So, check edgeDefs.last first.
    ///
    func parseValue(_ flo     : Flo     ,
                    _ prior   : String  ,
                    _ parItem : ParItem ,
                    _ level   : Int     ) -> Flo {

        let pattern = parItem.node?.pattern ?? ""

        if let edgeDef = flo.edgeDefs.edgeDefs.last {

            return parseEdgeDef(flo, edgeDef, parItem, level)

        } else if flo.exprs == nil {

            flo.exprs = FloExprs(flo, pattern)

        } else {
            // x y in `a(x y)`
            parseDeepVal(flo, flo.exprs, parItem)
            // keep prior while decorating Flo.val
            return flo
        }
        return parseNext(flo, pattern, parItem, level+1)
    }

    func parseEdgeDef(_ flo     : Flo        ,
                      _ edgeDef : FloEdgeDef ,
                      _ parItem : ParItem    ,
                      _ level   : Int        ) -> Flo {

        let pattern = parItem.node?.pattern ?? ""
        /// `9` in `a(8) << b(9)`
        if let path = edgeDef.pathVals.edgeExprs.keys.last {

            if let lastVal = edgeDef.pathVals.edgeExprs[path], lastVal != nil {
                //print("flo:\(flo.name) id:\(flo.id) lastVal:\(lastVal!.name) id:\(lastVal!.id)")
                parseDeepVal(flo, lastVal, parItem)
                return flo

            } else  {
                let val = FloExprs(flo, pattern)
                edgeDef.pathVals.addPathVal(path, val)
            }
        } 
        return parseNext(flo, pattern, parItem, level+1)
    }
    // MARK: - Tree Graph

    /// Dispatched: add edges to Flo, set state of current TernaryEdge
    ///
    func parseEdge(_ flo     : Flo     ,
                   _ prior   : String  ,
                   _ parItem : ParItem ,
                   _ level   : Int     ) -> Flo {

        if let pattern = parItem.node?.pattern {

            switch pattern {
            case "edgeOp" : flo.edgeDefs.addEdgeDef(parItem.getFirstValue())
            case "edges"  : flo.edgeDefs.addEdgeDef(parItem.getFirstValue())
            default       : break
            }
            return parseNext(flo, pattern, parItem, level+1)
        }
        return flo
    }

    /// Dispatched: Parse ParItem into a tree
    ///
    func parseTree(_ flo     : Flo     ,
                   _ prior   : String  ,
                   _ parItem : ParItem ,
                   _ level   : Int     ) -> Flo {

        let pattern = parItem .node?.pattern ?? ""

        switch pattern {
        case "name"     : return flo.addChild(parItem , .name)
        case "path"     : return flo.addChild(parItem , .path)
        case "comment"  : flo.comments.addComment(flo, parItem , prior)
        default         : break
        }

        let parentFlo = pattern == "many" ? flo.makeMany() : flo
        var nextFlo = parentFlo

        for nextPar in parItem .nextPars {

            switch  nextPar.node?.pattern  {

            case "child", "many":
                // push child of most recent name'd sibling to the next level
                self.dipatchParse(nextFlo, pattern, nextPar, level+1)

            case "name", "path":
                // add new named sibling to parent
                nextFlo = self.dipatchParse(parentFlo, pattern, nextPar, level+1)

            default:
                // decorate current sibling with new values
                nextFlo = self.dipatchParse(nextFlo, pattern, nextPar, level+1)
            }
        }
        return nextFlo
    }

    // MARK: - script

    ///  decorate current flo with additional attributes
    ///
    func parseNext(_ flo     : Flo     ,
                   _ prior   : String  ,
                   _ parItem : ParItem ,
                   _ level   : Int     ) -> Flo {

        for nextPar in parItem.nextPars {
            self.dipatchParse(flo, prior, nextPar, level+1)
        }
        return flo
    }

    ///  Dispatch floParse closure based on `pattern`
    ///
    /// find corresponding floParse dispatch to either
    ///     - parseNamePath
    ///     - parseValue
    ///     - parseEdge
    ///
    @discardableResult
    func dipatchParse(_ flo     : Flo     ,
                      _ prior   : String  ,
                      _ parItem : ParItem ,
                      _ level   : Int     ) -> Flo {

        // log(flo, par, level)  // log progress through parse, here

        if  let pattern = parItem.node?.pattern,
            let floParse = floKeywords[pattern] {

            return floParse(flo, prior, parItem, level+1)
        }
        // `^( < | <= | > | >= | == | *[ ] | \[ ] | +[ ] | -[ ] | \% | ,)`
        else if let value = parItem.value,
                let floParse = floKeywords[value] {
            
            return floParse(flo, prior, parItem, level+1)
        }
        return flo
    }

    ///  Parse script, starting from  root, deliminted by whitespace
    ///
    /// - Parameters:
    ///     - root: starting node from which to attach subtree
    ///     - script: text of script to convert into subtree
    ///     - whitespace: default is single line, may add \n for multiline script
    ///
    public func parseScript(_ root     : Flo,
                            _ script   : String,
                            whitespace : String = "\n\t ",
                            printGraph : Bool = false,
                            tracePar   : Bool = false) -> Bool {

        ParStr.tracing = tracePar
        Flo.LogBindScript = false
        Flo.LogMakeScript = false

        let parStr = ParStr(script)
        parStr.whitespace = whitespace

        if let par = rootParNode.findMatch(parStr, 0).parLast {

            if printGraph {
                rootParNode.printGraph(Visitor(0))
            }
            // reduce to keywords in floKeywords and print
            let reduce1 = par.reduceStart(floKeywords)
            dipatchParse(root, "", reduce1, 0)
            root.bindRoot()

            return true
        }
        return false
    }

    public func mergeScript(_ root: Flo,
                            _ script: String) -> Bool {

        let rootNow = Flo("√")
        let success = parseScript(rootNow, script)
        if success {
            mergeNow(rootNow, with: root)
        }
        return success
    }

    func mergeNow(_ now: Flo, with root: Flo) {
        let nowHash = now.hash
        if let dispatch = root.dispatch?.dispatch,
           let (flo,_) = dispatch[nowHash],
           let nowVal = now.exprs,
           let floVal = flo.exprs {

            floVal.setExprsVal(nowVal, Visitor(0))
        }
        for child in now.children {
            mergeNow(child, with: root)
        }
    }

}
