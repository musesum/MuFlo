
a: 1 ( b:2, c:3, d: b+c << e ) e @ a

a(1) (b(2) c(3) d(b+c)<<e)



 a: b: 1     🚫     <=  a.b: 1
 a (b: 1)            =>  a.b: 1
 a(b c).d            =>  a(b:d, c:d)
 a(b c).(d e)        =>  a( b ( d e ) c (d e))
 a(b c).(1)          =>  a(b:1, c:1)
 a(1).b(2)           => a:1 (b:2)

 a(1).b(2).c(3)      =>  a:1 (b:2 (c:3))
 =>  a 1 ( b 2 (c 3)) 🚫

 a(b c).(d e).(1)   =>  a ( b ( d(1) e(1) ) c ( d(1) e(1) ) ) 🚫
 =>  a ( b ( d:1, e:1 ), c ( d:1, e:1 ) )
 a(x:y) << b(x:c, y:d)
 a(x+y) << b(x:c, y:d)
 a(s:x+y) << b(x:c, y:d)
 a.s:x+y, a<< b(x:c, y:d)



 a(0…2~0=1)

 a(x(1) y(2))
 a(x:1, y:2)

 a(0…1~0=1)

 b(x/2) a<<b(x/2)

 m(1, 2, 3), n>>m(4, 5, 6)

 a(b,2,3

a(0…1~0=1)
a(0…1~0)

cell.one(1).two(2).three(3)

a(0…1~0=1)

b(0…1)

c(0…1=1)

a(1) b >> a(2)

a("b")

a.b c@a
a (b) c@a (b)

b(x/2) a << b(x/2)

a b << a(* 10)

a (x=1, y=2)

m (1, 2, 3), n >> m(4, 5, 6)

a ( b c ) a.*( d )

a (b c) a.*(d(0…1) >> a˚on(0))
a (b (d(0…1) >> a˚on(0))
   c (d(0…1) >> a˚on(0)))

a (b c) a˚.( d(0…1) >> a˚.on(0))
a (b(d(0…1) >> a˚.on(0))
   c(d(0…1) >> a˚.on(0)))

i(0…1~0.5, 0…1~0.5, 0…1~0.5)

a (b(c(1))) a.b.c(2)
a (b(c(1))) z@a (b(c(2)))        [.parens]
a (b(c:1))  z@a (b(c:2))         [.colons]

a (b(c:1)) a.b.c(2)
a (b(c(1))) z@a (b(c(2)))       [.parens]
a (b(c:1))  z@a (b(c:2))        [.colons]

a.b.c(0…1) z@a b.c(0…1~1)
a   (b.c:0…1  )                [.compact, .colon]
z@a (b.c:0…1~1)

a   ( b ( c(0…1  ) ) )
z@a ( b ( c(0…1~1) ) )

a (b c).(d e).(f g).(h i) z >> a.b˚g.   [.expand]
a (b(d(f(h i) g(h i)) e(f(h i) g(h i)))
   c(d(f(h i) g(h i)) e(f(h i) g(h i))))
z >> (a.b.d.g.h, a.b.e.g.h)

a (b(d(f(h i) g(h,i)) e(f(h,i) g(h,i)))  [.def, .comma]
   c(d(f(h i) g(h,i)) e(f(h,i) g(h,i))))
z >> a.b˚g

a (b c).(d e f>>b(1) ) z@a z.b.f⟡→c(1)
a    ( b ( d e f>>a.b(1) ) c ( d e f>>a.b(1) ) )
z@a  ( b ( d e f⟡→z.c(1) ) c ( d e f>>z.b(1) )

a._c   ( d ( e ( f ("ff") ) ) ) a.c.z @ _c ( d ( e.f   ("ZZ") ) )
a ( _c ( d ( e ( f ("ff") ) ) ) c ( z @ _c ( d ( e ( f ("ZZ") ) ) ) ) )

a.b ( _c ( d e.f(0…1) g) z @ _c ( g ) )
a ( b ( _c ( d e ( f(0…1) ) g ) z @ _c ( d e ( f(0…1) ) g ) ) )

a.b._c (d(1)) a.b.e@_c
a ( b ( _c ( d(1) ) e@_c ( d(1) ) ) )

a b >> a(1)

a << (b c)

a.b ( c d ) a.e@a.b ( f g )
a ( b ( c d ) e@a.b ( c d f g ) )

a ( b c ) d@a ( e f ) g@d ( h i ) j@g ( k l )
a ( b c ) d@a ( b c e f ) g@d ( b c e f h i ) j@g ( b c e f h i k l )

a ( b c ) h@a ( i j )
a ( b c ) h@a ( b c i j )

a ( b c ) \n h@a ( i j )
a ( b c ) h@a ( b c i j )
)))

body {left right}
    .{shoulder.elbow.wrist
        {thumb index middle ring pinky}
        .{meta prox dist }
        hip.knee.ankle.toes}
˚˚ <> .. // nervous system
˚˚ {pos(x 0…1, y 0…1, z 0…1)
    angle(roll %360, pitch %360, yaw %360)
    mm(0…3000)})
