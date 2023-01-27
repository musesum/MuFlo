flo ≈ left right* {

    left ≈ (path | name)
    right ≈ (value | child | many | copyat | array | edges | embed | comment)+

    child ≈ "{" comment* flo+ "}" | "." flo+
    many ≈ "." "{" flo+ "}"
    array ≈ "[" thru "]"
    copyat ≈ "@" (path | name) ("," (path | name))*

    value ≈ scalar | exprs
    value1 ≈ scalar1 | exprs

    scalar ≈ "(" scalar1 ")"
    scalars ≈ "(" scalar1 ("," scalar1)* ")"
    scalar1 ≈ (thru | modu | data | num) {
        thru ≈ num ("..." | "…") num dflt? now?
        modu ≈ "%" num dflt? now?
        index ≈ "[" (name | num) "]"
        data ≈ "*"
        dflt ≈ "=" num
        now ≈ ":" num
    }
    exprs ≈ "(" expr+ ("," expr+)* ")" {
        expr ≈ (exprOp | name | scalars | scalar1 | quote)
        exprOp ≈ '^(<=|>=|==|<|>|\*|_\/|\/|\%|\:|in|\,)|(\+)|(\-)[ ]'
    }
    edges ≈ edgeOp (edgePar | exprs | edgeItem) comment* {

        edgeOp ≈ '^([<←][<!~@⟐⟡◇→>]+|[!~@⟐⟡◇→>]+[>→])'
        edgePar ≈ "(" edgeItem+ ")" edges?
        edgeItem ≈ (edgeVal | ternary) comment*
        edgeVal ≈ (path | name) (edges+ | value)?

        ternary ≈ "(" tern ")" | tern {
            tern ≈ ternIf ternThen ternElse? ternRadio?
            ternIf ≈ (path | name) ternCompare?
            ternThen ≈ "?" (ternary | path | name | value1)
            ternElse ≈ ":" (ternary | path | name | value1)
            ternCompare ≈ compare (path | name | value1)
            ternRadio ≈ "|" ternary
        }
    }

    path ≈ '^(([A-Za-z_][A-Za-z0-9_]*)?[.º˚*]+[A-Za-z0-9_.º˚*]*)'
    name ≈ '^([A-Za-z_][A-Za-z0-9_]*)'
    quote ≈ '^\"([^\"]*)\"'
    num ≈ '^([+-]*([0-9]+[.][0-9]+|[.][0-9]+|[0-9]+[.](?![.])|[0-9]+)([e][+-][0-9]+)?)'
    comment ≈ '^([,]+|^[/]{2,}[ ]*(.*?)[\n\r\t]+|\/[*]+.*?\*\/)'
    compare ≈ '^[<>!=][=]?'
    embed ≈ '^[{][{](?s)(.*?)[}][}]'
}
