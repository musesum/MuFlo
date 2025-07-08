//  FloParse.swift
//  created by musesum on 3/10/19.

import Foundation

public struct FloParOps: OptionSet, Sendable {
    public let rawValue: Int

    static let printParsedAll    = FloParOps(rawValue: 1 << 0)
    static let printParsedTokens = FloParOps(rawValue: 1 << 1)
    static let logBindChildren   = FloParOps(rawValue: 1 << 2)
    static let logParsing        = FloParOps(rawValue: 1 << 3)
    static let logDefaults       = FloParOps(rawValue: 1 << 4)
    static let logBind           = FloParOps(rawValue: 1 << 5)

    var printParsedAll    : Bool { get { contains(.printParsedAll   )}}
    var printParsedTokens : Bool { get { contains(.printParsedTokens)}}
    var logBindChildren   : Bool { get { contains(.logBindChildren  )}}
    var logParsing        : Bool { get { contains(.logParsing       )}}
    var logDefaults       : Bool { get { contains(.logDefaults      )}}
    var logBind           : Bool { get { contains(.logBind          )}}
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public class FloParse {

    internal var floParser: Parser
    var ops: FloParOps
    var par = Par()

    public init(_ ops: FloParOps = []) {
        self.ops = ops
        // parse the Flo.par quasi-BNF definition for Flo scripts
        if let floParser = par.parse(par: FloPar) {
            if floParser.subParsers.isEmpty {
                err("floParser.subParsers.isEmpty")
            }
            floParser.repeats.repMax = Int.max
            self.floParser = floParser
        } else {
            floParser = Parser(.def,"")
            err("could not parse FloPar")
        }
        func err(_ msg: String) {
            PrintLog("⁉️ FloParse::init \(msg)")
        }
    }
    @discardableResult
    public func parseRoot(_ root: Flo,
                          _ script: String,
                          _ nextFrame: NextFrame? = nil,
                          parOps: ParOps = []) -> Bool {
        par.ops = parOps
        // parse the script.flo.h
        let parsin = Parsin(script)
        if let parsed = floParser.parseInput(parsin, 0)?.parsed {

            parsed.reduce()
            if ops.printParsedAll    { parsed.printAll() }
            if ops.printParsedTokens { parsed.printTokens() }

            parseFlo(root, parsed, 0)
            bindRoot(root, nextFrame, FloScriptOps.All)
            return true
        }
        return false
    }

    func parseFlo(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {

        for sub in parsed.subParse {
            let pattern = sub.parser.pattern
            switch pattern {
            case "name"    : flo.addChild(sub, .name)
            case "path"    : flo.addChild(sub, .path)
            case "exprs"   : parseExprs(flo.youngest, sub, level+1)
            case "dot"     : parseDot(flo.youngest, sub, level+1)
            case "branch"  : parseBranch(flo.youngest, sub, level+1)
            case "base"    : parseBase(flo.youngest, sub, level+1)
            case "embed"   : parseEmbed(flo, sub, level+1)
            case "comment" : flo.youngest.addComment(.branch, sub.nextResult)
            default        : logDefault(#function, sub)
            }
        }

        func parseBase(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            /// `:a` in  `a { b c } d:a`
            for sub in parsed.subParse {
                let pattern = sub.parser.pattern
                switch pattern {
                case "name" : flo.makeBase(sub.nextResult)
                case "path" : flo.makeBase(sub.nextResult)
                default     : logDefault(#function, sub)
                }
            }
        }
        func parseEmbed(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            //TODO
        }
    }

    func parseExprs(_ flo: Flo, _ parsed: Parsed, _ level: Int) {

        let exprs = flo.exprs ?? Exprs(flo)
        flo.exprs = exprs // maybe redundant

        for sub in parsed.subParse {
            switch sub.parser.pattern {
            case "edge"  : parseEdge(flo,exprs,sub,level+1)
            case "value" : parseValue(flo,exprs,sub,level+1)
            default      : logDefault(#function, sub)
            }
        }
    }

    func parseValue(_ flo: Flo, _ exprs: Exprs, _ parsed: Parsed, _ level: Int) {
        var name: String?
        var lastOp = EvalOp.none
        for parse in parsed.subParse {
            let pattern = parse.parser.pattern
            switch pattern {
            case "name"    : addName(parse)
            case "scalar"  : addScalar(parse)
            case "exprOp"  : addOp(parse)
            case "quote"   : exprs.addQuote(parse.nextResult)
            case "tooltip" : exprs.addTooltip(parse.nextResult)
            case "comment" : addComment(parse)
            default        : logDefault(#function, parse)
            }
        }
        func addOp(_ parsed: Parsed) {
            lastOp = exprs.addOpStr(parsed.nextResult)
            if lastOp == .comma {
                name = nil
            }
        }

        func addName(_ parsed: Parsed) {
            let hadName = name != nil
            name = parsed.nextResult
            exprs.addOpName(name, hadName)
        }
        func addComment(_ parsed: Parsed) {
            flo.addComment(.branch, parsed.nextResult)
            name = nil
        }

        func addScalar( _ parsed: Parsed) {

            let scalar = Scalar(flo, name ?? exprs.anonKey)
            exprs.addDeepScalar(scalar, name, lastOp)

            for parse in parsed.subParse {
                switch parse.parser.pattern {
                case "range"  : parseRange(parse) // double range
                case "num"    : scalar.parseNum(parse.firstDouble())
                case "origin" : scalar.parseOrigin(parse.firstDouble())
                case "now"    : scalar.parseNow(parse.firstDouble())
                default       : logDefault(#function, parse)
                }
            }
            func parseRange( _ parsed: Parsed) {
                for parse in parsed.subParse {
                    switch parse.parser.pattern {
                    case "num"     : scalar.parseRange(parse.firstDouble())
                    case "rangeOp" : addRangeOp(parse)
                    default        : logDefault(#function, parse)
                    }
                }
                func addRangeOp(_ parsed: Parsed) {
                    switch parsed.nextResult {
                    case "...", "…" : scalar.scalarOps.insert(.ranged)
                    case "_"        : scalar.scalarOps.insert(.rangei)
                    case "~"        : scalar.scalarOps.insert(.rangea)
                    default         : logDefault(#function, parsed)
                    }
                }
            }
        }
    }

    func parseEdge(_ flo: Flo, _ exprs: Exprs, _ parsed: Parsed, _ level: Int)  {
        for sub in parsed.subParse {
            let pattern = sub.parser.pattern
            switch pattern {
            case "edgeOp"  : parseEdgeOp(flo, sub, level+1)
            case "edgeVal" : parseEdgeVal(flo,sub,level+1)
            case "exprs"   : parseEdgeExprs(flo,sub,level+1)
            case "edgePar" : parseEdgePar(flo,sub,level+1)
            default        : logDefault(#function, sub)
            }
        }
        func parseEdgePar(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            for sub in parsed.subParse {
                let pattern = sub.parser.pattern
                switch pattern {
                case "edgeVal" : parseEdgeVal(flo,sub,level+1)
                case "comment" : flo.addComment(.edge, sub.nextResult)
                default        : logDefault(#function, sub)
                }
            }
        }
        func parseEdgeOp(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            for sub in parsed.subParse {
                if let result = sub.result {
                    flo.edgeDefs.addEdgeDef(result) // edgeVal
                }
            }
        }
        func parseEdgeVal(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            for sub in parsed.subParse {
                let pattern = sub.parser.pattern
                switch pattern {
                case "name"    : flo.edgeDefs.addPath(sub)
                case "path"    : flo.edgeDefs.addPath(sub)
                case "exprs"   : parseEdgeExprs(flo, sub, level+1)
                case "comment" : flo.addComment(.edge, sub.nextResult)
                default        : logDefault(#function, sub)
                }
            }
        }
        func parseEdgeExprs(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
            let exprs = Exprs(flo, parsed.parser.pattern)
            flo.edgeDefs.addExpress(exprs)
            for sub in parsed.subParse {
                let pattern = sub.parser.pattern
                switch pattern  {
                case "value" : parseValue(flo, exprs, sub, level+1)
                default      : logDefault(#function, sub)
                }
            }
        }
    }

    func parseDot(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
        /// `{` in  `a { b c }`
        for sub in parsed.subParse {
            let pattern = sub.parser.pattern
            switch pattern {
            case "name"    : flo.addChild(sub, .name)
            case "exprs"   : parseExprs(flo.youngest, sub, level+1)
            case "dot"     : parseDot(flo.youngest, sub, level+1)
            case "comment" : flo.youngest.addComment(.branch, sub.nextResult)
            default        : logDefault(#function, sub)
            }
        }
    }

    func parseBranch(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
        /// `{` in  `a { b c }`
        for sub in parsed.subParse {
            let pattern = sub.parser.pattern
            switch pattern {
            case "flo"     : parseFlo(flo, sub, level+1)
            case "graft"   : parseGraft(flo,sub, level+1)
            case "comment" : flo.addComment(.branch, sub.nextResult)
            case "onedot"  : continue
            default        : logDefault(#function, sub)
            }
        }
    }

    func parseGraft(_ flo: Flo, _ parsed: Parsed, _ level: Int)  {
        /// `.` in `a { b c }.{ d e }`

        let graft = flo.makeGraft()
        for sub in parsed.subParse {
            let pattern = sub.parser.pattern
            switch pattern {
            case "branch" : parseBranch(graft, sub, level+1)
            case "graft"  : parseGraft(graft, sub, level+1)
            case "onedot" : continue
            default       : logDefault(#function, sub)
            }
        }
        flo.graft(graft)
    }

    func bindRoot(_ root: Flo, _ nextFrame: NextFrame?, _ scriptOps: FloScriptOps = []) {
        if ops.logBind {  print("bindRoot     ") }
        step("bindPathName ") { root.bindPathName() }
        step("bindTopDown  ") { root.bindTopDown(self) }
        step("bindHashFlo  ") { root.bindHashFlo() }
        step("bindVals     ") { root.bindVals() }
        step("bindEdges    ") { root.bindEdges(nextFrame) }

        func step(_ msg: String, call: @escaping()->()) {
            if ops.logBind {
                print (msg + "   " + root.scriptFlo(scriptOps))
            }
            call()
        }
    }
}
