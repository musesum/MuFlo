? definition
! expression

note {
    octave(num / 12)
    scale(num % 12)
    key♯  (c c♯ d d♯ e f f♯ g g♯ a a♯ b)
    key♭  (c d♭ d e♭ e f g♭ g a♭ a b♭ b)
    major (0    2    2 1    2    2    2)
    _145  (0           5    7          )

}


a { b c }.{ d e f } ?
a { b { d e f } c { d e f } }

a / { d e f } ?
a { b c }

z:a ?
z { b c } a { b c }
z.b(1) == z { b(1) c }
=== z { b(1) c } a { b c }
a * { d e f } == a { b { d e f } c { d e f } }
=== a { b { d e f } c { d e f } } z { b(1) c }
a - * == a { } === a { } z { b(1) c }
z - * == z { } === z { } a { }

a{b c}.{d ( 1, <- b, -> e)
        e ( 2, <- c, -> d) }

a { b { d (1, <- b, -> e)
        e (2, <- c, -> d) }
    c { d (1, <- b, -> e)
        e (2, <- c, -> d) } }

a{ b c }.{ d (1, in b, out e)
           e (2, in c, out d) }

a { b { d (1, in b, out e)
        e (2, in c, out d) }
    c { d (1, in b, out e)
        e (2, in c, out d) } }

⟹ // prompt, results are indented

⟹ a.b 8 !? // pass 8 to a.b to 8, acivate verbose
    a.b (8) -> a.b.d (8) // out to a.b.d
    a.b.d (8) -> a.b.e (8) // out to a.b.e
    a.b.e (8) -> a.b.d (8) // blocked re-visit
    a.c.d (8) <- a.b (8) // from a.b
    a.c.d (8) -> a.c.e (8) // out to a.c.e
    a.c.e (8) -> a.c.d (.) // blocked re-visit

⟹ a? // list a

    a { b(8) { d(8, <- b, -> e)
               e(8, <- c, -> d) }
        c    { d(8, <- b, -> e)
               e(8, <- c, -> d) } }

⟹ a.c 9 ! // pass 9 to a.c to 8, acivate quietly

⟹ a? // list a again

   a { b(8) { d(9, <- b,-> e)
              e(9, <- c,-> d) }
       c(9) { d(9, <- b,-> e)
              e(9, <- c,-> d) } }

⟹ a˚. <==> ! // reduce a leaves to sync

   a{b c}.{d(1, <> a.*)
           e(2, <> a.*) }

⟹ a˚˚  <==> !? // reduce everything to sync

    a {b c}.{d(1) e(2)} a˚.(<> a.*)

⟹ p { q r }.{s t}

    p { q {s t} r {s t} }

⟹ p -> q(1) -> s(2) -> r(3) -> t(4)

    p(-> q) { q(-> s) { s(-> r) t } r(->t) { s t } }

