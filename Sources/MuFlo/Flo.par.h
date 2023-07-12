flo ≈ pathName (exprs | child | many | copyall | copyat | edges | embed | comment)* {

    pathName ≈ (path | name)
    child    ≈ "{" comment* flo+ "}" | "." flo
    many     ≈ "." "{" flo+ "}"
    copyall  ≈ "©" pathName ("," pathName)*
    copyat   ≈ "@" pathName ("," pathName)*

    exprs ≈ "(" expr+ ")" {
        expr   ≈ (scalar | exprOp | name | quote | comment)+
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
        edgeOp  ≈ '^([\^]|[<][<!@\©⟐⟡◇>]+|[!@⟐⟡◇>]+[>])'
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
