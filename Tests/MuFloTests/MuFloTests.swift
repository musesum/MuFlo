import CoreFoundation
import XCTest

@testable import MuFlo

final class MuFloTests: XCTestCase {

    var floParse = FloParse()
    var testErrors = 0
    var totalErrors = 0

    func testSession() { headline(#function)
        var err = 0
        err += test("a(1)")
        err += test("a(1)", nil, [.parens, .def, .now])
        XCTAssertEqual(err, 0)
    }
    func testDefaultValues() { headline(#function)
        let ops: ParOps = .printParsin
        var err = 0
        err += test("a (z : 1)", parOps: ops)
        err += test("a (z 0_127 : 1)", parOps: ops)
        err += test("w (x 0, y 0)", parOps: ops)
        err += test("b (0)", parOps: ops)
        err += test("c (d 0, e 0)", parOps: ops)
        XCTAssertEqual(err, 0)
    }
    func testEdgeSession() { headline(#function)
        var err = 0
        err += test("a(1) b(-> a(2))", nil, [.parens, .now, .edge])
        XCTAssertEqual(err, 0)
    }

    func testExpandPath() { headline(#function)
        var err = 0

        err += test("a {b {c}} a˚.{d e}", "a.b.c { d e }")
        err += test("a.b.c a˚.{d e}", "a.b.c { d e }")
        err += test("a.b.c  ˚.{d e}", "a.b.c { d e }")
        err += test("a.b.c {d e f}",  "a.b.c { d e f }")
        err += test("a.b.c.{d e f}",  "a.b.c { d e f }")

        err += test("a { b c } a.b(-> c(1))", "a { b(-> c(1)) c }")
        err += test("a { b c } a { b(-> c(1)) }", "a { b(-> c(1)) c }")

        err += test("a { b f } z:a z.f(-> b(1))", "a { b f } z { b f(-> b(1)) }")

        err += test("a { b c }.{ d e } z:a z.b.e(-> z.c(1))",
                    "a { b { d e } c { d e } } z { b { d e(-> c(1)) } c { d e } }")

        err += test("a {b c}.{d e f(-> b(1)) } z:a z.b.f(->c(1))",
                    """
                    a { b { d e f(-> b(1)) } c { d e f(-> b(1)) } }
                    z { b { d e f(-> c(1)) } c { d e f(-> b(1)) } }
                    """) // f; f to b

        err += test("a { b c }.{ d(0…1, -> a˚on(0)) }",
                    """
                    a { b { d(0…1, -> a˚on(0)) } 
                        c { d(0…1, -> a˚on(0)) } }
                    """,[.parens, .edge, .comment, .def, .noLF] )

        err += test("a { b c } a˚.{ d(0…1, -> a˚.on(0)) }",
                    """
                    a { b.d(0…1, -> a˚.on(0))
                        c.d(0…1, -> a˚.on(0)) } 
                    """)

        err += test("a.b.c { d(1) } a.b.e:a.b.c",
                    "a.b { c.d(1) e.d(1) }")

        /// should have warning: `cannot expand z.*.g`
//        err += test("a {b c}.{d e f} z:a z.*.g ", "a { b { d e f } c { d e f } } z { b { d e f g } c { d e f } }")
//
//        err += test("a.c { d { e { f (\"ff\") } } } a.c.z: a.c { d.e.f (\"ZZ\") }",
//                    "a.c { d.e.f (\"ff\") z { d.e.f (\"ZZ\") }")

        XCTAssertEqual(err, 0)
    }
    func testEdgeComma() { headline(#function)
        var err = 0
        err += test("z { b c { d e f(-> c) } }")
        err += test("z { b c { d e f(-> (b(1), c(1))) } }")
        err += test("z { b c { d e f(-> (z.b.d(1), z.b.e(1))) } }") // no  (z.b.d(1), z.b.e(1))
        XCTAssertEqual(err, 0)
    }
    func testSimple() { headline(#function)
        var err = 0
        err += test("a b")
        err += test("a { b }", "a.b")
        err += test("a { b { c } }", "a.b.c")
        err += test("a { b } c", "a.b c")
        err += test("a(0) b(0)")
        XCTAssertEqual(err, 0)
    }

    func testEdge() { headline(#function)
        var err = 0
        err += test("a(-> a)")
        err += test("a b(-> a)")
        err += test("a(-> a(0))")
        err += test("a b(-> a(0))")
        err += test("a b(<- a(* 10))")
        err += test("a(x, y, z, <- (x, y, z)) x(1) y(2) z(3)")
        err += test("a(x, y, z, <- b), b(x 1, y 2, z 3)")
        XCTAssertEqual(err, 0)
    }
    func testEvaluate() { headline(#function)
        var err = 0
        err += test("b(x / 2) a(<- b(x / 2))")
        XCTAssertEqual(err, 0)
    }
    func testStar() { headline(#function)
        var err = 0
        err += test("a { b c } a.*.d ", "a { b c }") // cannot expand path
        err += test("a { b c } a.* { d }", "a { b.d c.d }")
        err += test("a { b c } a.* { d(0…1, -> a˚on(0)) }",
                    """
                    a { b { d(0…1, -> a˚on(0)) } 
                        c { d(0…1, -> a˚on(0)) } }
                    """,[.parens, .edge, .comment, .def, .noLF] )
        err += test("a b(<- a(* 10))")
        XCTAssertEqual(err, 0)
    }

    func testDegree() { headline(#function)
        var err = 0
        err += test("a { b c } a˚.{ d }", "a { b.d c.d }")

        err += test("a { b c } a˚.{ d(0…1, -> a˚.on(0)) }",
                    """
                    a { b.d(0…1, -> a˚.on(0)) 
                        c.d(0…1, -> a˚.on(0)) }
                    """)
        XCTAssertEqual(err, 0)
    }
    func testPath() { headline(#function)
        var err = 0
        err += test("a.b { c d } ")
        err += test("a { b { c ..d } }",  "a { b.c d }")
        err += test("m (1, 2, 3), n(-> m(4, 5, 6))")
        err += test("a { b { c(1) } } a.b.c(2)", "a.b.c(2)")
        err += test("a.b.c(1) z:a { b.c(2) }", "a.b.c(1) z.b.c(2)")
        err += test("a.b.c(0…1) z:a { b.c(0…1=1) }", "a.b.c(0…1) z.b.c(0…1=1)")
        err += test("a.b { c { d e.f(0…1) g} z:c { g } } ",
                    "a.b { c { d e.f(0…1) g } z { d e.f(0…1) g } }")
        XCTAssertEqual(err, 0)
    }

    func testMixedDot() { headline(#function)
        var err = 0
        err += test("a { b.c d }")
        err += test("a { b(1).c d }")
        err += test("a { b(1).c //yo \n d }")
        err += test("a { // aa \n b.c // cc \n d }")
        err += test("a.b .d", "a.b.d")
        err += test("a.b c:a .d", "a.b c {b d}")
        err += test("one(1).two(2).three(3)")
        err += test("""
        a {
            b(0) // bb
            b.c(1)
        }
        """,
        """
        a.b(0) { // bb
            c(1)
        }
        """)
        XCTAssertEqual(err, 0)
    }

    func testComments() { headline(#function)
        var err = 0
        err += test("a('does something interesting')")
        err += test("a(x 'x does this', y 'y does that')")
        err += test("a(x, 'x does this', y, 'y does that')")
        err += test("a // yo")
        err += test("a { b } // yo", "a { // yo \nb } ")
        err += test("a { b // yo \n }", "a.b // yo")
        err += test("a { b { // yo \n c } }","a.b { // yo \n c }" )

        err += test("a, b { // yo \n c }")
        err += test("a { b { // yo \n c } }", "a.b { // yo \n c }")
        err += test("a { b { /* yo */ c } } ", "a.b { /* yo */ c }")
        err += test("a { b { /** yo **/ c } }", "a.b { /** yo **/ c }")
        //err += test("a b a // yo \n <- b // oy", " a <- b // yo \n b")
        XCTAssertEqual(err, 0)
    }
    func testParseBranch() { headline(#function)
        var err = 0
        err += test("a { b c }")
        err += test("a { b { c } }", "a.b.c")
        err += test("a { b { c } d { e } }", "a { b.c d.e }")
        err += test("a { b { c d } e }")
        XCTAssertEqual(err, 0)
    }
    func testParseGraft() { headline(#function)
        var err = 0

        err += test("a {b c}.{d e}",
                    "a { b { d e } c { d e } }")

        err += test("a {b c}.{d e}.{f g}",
                    "a { b { d { f g } e { f g } } c { d { f g } e { f g } } }")

        err += test("a {b c}.{d e}.{f g}.{h i} z(-> a.b˚g.h))",
                    "a { b { d { f { h i } g { h i } } e { f { h i } g { h i } } } " +
                    "    c { d { f { h i } g { h i } } e { f { h i } g { h i } } } } " +
                    " z(-> (a.b.d.g.h, a.b.e.g.h))")

        err += test("a {b {c}}.{d e}", "a.b { c d e }")

        XCTAssertEqual(err, 0)
    }

    func testParsePathCopy() { headline(#function)
        var err = 0
        err += test("a { b { c } } a.b(<> c)", "a.b(<>c).c")
        err += test("a { b { c } } a.b(1) ", "a.b(1).c ")
        err += test("a.b.c { b { d } }","a.b.c.b.d")
        err += test("a.b { c d } e:a { b.c(0) }", "a.b { c d } e.b { c(0) d }")
        err += test("a { b { c d } } e { b { c d } b(0) }", "a.b { c d } e.b(0) { c d }")

        XCTAssertEqual(err, 0)
    }

    func testExpr() { headline(#function)
        var err = 0
        subhead("simple")
        err += test("a (1)")
        err += test("a (1…2)")
        err += test("a (1_2)") // integer range
        err += test("a (1, 2)")
        err += test("a (x 1, y 2)")
        err += test("a (%2)")
        err += test("b (x %2, y %2)")
        err += test("m (1, 2, 3)")

        err += test("i (1…2=1.5, 3…4=3.5, 5…6=5.5)")
        err += test("b (x 1, y 2)")
        err += test("a (%2)")
        err += test("a (x 1…2, y 1…2)")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")

        subhead("edges")
        err += test("a(1) b(->a(2))")
        err += test("m (1, 2, 3), n(-> m(4, 5, 6))")

        subhead("scalars")
        err += test("a { b(2) { c } }", "a.b(2).c")
        err += test("a (1) { b(2) { c(3) } }", "a(1).b(2).c(3)")
        err += test("a(1).b(2).c(3)")
        err += test("a (0…1=0.5) { b(1…2) { c(2…3) } }", "a(0…1=0.5).b(1…2).c(2…3)")
        err += test("a(0…1=0.5).b(1…2).c(2…3)")
        err += test("a (%2) b(%2)")

        subhead("tuples")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")
        err += test("a (x 1…2, y 1…2)")
        err += test("b (x -1, y 2)")
        err += test("c (x 3, y 4)")
        err += test("d (x, y, z)")
        err += test("e (x -16…16, y -16…16)")
        err += test("f (p 0…1, q 0…1, r 0…1)")
        err += test("g (p 0…1=0.5, q 0…1=0.5, r 0…1=0.5)")
        err += test("h (p 0…1=0.5, q 0…1=0.5, r 0…1=0.5)")
        err += test("i (0…1=0.5, 0…1=0.5, 0…1=0.5)")
        err += test("j (one 1, two 2)")
        err += test("k (one \"1\", two \"2\")")

        subhead("current value")
        err += test("b(0…1)", nil, [.parens, .def])
        err += test("b(0…1=0.2 : 0.3)")
        err += test("a(0…1=0 : 1)", nil, [.parens, .def, .now])
        err += test("a(0…1=0 : 1)", nil, [.parens, .def, .now])
        err += test("c(0…1 : 1)", nil, [.parens, .def, .now ])

        subhead("miscellaneous")
        err += test("a(\"b\")")
        err += test("abcdefghijklmnopqrstu1 abcdefghijklmnopqrstu2")
        err += test("i(0...1=0.5, 0...1=0.5, 0...1=0.5)","i(0…1=0.5, 0…1=0.5, 0…1=0.5)")
        err += test("value(16777200)")
        err += test("value(1.67772e+07)", "value(16777200)")
        XCTAssertEqual(err, 0)
    }
    func testParsePaths() { headline(#function)

        var err=0
        err += test("a { b c } a˚.{ d(0…1, -> a˚.on(2)) }",
                    "a { b.d(0…1, -> a˚.on(2)) c.d(0…1, -> a˚.on(2)) }")

        err += test("a { b { c { c1 c2 } d } } a e", "a.b { c { c1 c2 } d } e")
        err += test("a { b { c d } } a { e }", "a { b { c d } e }")
        err += test("a { b { c d } b.e }", "a.b { c d e }")
        err += test("a { b { c d } b.e.f }", " a.b { c d e.f }")
        err += test("a.b.c.d { e.f }", "a.b.c.d.e.f")

        err += test("a { b { c { c1 c2 } d } b.c { c3 } }",
                    "a.b { c { c1 c2 c3 } d }") 

        subhead("override values")
        err += test("a { b { c { c1 c2 } d } b.c { c2(2) c3 } }",
                    "a.b { c { c1 c2(2) c3 } d }")
        err += test("ab { a(1) b(2) } ab { c(4) d(5) }",
                    "ab { a(1) b(2) c(4) d(5) }")

        XCTAssertEqual(err, 0)
    }
   //MARK: - Edges
    func testParseEdges() { headline(#function)
        var err = 0

        err += test("a.b.c ˚˚{ d }", "a { b { c.d d } d }")
        err += test("a.b.c a(<> .*) ", "a(<> b).b.c")

        err += test("a b c(<-b)")
        err += test("a, b, c(-> b)")
        err += test("a { a1, a2 } w(<- a.*)", "a { a1, a2 } w(<- (a.a1, a.a2))")
        err += test("a { b { c } } a(<> .*) ", "a(<> b).b.c")
        err += test("a { b { c } } a.b(<> c) ","a.b(<> c).c ")

        subhead("degree edge")
        err += test("a { b { c } } a˚˚(<> .*) ", "a(<> b).b(<> c).c")
        err += test("a { b { c } }  ˚˚(<> ..) ", "a(<> √).b(<> a).c(<> b)")

        subhead("multi edge")
        err += test("a(<- (b c))", "a(<- (b, c))")
        err += test("a(<- (b c)) { b c }", "a(<- (b, c)) { b c }")
        err += test("a(-> (b c)) { b c }", "a(-> (b, c)) { b c }")

        subhead("base twin")
        err += test("a {b c} z:a(<: a) ",
                    "a { b c } z(<: a) { b(<: a.b) c(<: a.c) }")

        err += test("a {b c}.{d e} z:a(<: a)",
                    """
                    a { b { d e } c { d e } }
                    z(<: a) { b(<: a.b) { d(<: a.b.d) e(<: a.b.e) }
                              c(<: a.c) { d(<: a.c.d) e(<: a.c.e) } }
                    """)

        XCTAssertEqual(err, 0)
    }
    func testParseRelativePaths() { headline(#function)
        var err = 0
        err += test("d {a1 a2}.{b1 b2} e(<- d˚b1)",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e(<- (d.a1.b1, d.a2.b1))")

        err += test("d {a1 a2}.{b1 b2} e(<- d˚˚)",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e(<- (d, d.a1, d.a1.b1, d.a1.b2, d.a2, d.a2.b1, d.a2.b2))")

        XCTAssertEqual(err, 0)
    }
    func testEdgeVal0() { headline(#function)
        /// test `a(3), b(2, -> a(3))` for `b!`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(1), b(2, -> a(3))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {

            b.activate([],Visitor(0))
            err = Parsin.testCompare("a(3), b(2)", root.scriptNow)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgeVal2() { headline(#function)
        /// test `a {a1 a2} b(-> a.*(2))` for `b!`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {a1 a2} b(-> a.*(2))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {

            b.activate([],Visitor(0, .model))
            err += Parsin.testCompare("a { a1(2) a2(2) } b(-> (a.a1(2), a.a2(2)))", root.scriptRoot([.parens, .now, .edge]))
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgeVal3a() { headline(#function)
        /// test `a {b c}.{f g}`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g}"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script) {
            let result = root.scriptRoot([.parens, .now])
            err += Parsin.testCompare("a { b { f g } c { f g } }", result)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgeVal3b() { headline(#function)
        /// test `a {b c}.{f g} z(-> a˚g(2))`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g} z(-> a˚g(2))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           //let a =  root.findPath("a"),
           let z =  root.findPath("z") {
            z.activate([],Visitor(0, .model))
            let result = root.scriptRoot([.parens, .now, .edge])
            err += Parsin.testCompare(
            "a { b { f g(2) } c { f g(2) } } z(-> (a.b.g(2), a.c.g(2)))", result)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgeVal4a() { headline(#function)
        /// test `a {b c}.{f g} z(-> a˚g(2))`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{d e} z(-> a˚e(2))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let z =  root.findPath("z") {

            z.activate([],Visitor(0, .model))
            err += Parsin.testCompare(
            "a { b { d e(2) } c { d e(2) } } z(-> (a.b.e(2), a.c.e(2)))", root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgeVal4b() { headline(#function)
        /// test `z -> a.b.f(1) -> a˚g(2)`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g} z(-> (a.b.f(1) a˚g(2)))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let z =  root.findPath("z") {

            z.activate([],Visitor(0, .model))

            err += Parsin.testCompare(
            """
            a { b { f(1) g(2) } 
                c { f    g(2) } }
            z(-> (a.b.f(1), a.b.g(2), a.c.g(2)))
            """, root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testEdgePath() { headline(#function)
        var err=0
        XCTAssertEqual(err, 0)
        err += test("a { b c }.{ d e (-> d) }",
                    "a { b { d e(-> d) } c { d e(-> d) } }")
        XCTAssertEqual(err, 0)
    }
    //MARK: - Base

    func testBase() { headline(#function)
        var err=0

        err += test("a.b c:a {d}",  "a.b c {b d}")
        err += test("a.b.c { ..d }",  "a.b { c d }")
        err += test("a.b c:a { d }",  "a.b c { b d }")
        err += test("a { b c } \n h:a { i j }",
                    "a { b c } h { b c i j }")

        err += test("a { b c } d:a", "a { b c } d { b c }")
        err += test("a { b c } d:a", "a { b c } d { b c }")

        err += test("a { b c } z:a",  "a { b c } z { b c }")
        err += test("a {b c} d:a ", "a { b c } d { b c }")

        err += test("a { b { c (\"yo\") } } d:a { b { c (\"oy\") } }",
                    "a.b.c(\"yo\") d.b.c(\"oy\")")
        err += test("a { b.bb c.cc z:b }",
                    "a { b.bb c.cc z.bb }")
        err += test("a { b c } d:a { e f } g:d { h i } j:g { k l }",
                    "a { b c } d { b c e f } g { b c e f h i } j { b c e f h i k l }")

        err += test("a { b c } h:a { i j }",
                    "a { b c } h { b c i j }")

        err += test("a { b c } \n h:a { i j }",
                    "a { b c } h { b c i j }")

        err += test("a { b c }.{d e} z:a.b",
                    "a { b { d e } c { d e } } z { d e }")

        err += test("a { b { d e } c { d e } } z:a.b",
                    "a { b { d e } c { d e } } z { d e }")

        err += test("a { b { c { c1 c2 } d { d1 d2 } } b.c:b.d }",
                    " a.b { c { c1 c2 d1 d2 }  d { d1 d2 } }")

        err += test("a { b { c d } } a:e",
                    "a {b { c d } e }")

        err += test("a.aa(1) b:a { aa(2) }",
                    "a.aa(1) b.aa(2)")

        subhead("merge base (d:c)")

        err += test("a.b { c { c1 c2 } d:c { d1 d2 } }",
                    "a.b { c { c1 c2 } d { c1 c2 d1 d2 } }")

        subhead("override values")

        err += test("""
                    ab    { a(1) b(2) } 
                    cd:ab { a(3)      c(4) d(5) }      
                    ef:cd {      b(6)      d(7) e(8) f(9) }
                    """,
                    """
                    
                    ab { a(1) b(2) } 
                    cd { a(3) b(2) c(4) d(5) } 
                    ef { a(3) b(6) c(4) d(7) e(8) f(9) }
                    """)

        subhead("multibase")

        err += test("a { a1 a2 } b { b1 b2 } c { c1 c2 } z:a:b:c",
                    "a { a1 a2 } b { b1 b2 } c { c1 c2 } z { c1 c2 b1 b2 a1 a2 }")

        XCTAssertEqual(err, 0)

    }

    func testBase0() { headline(#function)
        /// test `a{b(1)} c:a` for copy `b`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a { b(1) } c:a(<: a)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let c = root.findPath("c"),
           let ab = a.findPath("b"),
           let cb = c.findPath("b") {

            if let abv = ab.exprs?.nameAny.values.first as? Scalar,
               let acv = cb.exprs?.nameAny.values.first as? Scalar,
               abv.id == acv.id {
                err += 1
            }
            err += Parsin.testCompare("a.b(1) c (<: a).b(1, <: a.b)", root.scriptAll)

            ab.setVal(2, .fire)
            err += Parsin.testCompare("a.b(2) c (<: a).b(2, <: a.b)", root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testBase1() { headline(#function)
        /// test `z:a <:a`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b(1) c(2)}.{d(3) e(4)} z:a(<: a)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a =  root.findPath("a"),
           let ab = a.findPath("b"),
           let ac = a.findPath("c"),
           let abd = ab.findPath("d"),
           let abe = ab.findPath("e"),
           let acd = ac.findPath("d"),
           let ace = ac.findPath("e"),
           let z = root.findPath("z"),
           let zb = z.findPath("b"),
           let zc = z.findPath("c"),
           let zbd = zb.findPath("d"),
           let zbe = zb.findPath("e"),
           let zcd = zc.findPath("d"),
           let zce = zc.findPath("e") {

            err += Parsin.testCompare("""
            
            a        { b(1)         { d(3)           e(4)           }
                       c(2)         { d(3)           e(4)           }}
            z (<: a) { b(1, <: a.b) { d(3, <: a.b.d) e(4, <: a.b.e) }
                       c(2, <: a.c) { d(3, <: a.c.d) e(4, <: a.c.e) }}
            """, root.scriptAll)

            ab.setVal (10, .fire)
            err += Parsin.testCompare("""
            
            a        { b(10)         { d(3)           e(4)           }
                       c(2)          { d(3)           e(4)           }}
            z (<: a) { b(10, <: a.b) { d(3, <: a.b.d) e(4, <: a.b.e) }
                       c( 2, <: a.c) { d(3, <: a.c.d) e(4, <: a.c.e) }}
            """, root.scriptAll)

            ac.setVal (20, .fire)
            err += Parsin.testCompare("""
            
            a        { b(10)         { d(3)           e(4)           }
                       c(20)         { d(3)           e(4)           }}
            z (<: a) { b(10, <: a.b) { d(3, <: a.b.d) e(4, <: a.b.e) }
                       c(20, <: a.c) { d(3, <: a.c.d) e(4, <: a.c.e) }}
            """, root.scriptAll)

            abd.setVal(30, .fire)
            abe.setVal(40, .fire)
            acd.setVal(50, .fire)
            ace.setVal(50, .fire)
            err += Parsin.testCompare("""

            a        { b(10)         { d(30)           e(40)           }
                       c(20)         { d(50)           e(50)           }}
            z (<: a) { b(10, <: a.b) { d(30, <: a.b.d) e(40, <: a.b.e) }
                       c(20, <: a.c) { d(50, <: a.c.d) e(50, <: a.c.e) }}
            """, root.scriptAll)

            zb.setVal (11, .fire)
            zc.setVal (22, .fire)
            zbd.setVal(33, .fire)
            zbe.setVal(44, .fire)
            zcd.setVal(55, .fire)
            zce.setVal(66, .fire)
            err += Parsin.testCompare("""

            a        { b(10)         { d(30)           e(40)           }
                       c(20)         { d(50)           e(50)           }}
            z (<: a) { b(11, <: a.b) { d(33, <: a.b.d) e(44, <: a.b.e) }
                       c(22, <: a.c) { d(55, <: a.c.d) e(66, <: a.c.e) }}
            """, root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testBase2() { headline(#function)
        /// test `z:a <:> a`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b(1) c(2)}.{d(3) e(4)} z:a(<:> a)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let ab = a.findPath("b"),
           let ac = a.findPath("c"),
           let abd = ab.findPath("d"),
           let abe = ab.findPath("e"),
           let acd = ac.findPath("d"),
           let ace = ac.findPath("e"),

            let z = root.findPath("z"),
           let zb = z.findPath("b"),
           let zc = z.findPath("c"),
           let zbd = zb.findPath("d"),
           let zbe = zb.findPath("e"),
           let zcd = zc.findPath("d"),
           let zce = zc.findPath("e") {

            ab.setVal (10, .fire)
            ac.setVal (20, .fire)
            abd.setVal(30, .fire)
            abe.setVal(40, .fire)
            acd.setVal(50, .fire)
            ace.setVal(60, .fire)

            err += Parsin.testCompare("""

            a {           b(10)          { d(30)            e(40)           }
                          c(20)          { d(50)            e(60)           }}
            z   (<:> a) { b(10, <:> a.b) { d(30, <:> a.b.d) e(40, <:> a.b.e) }
                          c(20, <:> a.c) { d(50, <:> a.c.d) e(60, <:> a.c.e) }}
            """, root.scriptAll)

            zb.setVal (11, .fire)
            zc.setVal (22, .fire)
            zbd.setVal(33, .fire)
            zbe.setVal(44, .fire)
            zcd.setVal(55, .fire)
            zce.setVal(66, .fire)
            
            err += Parsin.testCompare("""

            a           { b(11)          { d(33)            e(44)            }
                          c(22)          { d(55)            e(66)            }}
            z   (<:> a) { b(11, <:> a.b) { d(33, <:> a.b.d) e(44, <:> a.b.e) }
                          c(22, <:> a.c) { d(55, <:> a.c.d) e(66, <:> a.c.e) }}
            """, root.scriptAll)
            
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testBaseExpand() { headline(#function)
        var err = 0
        err += test("a { b f } z:a z.f(1)", "a { b f } z { b f(1) }")
        err += test("a { b f } z:a *.f(1)", "a { b f(1) } z { b f(1) }")
        err += test("a { b f } z:a z.b.bb(1)", "a { b f } z { b.bb(1) f }")
        err += test("a { b f(-> a) } z:a", "a { b f(-> a) } z { b f(-> a) }")
        err += test("a {b c}.{d e f} z:a", "a { b { d e f } c { d e f } } z { b { d e f } c { d e f } }")
        err += test("a {b c}.{d e f} z:a { g }", "a { b { d e f } c { d e f } } z { b { d e f } c { d e f } g }")
        XCTAssertEqual(err, 0)
    }
    //MARK: - Filter
    func testFilter() { headline(#function)
        let ops: ParOps = .printParsin
        var err = 0

        let script = "a(x == 10, y, <- b) b(x 0, y 0)"

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {

            err += Parsin.testCompare("a(x == 10, y) b(x : 0, y : 0)", root.scriptNow, parOps: ops)

            b.activate([])
            err += Parsin.testCompare("a(x == 10, y, <- b) b(x 0, y 0)", root.scriptAll, parOps: ops)

            /// send an anonymous expression to `b` to satisfy filter
            let anonExpress = Exprs(Flo("anonFlo"), [("x", 10), ("y",20)])
            b.setFromExprs(anonExpress, .fire)
            err += Parsin.testCompare("a(x == 10, y : 20, <- b) b(x 10, y 20)", root.scriptAll, parOps: ops)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testFilter0() { headline(#function)

        var err = 0

        err += test("a (w == 0, x 1, y 0)")

        err += test("a (w 0, x 1, y 0)")

        err += test("a {b c}.{ d(1) e(2) }",
                    "a { b { d(1) e(2) } c { d(1) e(2) } }")

        err += test("a {b c}.{ d(x 1) e(y 2) }",
                    "a { b { d(x 1) e(y 2) } c { d(x 1) e(y 2) } }")

        err += test("""
                    a {b c}.{ d(x 1) e(y 2) } w(x 0, y 0, z 0)
                    """,
                    """

                    a { b { d (x 1) e (y 2) }
                        c { d (x 1) e (y 2) } }
                    w (x 0, y 0, z 0)
                    """)

        err += test("""
                    a {b c}.{ d(x == 10, y 0, z 0) e(x 0, y == 21, z 0) }
                    """,
                    """
                    
                    a { b { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) }
                        c { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) } }
                    """)

        err += test("""
                    a {b c}.{ d(x == 10, y 0, z 0) e(x 0, y == 21, z 0) } w(x 0, y 0, z 0, <> a˚.)
                    """,
                    """

                    a { b { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) }
                        c { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) } }
                    w (x 0, y 0, z 0, <> (a.b.d, a.b.e, a.c.d, a.c.e))
                    """)
        XCTAssertEqual(err, 0)
    }
    func testFilter1() { headline(#function)
        let ops: ParOps = .printParsin
        var err = 0

        let script = """
        a {b c}.{ d(x == 10, y 0, z 0)
                  e(x 0, y == 21, z 0) }
                  w(x 0, y 0, z 0, <> a˚.)
        """
        let root = Flo("√")

        if floParse.parseRoot(root, script),

           let w = root.findPath("w") {

            err += Parsin.testCompare("""

            a { b { d(x==10, y 0, z 0) e(x 0, y==21, z 0) }
                c { d(x==10, y 0, z 0) e(x 0, y==21, z 0) } }
                    w(x 0,  y 0, z 0, <>( a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops)

            // 0, 0, 0 --------------------------------------------------

            let exprs = Exprs(Flo("_t0_"), [("x", 0), ("y", 0), ("z", 0)])
            w.setFromExprs(exprs, .fire)
            err += Parsin.testCompare("""

            a { b { d(x==10, y 0, z 0)  e(x 0, y==21, z 0) }
                c { d(x==10, y 0, z 0)  e(x 0, y==21, z 0) } }
                    w(x 0,   y 0, z 0, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops)


            // 10, 11, 12 --------------------------------------------------
            w.setFromExprs(Exprs(Flo("_t1_"), [("x", 10), ("y", 11), ("z", 12)]), .fire)
            err += Parsin.testCompare("""

            a { b { d(x==10, y 11, z 12) e(x 0, y==21, z 0) }
                c { d(x==10, y 11, z 12) e(x 0, y==21, z 0) } }
                    w(x 10, y 11, z 12, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops )

            // 20, 21, 22 --------------------------------------------------
            // when match fails, so no change
            w.setNameNums([("x", 20), ("y", 21), ("z", 22)], .fire)
            err += Parsin.testCompare("""

            a { b { d(x == 10, y 11, z 12) e(x 20, y == 21, z 22) }
                c { d(x == 10, y 11, z 12) e(x 20, y == 21, z 22) } }
                    w(x 20, y 21, z 22, <> ( a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops)

            // 10, 21, 33 --------------------------------------------------
            w.setFromExprs( Exprs(Flo("_t3_"), [("x", 10), ("y", 21), ("z", 33)]), .fire)
            err += Parsin.testCompare("""

            a { b { d(x==10, y 21, z 33) e(x 10, y==21, z 33) }
                c { d(x==10, y 21, z 33) e(x 10, y==21, z 33) } }
                    w(x 10, y 21, z 33, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testFilter2() { headline(#function)
        let ops: ParOps = .printParsin
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = """
        a {b c}.{ d(x == 10, y, z) e(x, y == 21, z) }
                  w(x, y, z, <> a˚.)
        """
        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let w = root.findPath("w") {

            // 0, 0, 0 --------------------------------------------------

            w.setFromExprs(Exprs(Flo("_t0_"), [("x", 0), ("y", 0), ("z", 0)]), .fire)

            err += Parsin.testCompare("""
            
             a { b { d(x == 10, y, z) e(x, y == 21, z) }
                 c { d(x == 10, y, z) e(x, y == 21, z) } }
            w(x : 0, y : 0, z : 0, <> ( a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops )

            // 10, 11, 12 --------------------------------------------------

            w.setNameNums([("x", 10), ("y", 11), ("z", 12)], .fire)

            err += Parsin.testCompare("""

            a { b { d(x == 10, y : 11, z : 12) e(x, y== 21, z) }
                c { d(x == 10, y : 11, z : 12) e(x, y== 21, z) } }
            w(x : 10, y : 11, z : 12, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops )

            // 20, 21, 22 --------------------------------------------------

            w.setNameNums([("x", 20), ("y", 21), ("z", 22)], .fire)

            err += Parsin.testCompare("""

            a { b { d(x == 10, y : 11, z : 12) e(x : 20, y == 21, z : 22) }
                c { d(x == 10, y : 11, z : 12) e(x : 20, y == 21, z : 22) } }
            w(x : 20, y : 21, z : 22, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops )

            // 10, 21, 33 --------------------------------------------------

            w.setNameNums([("x", 10), ("y", 21), ("z", 33)], .fire)

            err += Parsin.testCompare("""
            
            a { b { d(x == 10, y : 21, z : 33) e(x : 10, y==21, z : 33) }
                c { d(x == 10, y : 21, z : 33) e(x : 10, y==21, z : 33) } }
            w(x : 10, y : 21, z : 33, <> (a.b.d, a.b.e, a.c.d, a.c.e))
            """, root.scriptAll, parOps: ops )

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    //MARK: - Expr
    func testExpr0() { headline(#function)
        /// test `a(x, y, <- b), b(x 0, y 0)
        var err = 0

        let script = "a(x, y, <- b), b(x 0, y 0)"

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {

            err += Parsin.testCompare("a(x, y), b(x : 0, y : 0)", root.scriptNow)

            b.setNameNums([("x", 1), ("y", 2)], .fire)
            err += Parsin.testCompare("a(x : 1, y : 2), b(x : 1, y : 2)", root.scriptNow)
            err += Parsin.testCompare("a(x, y, <- b), b(x 1, y 2)", root.scriptDef)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr1() { headline(#function)
        /// test `a(x 0) <- c, b(y 0) <- c, c(x 0, y 0)`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x 0, <- c),  c(x 0, y 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let c = root.findPath("c") {

            c.setNameNums([("x", 1), ("y", 2)], .fire)
            err = Parsin.testCompare("a(x : 1), c(x : 1, y : 2)", root.scriptNow)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr2() { headline(#function)
        /// test `a(x 0, <- c), b(y 0, <- c), c(x 0, y 0)`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x 0, <- c), b(y 0, <- c), c(x 0, y 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let c = root.findPath("c") {

            c.setNameNums([("x", 1), ("y", 2)], .fire)

            err += Parsin.testCompare("a(x : 1), b(y : 2), c(x : 1, y : 2)", root.scriptNow)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr3() { headline(#function)
        /// test `a(x:0…2, y:0…2, z:99), b (x:0…2, y:0…2) <- a`
        let ops: ParOps = .printParsin
        var err = 0

        let script = "a(x 0…2, y 0…2, z 99), b(x 0…2, y 0…2, <- a)"

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a") {

            a.setNameNums([("x", 1), ("y", 1)], .fire)

            err += Parsin.testCompare(
                "a(x 0…2, y 0…2, z 99), b(x 0…2, y 0…2, <- a)", root.scriptDef, parOps: ops )

            err += Parsin.testCompare("a(x : 1, y : 1, z : 99), b(x : 1, y : 1)", root.scriptNow, parOps: ops )
            err += Parsin.testCompare("a(x 0…2 : 1, y 0…2 : 1, z 99), b(x 0…2 : 1, y 0…2 : 1, <- a)", root.scriptAll, parOps: ops)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr4() { headline(#function)
        /// test `a(x in 2…4, y in 3…5) -> b b(x 1…2, y 2…3)`
        let ops: ParOps = .printParsin
        var err = 0

        let script = "a(x in 2…4, y in 3…5, -> b) b(x 1…2, y 2…3)"

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a") {

            err += Parsin.testCompare("a(x in 2…4, y in 3…5, -> b)  b(x 1…2, y 2…3)", root.scriptAll)
            err += Parsin.testCompare("a(x : 2, y : 3) b(x : 1, y : 2)", root.scriptNow, parOps: ops )

            // will fail expression, so no current values
            a.setNameNums([("x", 1), ("y", 4)], .fire)
            err += Parsin.testCompare("a(x in 2…4, y in 3…5, -> b) b(x 1…2, y 2…3)", root.scriptAll, parOps: ops )

            // will pass exprs, so include current value
            a.setNameNums([("x", 3), ("y", 4)], .fire)
            err += Parsin.testCompare("a(x in 2…4 : 3, y in 3…5 : 4, -> b) b(x 1…2 : 1.5, y 2…3 : 2.5)", root.scriptAll, parOps: ops)

            err += Parsin.testCompare("a(x : 3, y : 4) b(x : 1.5, y : 2.5)", root.scriptNow)

            // fail, will keep last value
            a.setNameNums([("x",1), ("y",4)], .fire)
            err += Parsin.testCompare("a(x : 3, y : 4) b(x : 1.5, y : 2.5)", root.scriptNow, parOps: ops )

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr5() { headline(#function)
        /// test `b(sum: x + y + z) <- a`
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = "a(x 10, y 20, z 30), b(x + y + z, <- a), c(x + y + z, <- a)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a = root.findPath("a") {

            a.setNameNums([("x", 1), ("y", 2), ("z", 3)], .fire)

            err += Parsin.testCompare(
            """
            a(x 1, y 2, z 3), 
            b(x + y + z : 6, <- a), 
            c(x + y + z : 6, <- a)
            """, root.scriptAll)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr6() { headline(#function)
        /// test `b(sum x + y + z) <- a`
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = "a(x 10, y 20, z 30), b(x < 0.9, y, z, <- a), c(x > 0, y, z, <- a)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a = root.findPath("a") {

            err += Parsin.testCompare(
            "a(x 10, y 20, z 30), b(x < 0.9, y, z, <- a), c(x > 0, y, z, <- a)", root.scriptAll)

            a.setNameNums([("x", 1), ("y", 2), ("z", 3)], .fire)
            err += Parsin.testCompare(
            "a(x 1, y 2, z 3), b(x < 0.9, y, z, <- a), c(x > 0 : 1, y : 2, z : 3, <- a)", root.scriptAll)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr7() { headline(#function)
        /// test `b(sum: x + y + z) <- a`
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = 
        """
        a(x 10, y 20, z 30, <- z)
        b(x 10, y 20, z 30, -> z)
        z(x 1, y 2)
        """
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let b = root.findPath("b"),
           let z = root.findPath("z"){

            z.activate([]) // changes a
            err += Parsin.testCompare(
                """
                a(x  1, y  2, z 30, <- z)
                b(x 10, y 20, z 30, -> z)
                z(x  1, y  2)
                """, root.scriptAll)

            a.activate([]) // no change
            err += Parsin.testCompare(
                """
                a(x  1, y  2, z 30, <- z)
                b(x 10, y 20, z 30, -> z)
                z(x  1, y  2)
                """, root.scriptAll)

            b.activate([]) // changes z, which changes a
            err += Parsin.testCompare(
                """
                a(x 10, y 20, z 30, <- z)
                b(x 10, y 20, z 30, -> z)
                z(x 10, y 20)
                """, root.scriptAll)

        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    func testExpr8() { headline(#function)
        /// test `a(pipe 1, file "kerne"l)
        var err = 0

        let script =
        """
        slide(pipe 1, file "kernel.cell.slide", kernel "slideKernel" ) {
            version (buffer_0, x 0…7 : 3)
            loops (y 0…20)
        }
        """
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script)  {

            err += Parsin.testCompare(
            """
            slide(pipe 1, file "kernel.cell.slide", kernel "slideKernel" ) {
                version (buffer_0, x 0…7 : 3)
                loops (y 0…20)
            }
            """, root.scriptAll)

        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    func testPolyEdge() { headline(#function)
        var err = 0
        err += test("a(0…1, <-b, ->c, ^-d) b c d(1)" )
        XCTAssertEqual(err, 0)
    }
    func testSideLineage() { headline(#function)
        var err = 0
        err += test("a {b c}.{d e}.{f g} a.b.d.f(<-e.f)",
                    "a { b { d { f(<-e.f) g } e { f g } } c { d { f g } e { f g } } }" )
        XCTAssertEqual(err, 0)
    }
    func testLeafComments() { headline(#function)
        // extra LF after comment?
        var err = 0
        err += test(
        """
        a { 
            b(1) // bb
            c
        }
        """,
        """
           a {
            b(1) // bb
            c
        }
        
        """, .Full, strict: true)
        XCTAssertEqual(err, 0)
    }

    //MARK: - assign
    func testClosure() { headline(#function)
        /// test `a(x:0…2, y:0…2, z:99), b (x:0…2, y:0…2) <- a`
        var err = 0
        let ops: ParOps = .printParsin

        let script = "a(x 0…2, y 0…2)"

        let root = Flo("√")
        if floParse.parseRoot(root, script, parOps: ops),
           let a = root.findPath("a") {


            var doubles: [Double] = []

            a.addClosure { flo, _ in
                doubles = flo.doubles
            }
            a.setNameNums([("x",1), ("y",1)], .fire)

            if doubles != [1, 1] {
                err += 1
            }
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testAssign0() { headline(#function)
        /// test `a(x, y) b(v 0) -> a(x v)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v 0, -> a(x : v))" /// `x` receives `v`
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {

            err += Parsin.testCompare("a(x, y) b(v 0, -> a(x : v))", root.scriptDef)

            b.setNameNums([("v", 1)], .fire)
            err += Parsin.testCompare( "a(x : 1, y) b(v 1, -> a(x : v))", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testAssign1() { headline(#function)
        /// test `a(x, y) b(v:0) -> a(x v/2, y v*2)`
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v 0, -> a(x : v/2, y : v*2))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseRoot(root, script),
            let b = root.findPath("b") {

            err += Parsin.testCompare("a(x, y) b(v 0, -> a(x : v/2, y : v*2))", root.scriptAll)

            b.setNameNums([("v", 1)], .fire)
            err += Parsin.testCompare("a(x : 0.5, y : 2) b(v 1, -> a(x : v / 2, y : v * 2))", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    //MARK: - Midi
    func testMidiGrid() { headline(#function)
        /// test `grid(x num/12, y num % 12) <- note, note(num 0…127 = 50)`
        var err = 0
        let script = "grid(x : num / 12, y : num % 12, z : num + 1, <- note), note(num 50)"

        let root = Flo("√")
        if floParse.parseRoot(root, script) {
            err += Parsin.testCompare(
            "grid(x : num / 12, y : num % 12, z : num + 1, <- note), note(num 50)",
            root.scriptAll)

            if let note = root.findPath("note") {
                note.activate([])
                err += Parsin.testCompare(
                "grid(x : 4.166667, y : 2, z : 51) note(num : 50)",
                root.scriptValue)
            } else {
                err += 1
            }

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testMidiFilter() { headline(#function)
        /// test `grid(num>20, chan==1, x num/12, y num%12)<-note ...
        var err = 0

        let script = """
        grid(num > 20, chan==1, x : num / 12, y : num % 12, <- note),
        note(num 0_127:0, chan 2)
        """

        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let note = root.findPath("note") {

            err += Parsin.testCompare("""
                grid(num > 20, chan == 1, x : num / 12, y : num % 12, <- note),  note(num 0_127:0, chan 2)
                """, root.scriptAll)

            note.setNameNums([("num",50), ("chan",0)], .fire)
            err += Parsin.testCompare("""
                grid(num > 20, chan == 1, x : num / 12, y : num % 12, <- note), note(num 0_127 : 50, chan 0)
                """, root.scriptAll)

            note.setNameNums([("num",50), ("chan",1)], .fire)
            err += Parsin.testCompare("""
                grid(num > 20 : 50, chan == 1, x : num / 12 : 4.166667, y : num % 12 : 2, <- note), note(num 0_127 : 50, chan 1)
                """, root.scriptAll)

        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    // MARK: - pasthrough
    func testPassthrough() { headline(#function)
        /// test `a(0…1)<-b, b<-c, c(0…10)<-a`
        var err = 0
        let script = "a(0…1,<-b), b(<-c), c(0…10,<-a)"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let b = root.findPath("b"),
           let c = root.findPath("c") {

            err += Parsin.testCompare("a(0…1,<-b), b(<-c), c(0…10,<-a)",root.scriptAll)

            c.setVal(5.0, .fire)
            err += Parsin.testCompare("a(0.5) b(5) c(5)",root.scriptValue)

            a.setVal(0.1, .fire)
            err += Parsin.testCompare("a(0.1) b(1) c(1)",root.scriptValue)

            b.setVal(0.2, .fire)
            err += Parsin.testCompare("a(0.02) b(0.2) c(0.2)",root.scriptValue)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testRadioInside() { headline(#function)
        /// test `radio button inside {...}`
        var err = 0
        let script = """
        radio {
            a(on 0) { a1(1) a2(2) }
            b(on 1) { b1(1) b2(2) }
            * (->  *(on 0))
            ˚.(-> ..(on 1))
        }
        """
        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let radio = root.findPath("radio"),
           let a = radio.findPath("a"),
           let b2 = radio.findPath("b.b2") {
            a.setNameNums([("on", 1)], .fire)
            err += Parsin.testCompare(
            """
            radio {
                a(on 1, -> (a(on 0), b(on 0))) {
                    a1(1, -> a(on 1))
                    a2(2, -> a(on 1))
                }
                b(on 0, -> (a(on 0), b(on 0))) {
                    b1(1, -> b(on 1))
                    b2(2, -> b(on 1))
                }
            }
            """,root.scriptFull)

            b2.setVal(22, .fire)
            print("\n" + root.scriptFull)
            err += Parsin.testCompare(
            """
            radio {
                a(on 0, -> (a(on 0), b(on 0))) {
                    a1(1, -> a(on 1))
                    a2(2, -> a(on 1))
                }
                b(on 1, -> (a(on 0), b(on 0))) {
                    b1(1, -> b(on 1))
                    b2(22, -> b(on 1))
                }
            }
            """,root.scriptFull)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testRadioOutside() { headline(#function)
        /// test `radio button path outside {...}`
        var err = 0
        let script = """
        radio {
            a(on 0) { a1(1) a2(2) }
            b(on 1) { b1(1) b2(2) }
        }
        radio.*(-> *(on 0))
        radio˚.(-> ..(on 1))
        """
        let root = Flo("√")

        if floParse.parseRoot(root, script),
           let radio = root.findPath("radio"),
           let a = radio.findPath("a"),
           let b2 = radio.findPath("b.b2") {

            print("\n" + root.scriptFull)
            a.setNameNums([("on", 1)], .fire)
             print("\n" + root.scriptFull)
            err += Parsin.testCompare(
            """
            radio {
                a(on 1, -> (a(on 0), b(on 0))) {
                    a1(1, -> a(on 1))
                    a2(2, -> a(on 1))
                }
                b(on 0, -> (a(on 0), b(on 0))) {
                    b1(1, -> b(on 1))
                    b2(2, -> b(on 1))
                }
            }
            """,root.scriptFull)

            b2.setVal(22, .fire)
            print("\n" + root.scriptFull)
            err += Parsin.testCompare(
            """
             radio {
                a(on 0, -> (a(on 0), b(on 0))) {
                    a1(1, -> a(on 1))
                    a2(2, -> a(on 1))
                }
                b(on 1, -> (a(on 0), b(on 0))) {
                    b1(1, -> b(on 1))
                    b2(22, -> b(on 1))
                }
            }
            """,root.scriptFull)


        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    //MARK: - Scripts
    func testD3Script() { headline(#function)
        /// D3.js script for force directed graph
        var err = 0
        let root = Flo("√")
        let script = "a.b.c(1) d { e(2, <> a.b.c) } f : d"

        if floParse.parseRoot(root, script) {

            err += Parsin.testCompare("a.b.c(1) d.e(2) f.e(2)", root.scriptNow)

//            err += Parsin.testCompare(
//            """
//            var graph = {
//            'nodes': [
//            {'id':548, 'name':'√', 'children': [550,553,557]},
//            {'id':550, 'name':'a', 'children': [559]},
//            {'id':559, 'name':'b', 'children': [560]},
//            {'id':560, 'name':'c'},
//            {'id':553, 'name':'d', 'children': [554]},
//            {'id':554, 'name':'e', 'edges': ['554<>560']},
//            {'id':557, 'name':'f', 'children': [565]},
//            {'id':565, 'name':'e'},
//            ],
//            'links': [
//            {'id':'548.550', 'source':548, 'target':550, 'type':'.'},
//            {'id':'548.553', 'source':548, 'target':553, 'type':'.'},
//            {'id':'548.557', 'source':548, 'target':557, 'type':'.'},
//            {'id':'550.559', 'source':550, 'target':559, 'type':'.'},
//            {'id':'559.560', 'source':559, 'target':560, 'type':'.'},
//            {'id':'553.554', 'source':553, 'target':554, 'type':'.'},
//            {'id':'557.565', 'source':557, 'target':565, 'type':'.'},
//            {'id':'554<>560', 'source':554, 'target':560, 'type':'<>'},
//            ]
//            }
//            """,root.makeD3Script())
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testAnonParameters() { headline(#function)
        var err = 0
        let script = """
        a (_p 1, _q 2, <- b)
        b (_r 3, _s 4)
        """
        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let b = root.findPath("b") {
            
            err += Parsin.testCompare(
            """
            a (_p 1, _q 2, <- b)
            b (_r 3, _s 4)
            """, root.scriptFull)
            
            b.activate([])

            err += Parsin.testCompare(
            """
            a (_p 3, _q 4, <- b)
            b (_r 3, _s 4)
            """, root.scriptFull)
            
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testBodySkeleton() { headline(#function)
        /// test body pose
        var err = 0
        err += testFile("test.body.input", out: "test.body.output", .Full)
        err += testFile("test.skeleton.input",  out: "test.skeleton.output", .Curly)
        err += testFile("test.hand.input",  out: "test.hand.output", .Curly)
        XCTAssertEqual(err, 0)
    }

    //MARK: - deltas
    

    func testDelta() { headline(#function)
        /// test delta changes only
        var err = 0
        let script = "a { b(0) c(0) d(0…1, ^- f) e(0…1) f } "
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let b = a.findPath("b"),
           let c = a.findPath("c"),
           let d = a.findPath("d"),
           let e = a.findPath("e")
        {

            err += Parsin.testCompare("a { b(0) c(0) d(0…1, ^- f) e(0…1) f } ",root.scriptAll)

            b.setVal(1, .fire)
            var now = root.scriptRoot(.Delta)
            err += Parsin.testCompare("a.b(1)",now)

            c.setVal(2, .fire)
            now = root.scriptRoot(.Delta)
            err += Parsin.testCompare("a { b(1) c(2) }",now)

            d.setVal(0.3, .fire)
            now = root.scriptRoot(.Delta)
            err += Parsin.testCompare("a { b(1) c(2) d(0.3) }",now)

            e.setVal(0.4, .fire)
            now = root.scriptRoot(.Delta)
            err += Parsin.testCompare("a { b(1) c(2) d(0.3) e(0.4)}",now)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testValue() { headline(#function)
        /// test delta changes only
        var err = 0
        let script = "a { b(0) c(0) d(0…1, ^- f) e(0…1) f } "
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let b = a.findPath("b"),
           let c = a.findPath("c"),
           let d = a.findPath("d"),
           let e = a.findPath("e")
        {

            err += Parsin.testCompare("a { b(0) c(0) d(0…1, ^- f) e(0…1) f } ",root.scriptAll)

            b.setVal(1, .fire)
            var now = root.scriptRoot( [.now,.parens,.compact,.noLF]  )
            err += Parsin.testCompare("a { b(1) c(0) d(0) e(0) f }",now)

            c.setVal(2, .fire)
            now = root.scriptRoot( [.now,.parens,.compact,.noLF]  )
            err += Parsin.testCompare("a { b(1) c(2) d(0) e(0) f }",now)

            d.setVal(0.3, .fire)
            now = root.scriptRoot( [.now,.parens,.compact,.noLF] )
            err += Parsin.testCompare("a { b(1) c(2) d(0.3) e(0) f }",now)

            e.setVal(0.4, .fire)
            now = root.scriptRoot( [.now,.parens,.compact,.noLF]  )
            err += Parsin.testCompare("a { b(1) c(2) d(0.3) e(0.4) f }",now)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testRange() { headline(#function)
        /// test delta changes only
        var err = 0
        let script = "a { b(0~1, -> c) c(0…1) } "
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseRoot(root, script),
           let a = root.findPath("a"),
           let b = a.findPath("b")
        {
            err += Parsin.testCompare("a { b(0~1, -> c) c(0…1) } ",root.scriptAll)

            b.setVal(0.5, .fire)
            var now = root.scriptRoot( [.now,.parens,.compact,.noLF])
            err += Parsin.testCompare("a { b(0.5) c(0.5) }", now)

            b.setVal(2, [.fire, .ranging]) // set max
            now = root.scriptRoot( [.now,.parens,.compact,.noLF])
            err += Parsin.testCompare("a { b(2) c(1) }", now)

            b.setVal(0.5, .fire)
            now = root.scriptRoot( [.now,.parens,.compact,.noLF])
            err += Parsin.testCompare("a { b(0.5) c(0.25) }", now)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testSky() { headline(#function)
        var err = 0
            err += testFile("test.sky", out: "test.sky", .Full)
        XCTAssertEqual(err, 0)
    }
    func testTipNow() { headline(#function)
        var err = 0
        //err += test("a(x 0…1)","a(x : 0)",.Now)
        err += test("a(x 0…1, 'tip')","a(x 0…1, 'tip')",.All)
        err += test("a(x 0…1, 'tip')","a(x : 0)",.Now)
        XCTAssertEqual(err, 0)
    }
    func testSkyVal() { headline(#function)
        var err = 0
        err += testFile("test.sky", out: "test.sky.val", .Now)
        XCTAssertEqual(err, 0)
    }
}
