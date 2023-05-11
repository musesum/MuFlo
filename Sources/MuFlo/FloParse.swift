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

            dispatchFunc(parseTree, from: ["child", "many", "copyat"])

            dispatchFunc(parseValue, from: ["data",
                                            "scalar1", "thru", "thri",
                                            "modu", "dflt", "now", "num",
                                            "quote", "embed", "expr"])

            dispatchFunc(parseEdge, from: ["edges", "edgeOp",
                                           "ternIf", "ternThen", "ternElse",
                                           "ternRadio","ternCompare"])

            dispatchFunc(parseExprs, from: ["exprs"])
        }
    }

    // MARK: - names paths comments

    ///  Dispatched: parse lvalue name, paths to Flo, FloEdges, but not Exprs
    ///
    ///  - Parameters:
    ///      - flo:     current Flo
    ///      - prior:   prior keyword
    ///      - par: node in parse graph
    ///      - level:   Level depth
    ///
    ///
    ///   a, b, c, d, e, f.g but not x y in
    ///
    ///      a { b << (c ? d : e) } f.g(x y)
    ///
    func parseNamePath(_ flo: Flo,
                       _ prior: String,
                       _ par: ParItem,
                       _ level: Int) -> Flo {

        switch prior {

            case "edges", "ternIf", "ternThen", "ternElse", "ternRadio", "ternCompare":

                flo.edgeDefs.lastEdgeDef().addPath(par)

            case "copyat":

                flo.addChild(par, .copyat)

            case "expr":
                if let edgeDef = flo.edgeDefs.edgeDefs.last,
                   let edgePath = edgeDef.pathVals.pathVal.keys.last,
                   let edgeVal = edgeDef.pathVals.pathVal[edgePath] as? FloValExprs {

                    parseNextExpr(flo, edgeVal, par, prior)
                }
                else if let floVal = flo.val as? FloValExprs {

                    parseNextExpr(flo, floVal, par, prior)
                }

            default:
                let pattern = par.node?.pattern
                switch pattern {
                    case "comment": flo.comments.addComment(flo, par, prior)
                    case "name": return flo.addChild(par, .name)
                    case "path": return flo.addChild(par, .path)
                    default: break
                }
        }
        return flo
    }



    /// Dispatched: Parse a comment or comma (which is a micro comment)
    ///
    func parseComment(_ flo: Flo,
                      _ prior: String,
                      _ par: ParItem,
                      _ level: Int) -> Flo {

        if par.node?.pattern == "comment" {
            flo.comments.addComment(flo, par, prior)
        }
        return flo
    }

    // MARK: - values

    ///
    /// decorate current value with attributes
    ///
    func parseDeepVal(_ flo: Flo,
                      _ val: FloVal?,
                      _ par: ParItem)  {

        let pattern = par.node?.pattern ?? ""

        switch val {
            case let val as FloValScalar: parseDeepScalar(val, par)
            case let val as FloValExprs:     parseNextExpr(flo, val, par, pattern)
            case let val as FloValTern:   parseTernary(flo, val, par, pattern)
            default: break
        }
    }

    /// parse Ternary
    ///
    func parseTernary(_ flo: Flo,
                      _ val: FloValTern,
                      _ par: ParItem,
                      _ pattern: String)  {
        switch pattern {

            case "scalar1":
                let scalar = FloValScalar(flo, "scalar1")
                val.deepAddVal(scalar)
                parseDeepScalar(scalar, par)

            case "data":  val.deepAddVal(FloValData(flo,"data"))
            case "exprs": val.deepAddVal(FloValExprs(flo, "exprs"))
            default: parseDeepVal(flo, val.getVal(), par) // decorate deepest non tern value
        }
    }

    /// decorate current scalar with min, …, max, num, = dflt
    ///
    func parseDeepScalar(_ scalar: FloValScalar,
                         _ par: ParItem)  {

        let pattern = par.node?.pattern ?? ""

        switch pattern {
            case "thru": scalar.valOps += .thru
            case "thri": scalar.valOps += .thri
            case "modu": scalar.valOps += .modu
            case "num" : scalar.parseNum(par.getFirstDouble())
            case "dflt": scalar.parseDflt(par.getFirstDouble())
            case "now" : scalar.parseNow(par.getFirstDouble())
            default:     break
        }
        for nextPar in par.nextPars {
            parseDeepScalar(scalar, nextPar)
        }
    }

    /// parse next expression
    ///
    ///     exprs ~ "(" expr+ ("," expr+)* ")" {
    ///         expr ~ (exprOp | name | scalars | scalar1 | quote)
    ///         exprOp ~ '^(<=|>=|==|<|>|\*|\/|\+[ ]|\-[ ]|in)'
    ///     }
    ///
    func parseNextExpr(_ flo: Flo,
                       _ exprs: FloValExprs,
                       _ par: ParItem,
                       _ prior: String) {

        var hasOp = false
        var hasIn = false
        var scalar: FloValScalar?
        var name: String?

        for nextPar in par.nextPars {
            let pattern = nextPar.node?.pattern
            switch pattern {
                case ""        : addExprOp(nextPar)
                case "name"    : addName(nextPar)
                case "quote"   : addQuote(nextPar)
                case "scalar1" : addDeepScalar(nextPar)
                default        : break
            }
        }
        finishExpr()
        func finishExpr() {
            if hasIn, let name, let scalar {
                hasIn = false
                let copy = scalar.copy()
                exprs.nameAny[name] = copy
            }
        }
        func addDeepScalar(_ nextPar: ParItem) {
            scalar = FloValScalar(flo, name ?? "addDeepScalar")
            guard let scalar else { return }

            if hasOp {
                /// `c` in `a(b < c)` so don't add nameAny["c"]
                exprs.addScalar(scalar)
            } else {
                /// `b` in `a(b < c)` so add a nameAny["c"]
                exprs.addDeepScalar(scalar)
            }
            for deepPar in nextPar.nextPars {
                parseDeepScalar(scalar, deepPar)
            }
        }
        func addName(_ nextPar: ParItem)  {
            name = nextNextVal(nextPar)
            exprs.addName(name)
        }
        func addQuote(_ nextPar: ParItem)  {
            exprs.addQuote(nextNextVal(nextPar))
        }

        func addExprOp(_ nextPar: ParItem)  {

            let val = nextPar.value
            exprs.addOpStr(val)
            switch val {
                case ",":
                    finishExpr()
                    hasOp = false

                case "in":

                    hasOp = true
                    hasIn = true

                default:
                    hasOp = true
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
    func parseExprs(_ flo: Flo,
                    _ prior: String,
                    _ par: ParItem,
                    _ level: Int) -> Flo {
        switch prior {
            case "many",
                "child":

                flo.val = FloValExprs(flo, prior)
                
            case "edges":

                flo.edgeDefs.parseEdgeExprs(flo)

            default: print("🚫 unknown prior: \(prior)")
        }
        let pattern = par.node?.pattern ?? ""
        let nextFlo = parseNext(flo, pattern, par, level+1)
        return nextFlo
    }

    ///  Dispatched: Parse a FloVal
    ///
    ///  Will always parse `Flo.val` before a `Flo.edgeDef.val`.
    ///  So, check edgeDefs.last first.
    ///
    func parseValue(_ flo: Flo,
                    _ prior: String,
                    _ par: ParItem,
                    _ level: Int) -> Flo {

        let pattern = par.node?.pattern ?? ""

        if let edgeDef = flo.edgeDefs.edgeDefs.last {

            return parseEdgeDef(flo, edgeDef, par, level)

        } else if flo.val == nil {
            // nil in `a*_`
            switch pattern {
                case "embed"    : flo.val = FloValEmbed(flo, str: par.getFirstValue())
                case "scalar1"  : flo.val = FloValScalar(flo, pattern)
                case "data"     : flo.val = FloValData(flo, pattern)
                case "exprs"    : flo.val = FloValExprs(flo, pattern)
                default         : break
            }
        } else {
            // x y in `a(x y)`
            parseDeepVal(flo, flo.val, par)
            // keep prior while decorating Flo.val
            return flo
        }
        return parseNext(flo, pattern, par, level+1)
    }

    func parseEdgeDef(_ flo: Flo,
                      _ edgeDef: FloEdgeDef,
                      _ par: ParItem,
                      _ level: Int) -> Flo {

        let pattern = par.node?.pattern ?? ""
        // 9 in `a(8) <- (b ? 9)`
        if let path = edgeDef.pathVals.pathVal.keys.last {

            if let lastVal = edgeDef.pathVals.pathVal[path], lastVal != nil {
                parseDeepVal(flo, lastVal, par)
                return flo

            } else  {
                func addVal(_ val: FloVal) {
                    edgeDef.pathVals.add(path: path, val: val)
                }
                switch pattern {
                    case "embed"   : addVal(FloValEmbed(flo, str: par.getFirstValue()))
                    case "scalar1" : addVal(FloValScalar(flo, pattern))
                    case "data"    : addVal(FloValData(flo, pattern))
                    case "exprs"   : addVal(FloValExprs(flo, pattern))
                    case "ternIf"  : addVal(FloValTern(flo, level))
                    default        : break
                }
            }

        } else if let ternVal = edgeDef.ternVal {

            parseDeepVal(flo, ternVal, par)
        }
        return parseNext(flo, pattern, par, level+1)
    }
    // MARK: - Tree Graph

    /// Dispatched: add edges to Flo, set state of current TernaryEdge
    ///
    func parseEdge(_ flo: Flo,
                   _ prior: String,
                   _ par: ParItem,
                   _ level: Int) -> Flo {

        if let pattern = par.node?.pattern {

            switch pattern {
                case "edgeOp"      : flo.edgeDefs.addEdgeDef(par.getFirstValue())
                case "edges"       : flo.edgeDefs.addEdgeDef(par.getFirstValue())
                case "ternIf"      : flo.edgeDefs.addEdgeTernary(FloValTern(flo, level))
                case "ternThen"    : FloValTern.setTernState(.thenVal,  level)
                case "ternElse"    : FloValTern.setTernState(.elseVal,  level)
                case "ternRadio"   : FloValTern.setTernState(.radioVal, level)
                case "ternCompare" : FloValTern.setCompare(par.getFirstValue())
                default            : break
            }
            return parseNext(flo, pattern, par, level+1)
        }
        return flo
    }

    /// Dispatched: Parse ParItem into a tree
    ///
    func parseTree(_ flo: Flo,
                   _ prior: String,
                   _ par: ParItem,
                   _ level: Int) -> Flo {

        let pattern = par.node?.pattern ?? ""

        switch pattern {
            case "name"     : return flo.addChild(par, .name)
            case "path"     : return flo.addChild(par, .path)
            case "comment"  : flo.comments.addComment(flo, par, prior)
            default         : break
        }

        let parentFlo = pattern == "many" ? flo.makeMany() : flo
        var nextFlo = parentFlo

        for nextPar in par.nextPars {

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
    func parseNext(_ flo: Flo,
                   _ prior: String,
                   _ par: ParItem,
                   _ level: Int) -> Flo {

        for nextPar in par.nextPars {
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
    func dipatchParse(_ flo: Flo,
                      _ prior: String,
                      _ par: ParItem,
                      _ level: Int) -> Flo {

        // log(flo, par, level)  // log progress through parse, here

        if  let pattern = par.node?.pattern,
            let floParse = floKeywords[pattern] {

            return floParse(flo, prior, par, level+1)
        }
        // `^( < | <= | > | >= | == | *[ ] | \[ ] | +[ ] | -[ ] | \% | ,)`
        else if let value = par.value,
                let floParse = floKeywords[value] {
            
            return floParse(flo, prior, par, level+1)
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
    public func parseScript(_ root:     Flo,
                            _ script:   String,
                            whitespace: String = "\n\t ",
                            printGraph: Bool = false,
                            tracePar: Bool = false) -> Bool {

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
           let nowVal = now.val,
           let floVal = flo.val {

            floVal.setVal(nowVal, Visitor(0))
        }
        for child in now.children {
            mergeNow(child, with: root)
        }
    }

}
