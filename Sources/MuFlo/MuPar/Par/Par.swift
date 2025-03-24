//  Par.Swift
//  created by musesum on 6/22/17.

import Foundation

/// Parse a script into a new graph, using static `Par.par` graph
public class Par {
    public static let shared = Par()
    public static var printParsin = false
    public static var traceParser = false
    public static var printParParTree = false
    public static var printParParDetail = false
    public static var printParParParsed = false


    public func parse(par: String) -> Parser? {
        return parse(script: par, "\t ")
    }

    public func parse(script: String,_ whitespace: String = "\t\n ") -> Parser? {
        let parsin = Parsin(script, whitespace) // parse in script

        if Par.printParParDetail { Par.par.printDetail() }
        if Par.printParParTree { Par.par.printTree() }
        if Par.printParsin { print(parsin.str.divider()) }

        if let parsed = Par.par.parseInput(parsin)?.parsed {

            if Par.printParParParsed { print(parsed.makeScript()) }

            let def = Parser(.def,"",.one)
            if let parser = parse(parser: def, parsed, 0) {
                parser.connectReferences(Visitor(0))
                parser.distillSuffixs(Visitor(0))
                return parser
            }
        }
        return nil

        func parse(parser: Parser, _ parsed: Parsed, _ level: Int) -> Parser? {

            if Par.traceParser {
                print("\n⦙ ".pad(level) + parser.makeScript(isLeft: false), terminator: ": ")
            }
            for subParsed in parsed.subParse {

                if Par.traceParser { print (subParsed.parser.pattern, terminator: " ") }

                switch subParsed.parser.pattern {
                case "par"    : addSub(.def,"", subParsed)
                case "or"     : addSub(.or, "", subParsed)
                case "and"    : addSub(.and,"", subParsed)
                case "right"  : addSub(.and,"", subParsed)
                case "parens" : addSub(.and,"", subParsed)
                case "name"   : addName(.and, subParsed)
                case "path"   : addLeaf(.and, subParsed)
                case "quote"  : addLeaf(.quote, subParsed)
                case "regex"  : addLeaf(.regx, subParsed)
                case "repeats": addReps(subParsed)
                default       : break
                }
            }
            return parser

            /// Apply list of sub parsers
            func addSub(_ type: ParType,_ pattern: String, _ subParsed: Parsed) {
                let patParser = Parser(type, pattern)
                if let subParser = parse(parser: patParser, subParsed, level+1) {
                    parser.subParsers.append(subParser)
                    subParser.uberParser = parser
                }
            }
            /// Apply name to super node
            func addName(_ type: ParType, _ subParsed: Parsed) {
                let pattern = subParsed.result ?? ""
                if Par.traceParser { print ("`" + pattern, terminator: "` ") }
                parser.isName = true
                parser.type = type
                parser.pattern = pattern
            }
            /// apply literal to current par
            func addLeaf(_ type: ParType,_ subParsed: Parsed) {
                let pattern = subParsed.result ?? ""
                if Par.traceParser { print(pattern, terminator: " ") }
                let addParser = Parser(type, pattern)
                parser.subParsers.append(addParser)
                addParser.uberParser = parser
            }
            /// Apply repeat `* ? +` to current node
            func addReps(_ subParsed: Parsed) {
                if let nextValue = subParsed.result {
                    parser.repeats.parse(nextValue)
                }
            }
        }
    }

    /// Explicitly declared parse graph, desciption of syntax in Par.par.h
    static let par =
    Parser(.def, "", .one, [
        Parser(.and, "par", .many, [
            Parser(.and, "name", .one, [
                Parser(.regx, #"^([A-Za-z_]\w*)"#)]),
            Parser(.quote, ":="),
            Parser(.or, "right", .many, [
                Parser(.and, "or", .one, [
                    Parser(.and, "and"),
                    Parser(.and,"",.many, [
                        Parser(.quote, "|"),
                        Parser(.and, "right")])]),
                Parser(.and,"and", .many, [
                    Parser(.or,"leaf", .one, [
                        Parser(.and, "path", .one, [ Parser(.regx,"^[A-Za-z_][A-Za-z0-9_.]*")]),
                        Parser(.and, "quote", .one, [ Parser(.regx, #"^\"([^\"]*)\""#)]),
                        Parser(.and, "regex", .one, [ Parser(.regx,"^'(.*)'$")])]),
                    Parser(.and, "repeats")]),
                Parser(.and, "parens", .one, [
                    Parser(.quote,"("),
                    Parser(.and, "right"),
                    Parser(.quote, ")"),
                    Parser(.and, "repeats")])]),
            Parser(.and, "sub", .opt, [
                Parser(.quote, "{"),
                Parser(.and, "_end"),
                Parser(.and, "par"),
                Parser(.quote, "}"),
                Parser(.and, "_end")
            ]),
            Parser(.and, "repeats", .opt, [ Parser(.regx, #"^([\~]?[\?\+\*]|\{\d+[,]?\d*\})"#)]), // ? + * {2,3}
            Parser(.and, "_end", .opt, [ Parser(.regx, #"^([ \n\t,;]*|[/][/][^\n]*)"#)])])])
}
