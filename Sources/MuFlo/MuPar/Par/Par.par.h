//  Par.par.h
//  created by musesum on 6/22/17.

// this is not parsed, describes Par.parser in the Par.swift file
par+: name repeats ":" right sub _end {
    name: '^[A-Za-z_]\w*'
    repeats?: '^([\~]?([\?\+\*]|\{],]?\d+[,]?\d*\})[\~]?)'
    
    right+|: (or | and | parens)+  {
        or: and ("|" and)+

        and+: leaf repeats {
            leaf| {
                match: '^([A-Za-z_]\w*)\(\)'
                path: '^[A-Za-z_][A-Za-z0-9_.]*'
                quote: '^\"([^\"]*)\"' // skip  \"
                regex: '^([i_]*\'[^\']+)'
            }
        }
        parens?: "(" right ")" repeats
    }
    sub?: "{" _end par "}" _end {
        _end?: '[ \\n\\t,]*'
    }
}

// conventional version of above
par     := name ":=" right sub? _end
right   := (or | and | parens)+
or      := and ("|" and)+
and     := (match | path | quote | regex) repeats?
parens  := "(" right ")" repeats
sub     := "{" _end par "}" _end?
name    := '^[A-Za-z_]\w*'
repeats := '^([\~]?([\?\+\*]|\{],]?\d+[,]?\d*\})[\~]?)'
match   := '^([A-Za-z_]\w*)\(\)'
path    := '^[A-Za-z_][A-Za-z0-9_.]*'
quote   := '^\"([^\"]*)\"'
regex   := '^([i_]*\'[^\']+)'
_end    := '[ \n\t,]*'


token :=
(  \w+            #  name
 | \:\=           #  rule
 | "(?:[^"]*)"    #  quote 
 | [i_]*'[^']+'   #  regex
 | [()|]          #  boolean
 | [+\*\?]        #  repeats
)
