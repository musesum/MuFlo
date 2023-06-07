flo ≈ pathName (exprs | child | many | copyat | edges | embed | comment)* {

    pathName ≈ (path | name)
    child    ≈ "{" comment* flo+ "}" | "." flo
    many     ≈ "." "{" flo+ "}"
    copyat   ≈ "@" pathName ("," pathName)*

    exprs ≈ "(" expr+ ")" {
        expr   ≈ (exprOp | name | scalar | quote | comment)+
        exprOp ≈ '^(<=|>=|==|≈|<|>|\*|\:|\/|\%|in|\,)|(\+)|(\-)[ ]'

        scalar ≈ (thru | thri | modu | now | num) {
            thru ≈ num ("..." | "…") num dflt? now?
            thri ≈ num ("_") num dflt? now?
            modu ≈ "%" num dflt? now?
            dflt ≈ "~" num
            now  ≈ "=" num
        }
    }
    edges ≈ edgeOp (edgePar | exprs | edgeVal) comment* {
        edgeOp  ≈ '^([\^]|[<←][<!@⟐⟡◇→>]+|[!@⟐⟡◇→>]+[>→])'
        edgePar ≈ "(" edgeItem+ ")" edges?
        edgeItem ≈ edgeVal comment*
        edgeVal ≈ pathName (edges+ | exprs)?
    }
    path    ≈ '^(([A-Za-z_][A-Za-z0-9_]*)?[.º˚*]+[A-Za-z0-9_.º˚*]*)'
    name    ≈ '^([A-Za-z_][A-Za-z0-9_]*)'
    quote   ≈ '^\"([^\"]*)\"'
    num     ≈ '^([+-]*([0-9]+[.][0-9]+|[.][0-9]+|[0-9]+[.](?![.])|[0-9]+)([e][+-][0-9]+)?)'
    comment ≈ '^([,]+|^[/]{2,}[ ]*(.*?)[\n\r\t]+|\/[*]+.*?\*\/)'
    embed   ≈ '^[{][{](?s)(.*?)[}][}]'
}


flo ≈ pathName (exprs | child | many | copyat | edges | embed | comment)* {

    pathName ≈ (path | name)
    child  ≈     "(" comment* flo+ ")" | "." flo
    many   ≈ "." "(" comment* flo+ ")"
    copyat ≈ "@" pathName ("," pathName)*

    exprs ≈ ("(" expr+ ")" | ":" expr+ exprEnd) {
        exprEnd  ≈ '!=([\,\)\n]'
        expr   ≈ (exprOp | name | scalar | quote | comment) {
            exprOp ≈ '^(<=|>=|==|≈|<|>|\*|\:|\/|\%|in|\,)|(\+)|(\-)[ ]'
            scalar ≈ (thru | thri | modu | num) {
                thru ≈ num ("..." | "…") num dflt? now?
                thri ≈ num ("_") num dflt? now?
                modu ≈ "%" num dflt? now?
                dflt ≈ "~" num
                now  ≈ "=" num
            }
            quote   ≈ '^\"([^\"]*)\"'
        }
    }

    edges ≈ edgeOp (edgePar | exprs | edgeVal) comment* {
        edgeOp  ≈ '^([\^]|[<←][<!@⟐⟡◇→>]+|[!@⟐⟡◇→>]+[>→])'
        edgePar ≈ "(" edgeItem+ ")" edges?
        edgeItem ≈ edgeVal comment*
        edgeVal ≈ pathName (edges+ | exprs)?
    }
    path    ≈ '^(([A-Za-z_][A-Za-z0-9_]*)?[.º˚*]+[A-Za-z0-9_.º˚*]*)'
    name    ≈ '^([A-Za-z_][A-Za-z0-9_]*)'
    num     ≈ '^([+-]*([0-9]+[.][0-9]+|[.][0-9]+|[0-9]+[.](?![.])|[0-9]+)([e][+-][0-9]+)?)'
    comment ≈ '^([,]+|^[/]{2,}[ ]*(.*?)[\n\r\t]+|\/[*]+.*?\*\/)'
    embed   ≈ '^[{][{](?s)(.*?)[}][}]'
}

