// created by musesum on 1/6/25

import Foundation

enum TokenType: String {
    case name
    case rule
    case quote
    case regex
    case boolean
    case repeats
}

struct Token {
    let type: TokenType
    let value: String
    init(_ type: TokenType, _ value: String) {
        self.type = type
        self.value = value
    }
}
let parDef =
    #"""
    par     := name ":=" right sub? _end
    right   := (or | and | parens)+
    or      := and ("|" and)+
    and     := (match | path | quote | regex) repeats?
    parens  := "(" right ")" repeats
    sub     := "{" _end par "}" _end?
    name    := '^[A-Za-z_]\w*'
    repeats := '^([\~]?([\?\+\*]|\{],]?\d+[,]?\d*\})[\~]?)'
    match   := '^([A-Za-z_]\w*)\(\)'
    path    := '^[A-Za-z_][A-Za-z0-9_.]*'
    quote   := '^\"([^\"]*)\"'
    regex   := '^([i_]*\'[^\']+)'
    _end    := '[ \n\t,]*'
    """#
func tokenize(_ input: String) -> [Token] {
    // 1. Define the combined regex pattern with named groups
    let pattern = """
    (?<name>\\w+)
    |(?<rule>\\:=)
    |(?<quote>\\"[^"]*\\")
    |(?<regex>[i_]*'[^']+)
    |(?<boolean>[()|])
    |(?<repeats>[+*?])
    """

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return []
    }

    let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
    let matches = regex.matches(in: input, options: [], range: nsRange)

    var tokens = [Token]()

    let keys = ["name","rule","quote","regex","boolean","repeats"]
    for match in matches {
        for key in keys {
            if let range = Range(match.range(withName: key), in: input),
               range.lowerBound != range.upperBound,
               let type = TokenType(rawValue: key) {

                let value = String(input[range])
                let token = Token(type, value)
                tokens.append(token)
            }
        }
    }
    return tokens
}
