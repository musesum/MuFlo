#current
flo := (path | name) (dot | base | exprs | branch | embed | comment)* {
    path := '(\w*[.º˚*]+[\w.º˚*]*)'
    name := '(?!\d)\w+'
    base := ":" (path | name)
    exprs := "(" (edge | value)+ ")" {
        value := (name scalar | scalar | name exprOp | exprOp | name | quote | comment)+ {
            scalar := (range | num) (dflt | now)* {
                range := num rangeOp num
                dflt := "~" num
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
    dot     := "." name exprs? dot?
    branch  := "{" comment* flo+ "}" graft*
    graft   := "." branch
    embed   := '^\{\{(.*?)\}\}'
    comment := '(,+|//\s*(.*?)$|\/\*+(.*?)\*+\/)'
}
# a { b(0) { // bb
b.c (1) } }
flo { name("a") ⫶ branch.flo { name("b") ⫶ exprs.value.scalar.num("0") ⫶ branch { comment("// bb ") ⫶ flo { path("b.c") ⫶ exprs.value.scalar.num("1") } } } }

expect ⟹ a ⁉️{ b(0) { // bb
    b.c (1) } }
actual ⟹ a⁉️.b(0) { // bb
    b.c(1) }
──────────────────────────────


# a { b(0) // bb
b.c (1) }
flo { name("a") ⫶ branch.flo { name("b") ⫶ exprs.value.scalar.num("0") ⫶ comment("// bb ") ⫶ path("b.c") ⫶ exprs.value.scalar.num("1") } }
bindRoot
bindPathName    √.a { b(0) // bb b.c(1) }
    bindTopDown     √.a.b(0) { // bb
        c(1) }
    bindHashFlo     √.a.b(0) { // bb
        c(1) }
    bindVals        √.a.b(0) { // bb
        c(1) }
    bindEdges       √.a.b(0) { // bb
        c(1) }
    ⁉️ mismatch
    expect ⟹ a ⁉️{ b(0) // bb
        b.c (1) }
    actual ⟹ a⁉️.b(0) { // bb
        c(1) }
