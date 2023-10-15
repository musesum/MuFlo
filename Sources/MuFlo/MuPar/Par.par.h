//  Par.par.h
//  created by musesum on 6/22/17.

// this is not parsed, describes Par.par in the Par.swift file
par+: name reps ":" right sub _end {
    name: '^[A-Za-z_]\w*'
    reps?: '^([\~]?([\?\+\*]|\{],]?\d+[,]?\d*\})[\~]?)'
    
    right+|: (or | and | parens)+  {
        or: and ("|" and)+

        and+: leaf reps {
            leaf| {
                match: '^([A-Za-z_]\w*)\(\)'
                path: '^[A-Za-z_][A-Za-z0-9_.]*'
                quote: '^\"([^\"]*)\"' // skip  \"
                regex: '^([i_]*\'[^\']+)'
            }
        }
        parens?: "(" right ")" reps
    }
    sub?: "{" _end par "}" _end {
        _end?: '[ \\n\\t,]*'
    }
}
