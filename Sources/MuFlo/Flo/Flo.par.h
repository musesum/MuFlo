#current
flo := (path | name) (dot | base | exprs | branch | embed | comment)* {
    path := '(\w*[.º˚*]+[\w.º˚*]*)'
    name := '(?!\d)\w+'
    base := ":" (path | name)
    exprs := "(" (edge | value)+ ")" {
        value := (name scalar | scalar | name exprOp | exprOp | name | quote | comment)+ {
            scalar := (range | num) (origin | prior | empty | now)* {
                range := num rangeOp num
                origin := "~" num
                prior := "↻" num
                empty := "∅" num
                now  := ":" num
            }
            rangeOp := '(\.\.\.|…|_)'
            exprOp := '(in|<=|>=|==|<[^>\-:!]|>|[*:=/%,+-,])'
            quote := '"([^"]*)"'
            num := '([+-]*\d*\.?\d+(e[+-]?\d+)?)'
        }
        edge := edgeOp (edgePar | edgeVal) {
            edgeOp := '(\^-|<-|->|<>|<:>|:>|<:|<!>|<!|!>)'
            edgePar := "(" (edgeVal comment*)+ ")"
            edgeVal := (path | name | edge | exprs)+
        }
    }
    dot     := "." name exprs? dot? comment*
    branch  := "{" comment* flo+ "}" graft*
    graft   := "." branch
    embed   := '^\{\{(.*?)\}\}'
    comment := '(,+|//\s*(.*?)$|\/\*+(.*?)\*+\/)'
}
