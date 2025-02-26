// created by musesum on 2/14/25


flo := (path | name) (base | exprs | branch | embed | comment)* {
    path := '(\w*[.º˚*]+[\w.º˚*]*)'
    name := '(?!\d)\w+'
    base := ":" (path | name)
    exprs := "(" (edge | value)+ ")" {
        value := (name scalar | scalar | name exprOp | exprOp | name | quote | comment)+ {
            scalar := (thru | thri | mod | now | num) {
                thru := num ("..." | "…") num dflt? now?
                thri := num ("_") num dflt? now?
                mod  := "%" num dflt? now?
                dflt := "~" num
                now  := "=" num
            }
            exprOp := '(in|<=|>=|==|<[^>\-:!]|>|[*=/%,+-,])'
            quote := '"([^"]*)"'
            num := '([+-]*\d*\.?\d+(e[+-]?\d+)?)'
        }
        edge := edgeOp (edgePar | edgeVal) {
            edgeOp := '(\^-|<-|->|<>|<:>|:>|<:|<!>|<!|!>)'
            edgePar := "(" (edgeVal comment*)+ ")"
            edgeVal := (path | name | edge | exprs)+
        }
    }
    branch  := ("{" comment* flo+ "}" graft* | onedot flo) 
    graft   := onedot branch
    embed   := '^\{\{(.*?)\}\}'
    comment := '(,+|//\s*(.*?)$|\/\*+(.*?)\*+\/)'
    onedot  := '\.(?!\.)'
}