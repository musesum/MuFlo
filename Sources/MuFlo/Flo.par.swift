//
//  Flo.swift
//  Par
//
//  Created by warren on 11/14/17.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

// this it language definition for the Flo Script,
// which is read by the Par package to produce a parse Graph
// A prettier version of this string is in Flo.par.v2.h

public let FloPar =
#"""
flo ≈ pathName (exprs | child | many | copyat | edges | embed | comment)* {

    pathName ≈ (path | name)
    child    ≈ "{" comment* flo+ "}" | "." flo+
    many     ≈ "." "{" flo+ "}"
    copyat   ≈ "@" pathName ("," pathName)*

    exprs ≈ "(" expr+ ("," expr+)* ")" {
        expr   ≈ (exprOp | name | scalar | quote)
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
"""#
