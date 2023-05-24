flo ≈ pathName (exprs | child | many | copyat | edges | embed | comment)* {

    pathName ≈ (path | name)
    child    ≈ "{" comment* flo+ "}" | "." flo+
    many     ≈ "." "{" flo+ "}"
    copyat   ≈ "@" pathName ("," pathName)*

    exprs ≈ "(" expr+ ("," expr+)* ")" {
        expr   ≈ (exprOp | name | scalar | quote)
        exprOp ≈ '^(<=|>=|==|≈|<|>|\*|\:|\/|\%|in|\,)|(\+)|(\-)[ ]'

        scalar ≈ (thru | thri | modu | num) {
            thru ≈ num ("..." | "…") num dflt? now?
            thri ≈ num ("_") num dflt? now?
            modu ≈ "%" num dflt? now?
            dflt ≈ "~" num
            now  ≈ "=" num
        }
    }
    edges ≈ edgeOp (edgePar | exprs | edgeVal) comment* {
        edgeOp  ≈ '^([\^]|[<←][<!@⟐⟡◇→>]+|[!@⟐⟡◇→>]+[>→])'
        edgePar ≈ "(" edgeVal+ ")" edges?
        edgeVal ≈ pathName (edges+ | exprs)?
    }
    path    ≈ '^(([A-Za-z_][A-Za-z0-9_]*)?[.º˚*]+[A-Za-z0-9_.º˚*]*)'
    name    ≈ '^([A-Za-z_][A-Za-z0-9_]*)'
    quote   ≈ '^\"([^\"]*)\"'
    num     ≈ '^([+-]*([0-9]+[.][0-9]+|[.][0-9]+|[0-9]+[.](?![.])|[0-9]+)([e][+-][0-9]+)?)'
    comment ≈ '^([,]+|^[/]{2,}[ ]*(.*?)[\n\r\t]+|\/[*]+.*?\*\/)'
    embed   ≈ '^[{][{](?s)(.*?)[}][}]'
}

flo ≈ pathName (value | child | many | copyat | edges | embed | comment)* {

    child ≈ "{" comment* flo+ "}" | "." flo+
    many ≈ "." "{" flo+ "}"
    copyat ≈ "@" pathName ("," pathName)*

    value ≈ scalar | exprs
    scalar ≈ "(" scalar1 ")"
    scalar1 ≈ (thru | thri | modu | num) {
        thru ≈ num ("..." | "…") num dflt? now?
        thri ≈ num ("_") num dflt? now?
        modu ≈ "%" num dflt? now?
        dflt ≈ "=" num
        now ≈ ":" num
    }
    exprs ≈ "(" expr+ ("," expr+)* ")" {
        expr ≈ (exprOp | name | scalar1 | quote)
        exprOp ≈ '^(<=|>=|==|<|>|\*|_\/|\/|\%|\:|in|\,)|(\+)|(\-)[ ]'
    }
    edges ≈ edgeOp (edgePar | exprs | edgeItem) comment* {

        edgeOp ≈ '^([<←][<!~@⟐⟡◇→>]+|[!~@⟐⟡◇→>]+[>→])'
        edgePar ≈ "(" edgeItem+ ")" edges?
        edgeItem ≈ edgeVal comment*
        edgeVal ≈ pathName (edges+ | value)?
    }
    pathName ≈ (path | name)
    path ≈ '^(([A-Za-z_][A-Za-z0-9_]*)?[.º˚*]+[A-Za-z0-9_.º˚*]*)'
    name ≈ '^([A-Za-z_][A-Za-z0-9_]*)'
    quote ≈ '^\"([^\"]*)\"'
    num ≈ '^([+-]*([0-9]+[.][0-9]+|[.][0-9]+|[0-9]+[.](?![.])|[0-9]+)([e][+-][0-9]+)?)'
    comment ≈ '^([,]+|^[/]{2,}[ ]*(.*?)[\n\r\t]+|\/[*]+.*?\*\/)'
    compare ≈ '^[<>!=][=]?'
    embed ≈ '^[{][{](?s)(.*?)[}][}]'
}


flo ~ pathName  (exprs | edges | many | copyat | embed | comment)* {

    exprs ≈ (exParen | exColon ) {

        exParen ≈ "(" expr+ ("," expr+)* ")"
        exColon ≈ ":" expr+ (comment | comma | eol)
        expr   ≈ (exprOp | name ":"? | scalar | quote)
        exprOp ≈ '^(<=|>=|==|≈|<|>|\*|\/|\%|in|\,)|(\+)|(\-)[ ]'

        scalar ≈ (thru | thri | modu | num) {
            thru  ≈ num ("..." | "…") num dflt? now?
            thri  ≈ num ("_") num dflt? now?
            modu  ≈ "%" num dflt? now?
            dflt  ≈ "~" num
            now   ≈ "=" num
        }
    }
