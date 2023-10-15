//  Par.par.h
//  created by musesum on 6/22/17.

// this is not parsed, describes Par.par in the Par.swift file
par ≈ name "≈" right sub? end {
    name ≈ '^[A-Za-z_]\w*'

    right ≈ (or | and | parens)+ {
        or ≈ and ("|" and)+
        and ≈ (match | path | quote | regex) reps? {
                match ≈ '^([A-Za-z_]\w*)\(\)'
                path ≈ '^[A-Za-z_][A-Za-z0-9_.]*'
                quote ≈ '^\"([^\"]*)\"' // skip  \"
                regex ≈ '^([i_]*\'[^\']+)'
        }
        parens ≈ "(" right ")" reps
        reps ≈ '^([\~]?([\?\+\*]|\{],]?\d+[,]?\d*\})[\~]?)'
    }
    sub ≈ "{" end par "}" end?
    end ≈ '[ \\n\\t,]*'
}

