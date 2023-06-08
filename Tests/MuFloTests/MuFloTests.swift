import CoreFoundation
import XCTest
import MuPar
import MuSkyFlo

@testable import MuFlo

final class MuFloTests: XCTestCase {

    var floParse = FloParse()

    /** Test script produces expected output
     - parameter script: test script
     - parameter expected: exected output after parse
     */
    func test(_ script: String,
              _ expected: String? = nil,
              _ scriptOps: FloScriptOps = FloScriptOps.Full) -> Int {

        var err = 0

        print(script)
        let root = Flo("√")
        let expected = expected ?? script

        if floParse.parseScript(root, script) {
            let actual = root.scriptRoot(scriptOps)
            // print("\n" + actual)
            err = ParStr.testCompare(expected, actual)
        } else  {
            print(" 🚫 failed parse")
            err += 1  // error found
        }
        return err
    }

    func headline(_ title: String) {
        //let titled = title.titleCase()
        print("\n━━━━━━━━━━━━━━━━━━━━━━ \(title) ━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    func subhead(_ title: String) {
        //let titled = title.titleCase()
        print("━━━━━━━━━━━ \(title) ━━━━━━━━━━━")
    }

    func read(_ filename: String) -> String? {
        let url = Bundle.module.url(forResource: filename, withExtension: "flo.h")
        if let path = url?.path {
            do { return try String(contentsOfFile: path) } catch {}
        }
        print("🚫 \(#function) cannot find:\(filename)")
        return nil
    }
    func readSky(_ filename: String) -> String? {
        return MuSkyFlo.read(filename, "flo.h")
    }

    func parseSky(_ name: String, _ root: Flo) -> Int {
        if let script = MuSkyFlo.read(name, "flo.h"),
           FloParse().parseScript(root, script) {
            print (name +  " ✓")
            return 0
        } else {
            print(name + " 🚫 parse failed")
            return 1
        }
    }
    func parse(_ name: String,_ root: Flo) -> Int {
        if let script = read(name) ?? MuSkyFlo.read(name, "flo.h"),
           floParse.parseScript(root, script) {
            print (name +  " ✓")
            return 0
        } else {
            print(name + " 🚫 parse failed")
            return 1
        }
    }

    func testSkyFile(_ inFile: String, out outFile: String) -> Int {

        if let inScript  = MuSkyFlo.read(inFile,  "flo.h"),
           let outScript = MuSkyFlo.read(outFile, "flo.h") {

            return testParse(inScript, outScript)

        } else {
            return 1 // error
        }
    }
    func testParse(_ inScript: String,
                   _ outScript: String,
                   full: Bool = false) -> Int {

        let root = Flo("√")

        if floParse.parseScript(root, inScript, whitespace: "\n\t ") {
            print (name +  " ✓")
            let err = ParStr.testCompare(outScript, full ? root.scriptFull : root.scriptAll)
            return err
        } else {
            return 1 // error
        }
    }
    func testFile(_ input: String, out: String, full: Bool = false) -> Int {

        if let inScript = read(input) {
            let outScript = read(out) ?? inScript
            return testParse(inScript, outScript, full: full)
        } else {
            return 1 // error
        }
    }

    func testPretty() {
        let root = Flo("√")
        let script = "a ( b ( // oy\n c // yo\n d ) e )"
        if floParse.parseScript(root, script, whitespace: "\n\t ") {
            let result = root.script(.cmpct)
            print(result)
        }
    }

    func testSession() { headline(#function)
        var err = 0
        err += test("a(1)")
        err += test("a(1)", nil, [.parens, .def, .now])
        XCTAssertEqual(err, 0)
    }

    func testEdgeSession() { headline(#function)
        var err = 0
        err += test("a(1) b >> a(2)", nil, [.parens, .now, .edge])
        XCTAssertEqual(err, 0)
    }

    func testParseShort() { headline(#function)
        var err = 0

        err += test("a(1)")
        err += test("a (x 1, y 2)")
        err += test("b(0…1)", nil, [.parens, .def])
        err += test("b(0…1~0.2:0.3)")

        err += test("a(x,y,z)<<(x,y,z) x(1) y(2) z(3)")
        err += test("a(x,y,z)<<b, b(x:1, y:2, z:3)")
        err += test("b(x / 2) a << b(x / 2)")
        err += test("a(0…1~0:1)", nil, [.parens, .def, .now])

        err += test("cell.one(1).two(2).three(3)", nil, [.parens, .now, .cmpct])
        err += test("a(0…1~0:1)", nil, [.parens, .def, .now])

        err += test("c(0…1:1)", nil, [.parens, .def, .now ])
        err += test("a(1) b >> a(2)")

        err += test("a(\"b\")")
        err += test("a { b c } d@a", "a { b c } d@a { b c }")
        err += test("a.b c@a", "a.b c @a .b", [.parens, .def, .now, .cmpct])
        err += test("a.b c @a .b",  "a { b } c @a { b }")

        err += test("b(x / 2) a << b(x / 2)")
        err += test("a b << a(* 10)")
        err += test("m (1, 2, 3), n >> m(4, 5, 6)")

        err += test("a { b c } a.*{ d }",
                    "a { b { d } c { d } }")

        err += test("a { b c } a.* { d(0…1) >> a˚on(0) }",
                    "a { b { d(0…1) >> a˚on(0) } c { d(0…1) >> a˚on(0) } }",[.parens, .edge, .comnt, .def, .noLF] )

        err += test("a { b c } a˚.{ d(0…1) >> a˚.on(0) }",
                    "a { b { d(0…1) >> a˚.on(0) } c { d(0…1) >> a˚.on(0) } }")

        err += test("i(0…1~0.5, 0…1~0.5, 0…1~0.5)")

        err += test(
            /**/"abcdefghijklmnopqrstu1 abcdefghijklmnopqrstu2")

        err += test("a { b { c(1) } } a.b.c(2)", "a { b { c(2) } }")

        err += test(
            /**/"a { b { c(1) } } z@a { b.c(2) }",
                "a { b { c(1) } } z@a { b { c(2) } }")

        err += test("a b c⟡→a")
        err += test("value(16777200)")
        err += test("value(1.67772e+07)", "value(16777200)")

        err += test("a.b.c(0…1) z@a { b.c(0…1~1) }",
                    "a { b { c(0…1) } } z@a { b { c(0…1~1) } }")

        err += test("a {b c}.{d e}.{f g}.{h i} z >> a.b˚g.h",
                    "a { b { d { f { h i } g { h i } } e { f { h i } g { h i } } } " +
                    "    c { d { f { h i } g { h i } } e { f { h i } g { h i } } } } " +
                    " z >> (a.b.d.g.h, a.b.e.g.h)")

        err += test("a {b c}.{d e f>>b(1) } z@a z.b.f⟡→c(1) ",
                    "a    { b { d e f>>a.b(1) } c { d e f>>a.b(1) } }" +
                    "z@a { b { d e f⟡→z.c(1) } c { d e f>>z.b(1) } }")

        err += test("a._c   { d { e { f (\"ff\") } } } a.c.z @ _c { d { e.f   (\"ZZ\") } }",
                    "a { _c { d { e { f (\"ff\") } } } c { z @ _c { d { e { f (\"ZZ\") } } } } }")

        err += test("a.b { _c { d e.f(0…1) g} z @ _c { g } } ",
                    "a { b { _c { d e { f(0…1) } g } z @ _c { d e { f(0…1) } g } } }")

        err += test("a.b._c {d(1)} a.b.e@_c",
                    "a { b { _c { d(1) } e@_c { d(1) } } }")

        err += test("a b >> a(1)")

        err += test("a.b { c d } a.e@a.b { f g } ",
                    "a { b { c d } e@a.b { c d f g } }")

        err += test("a { b c } d@a { e f } g@d { h i } j@g { k l }",
                    "a { b c } d@a { b c e f } g@d { b c e f h i } j@g { b c e f h i k l }")

        err += test("a { b c } h@a { i j }",
                    "a { b c } h@a { b c i j }")

        err += test("a { b c } \n h@a { i j }",
                    "a { b c } h@a { b c i j }")

        XCTAssertEqual(err, 0)
    }

    /// compare script with expected output and print an error if they don't match
    func testParseBasics() { headline(#function)

        var err = 0

        subhead("comment")
        err += test("a // yo", "a") //TODO: `a // yo`
        err += test("a { b } // yo", "a { b }")
        err += test("a { b // yo \n }")
        err += test("a { b { // yo \n c } }")

        err += test("a, b { // yo \n c }")
        err += test("a { b { // yo \n c } } ")
        err += test("a { b { /* yo */ c } } ")
        err += test("a { b { /** yo **/ c } } ")
        // error err += test("a b a // yo \n << b // oy\n", "a // yo \n << b // oy\n b")

        subhead("hierarchy")
        err += test("a { b c }")
        err += test("a { b { c } }")
        err += test("a { b { c } d { e } }")
        err += test("a { b { c d } e }")

        subhead("many")
        err += test("a {b c}.{d e}",
                    "a { b { d e } c { d e } }")

        err += test("a {b c}.{d e}.{f g}",
                    "a { b { d { f g } e { f g } } c { d { f g } e { f g } } }")

        subhead("copyat")
        err += test("a {b c} d@a ",
                    "a { b c } d@a { b c }")
        err += test("_a { b { c (\"yo\") } } d@ _a { b { c (\"oy\") } }")

        XCTAssertEqual(err, 0)
    }

    func testParsePathCopy() { headline(#function)
        var err = 0

        err += test("a.b.c { b { d } }",
                    "a { b { c { b { d } } } }")

        err += test("a.b { c d } e@a { b.c(0) }",
                    "a { b { c d } } e@a { b { c(0) d } }")

        err += test("a { b { c } } a.b <> c ",
                    "a { b <> a.b.c { c } }")

        err += test("a { b { c d } } e { b { c d } b(0) }" ,
                    "a { b { c d } } e { b(0) { c d } }")

        //        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? f.j : 0) ",
        //                    "a { b { d { f << (f.i ? f.j : 0 ) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }" +
        //                    "        e { f << (f.i ? f.j : 0 ) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }" +
        //                    "    c { d { f { i j } g { i j } }" +
        //                    "        e { f { i j } g { i j } } } } a.b˚f << (f.i ? f.j : 0 )" +
        //                    "", [.parens, .edge, .comment, .copyAt, .def, .now])
        //
        XCTAssertEqual(err, 0)
    }

    func testParseValues() { headline(#function)
        var err = 0
        err += test("a (1)")
        err += test("a (1…2)")
        err += test("a (1_2)") // integer range
        err += test("a (1, 2)")
        err += test("a (x 1, y 2)")
        err += test("a (%2)")
        err += test("b (x %2, y %2)")
        err += test("b (x 1, y 2)")
        err += test("m (1, 2, 3)")
        err += test("m (1, 2, 3), n >> m(4, 5, 6)")
        err += test("i (1…2~1.5, 3…4~3.5, 5…6~5.5)")
        err += test("b (x 1, y 2)")
        err += test("b (x 1, y 2)")
        err += test("a (%2)")
        err += test("a (x 1…2, y 1…2)")
        err += test("a (x 0…1~0.5, y 0…1~0.5)")
        err += test("a (0…1~0.5) { b(1…2) { c(2…3) } }")
        err += test("a (x 0…1~0.5, y 0…1~0.5)")

        subhead("flo scalars")
        err += test("a { b(2) { c } }")
        err += test("a (1) { b(2) { c(3) } }")
        err += test("a (0…1~0.5) { b(1…2) { c(2…3) } }")
        err += test("a (%2) b(%2)")

        subhead("flo tuples")
        err += test("a (x 0…1~0.5, y 0…1~0.5)")
        err += test("a (x 1…2, y 1…2)")
        err += test("b (x -1, y 2)")
        err += test("c (x 3, y 4)")
        err += test("d (x, y, z)")
        err += test("m (0, 0, 0), n >> m(1, 1, 1)")
        err += test("m (0, 0, 0), n(1, 1, 1) >> m")
        err += test("e (x -16…16, y -16…16)")
        err += test("f (p 0…1, q 0…1, r 0…1)")
        err += test("g (p 0…1~0.5, q 0…1~0.5, r 0…1~0.5)")
        err += test("h (p 0…1~0.5, q 0…1~0.5, r 0…1~0.5)")
        err += test("i (0…1~0.5, 0…1~0.5, 0…1~0.5)")
        err += test("j (one 1, two 2)")
        err += test("k (one \"1\", two \"2\")")
        XCTAssertEqual(err, 0)
    }

    func testParsePaths() { headline(#function)
        var err=0

        err += test("a { b c } a˚.{ d(0…1) >> a˚.on(2) }",
                    "a { b { d(0…1) >> a˚.on(2) } c { d(0…1) >> a˚.on(2) } }")

        err += test("aa { a(1) } bb@aa { a(2) }")
        
        err += test("a { b { c { c1 c2 } d } } a e",
                    "a { b { c { c1 c2 } d } } e")

        err += test("a { b { c d } } a { e }",
                    "a { b { c d } e }")

        err += test("a { b { c d } b.e }",
                    "a { b { c d e } }")

        err += test("a { b { c d } b.e.f }",
                    "a { b { c d e { f } } }")

        err += test("a.b.c.d { e.f }",
                    "a { b { c { d { e { f } } } } }")

        err += test("a { b { c { c1 c2 } d } b.c { c3 } }",
                    "a { b { c { c1 c2 c3 } d } }")

        subhead("copyAt")

        err += test("a { b { c { c1 c2 } d { d1 d2 } } b.c@b.d  }",
                    "a { b { c { c1 c2 d1 d2 } d { d1 d2 } } }")

        err += test("a { b { c d } } a@e", // no e
                    "a { b { c d } e }")

        subhead("override values")

        err += test("a { b { c { c1 c2 } d } b.c { c2(2) c3 } }",
                    "a { b { c { c1 c2(2) c3 } d } }")

        err += test("ab { a(1) b(2) } cd@ ab { a(3) c(4) d(5) }      ef@ cd {      b(6)      d(7) e(8) f(9) }",
                    "ab { a(1) b(2) } cd@ ab { a(3) b(2) c(4) d(5) } ef@ cd { a(3) b(6) c(4) d(7) e(8) f(9) }")

        err += test("ab { a(1) b(2) } ab { c(4) d(5) }",
                    "ab { a(1) b(2) c(4) d(5) }")

        subhead("decorate leaves (˚.)")

        err += test("ab { a(1) b(2) } cd { c(4) d(5) } ab˚.@ cd",
                    "ab { a(1) { c(4) d(5) } b(2) { c(4) d(5) } } cd { c(4) d(5) }")

        subhead("merge copyAt (d@_c)")

        err += test("a.b   { _c { c1 c2 } d@_c {       d1 d2 } }",
                    "a { b { _c { c1 c2 } d@_c { c1 c2 d1 d2 } } }")

        err += test("a.b   { _c { c1 c2 } d     { d1 d2 }@ _c }",
                    "a { b { _c { c1 c2 } d@ _c { d1 d2 c1 c2 } } }")

        XCTAssertEqual(err, 0)
    }

    func testParseEdges() { headline(#function)
        var err = 0

        err += test("a b c << b")
        err += test("a, b, c >> b")

        err += test("a { a1, a2 } w << a.* ",
                    "a { a1, a2 } w << (a.a1, a.a2)")

        err += test("a { b { c } } a <> .* ",
                    "a <> a.b { b { c } }")

        err += test("a { b { c } } a.b <> c ",
                    "a { b <> a.b.c { c } }")

        err += test("a { b { c } } a˚˚ <> .* ",
                    "a <> a.b { b <> a.b.c { c } } a˚˚ <> .*")

        err += test("a { b { c } } ˚˚ <> .. ",
                    "a <> √ { b <> a { c <> a.b } } ˚˚ <> ..")

        subhead("multi edge")

        err += test("a << (b c)")

        err += test("a << (b c) { b c }",
                    "a << (a.b, a.c) { b c }")

        err += test("a >> (b c) { b c }",
                    "a >> (a.b, a.c) { b c }")

        subhead("copyat edge")

        err += test("a {b c} z@a ←@a ",
                    "a { b c } z@a ←@a { b ←@ a.b c ←@ a.c }")

        err += test("a {b c}.{d e} z@a ←@ a",
        """
        a { b { d e } c { d e } }
          z@a ←@a { b ←@ a.b { d ←@ a.b.d e ←@ a.b.e }
                    c ←@ a.c { d ←@ a.c.d e ←@ a.c.e } }
        """)

        XCTAssertEqual(err, 0)
    }

    func testParseRelativePaths() { headline(#function)
        var err = 0
        err += test("d {a1 a2}.{b1 b2} e << d˚b1",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e << (d.a1.b1, d.a2.b1)")

        err += test("d {a1 a2}.{b1 b2} e << d˚˚",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e << (d, d.a1, d.a1.b1, d.a1.b2, d.a2, d.a2.b1, d.a2.b2)")


        XCTAssertEqual(err, 0)
    }

    /// test `b >> a(2)` for `b!`
    func testEdgeVal1() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(1) b >> a(2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            b.activate(Visitor(.model))
            err = ParStr.testCompare("a(2) b >> a(2)", root.scriptNow)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `b >> a.*(2)` for `b!`
    func testEdgeVal2() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {a1 a2} b >> a.*(2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            b.activate(Visitor(.model))
            let result = root.scriptRoot([.parens, .now, .edge])
            err = ParStr.testCompare("a { a1(2) a2(2) } b >> (a.a1(2), a.a2(2))", result)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a {b c}.{f g}`
    func testEdgeVal3a() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g}"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script) {
            let result = root.scriptRoot([.parens, .now])
            err += ParStr.testCompare("a { b { f g } c { f g } }", result)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a {b c}.{f g} z >> a˚g(2)`
    func testEdgeVal3b() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g} z >> a˚g(2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           //let a =  root.findPath("a"),
           let z =  root.findPath("z") {
            z.activate(Visitor(.model))
            let result = root.scriptRoot([.parens, .now, .edge])
            err += ParStr.testCompare("a { b { f g(2) } c { f g(2) } } z >> (a.b.g(2), a.c.g(2))", result)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z >> a.b.f(1) >> a˚g(2)`
    func testEdgeVal4a() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g} z >> a˚g(2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let z =  root.findPath("z") {

            z.activate(Visitor(.model))

            err += ParStr.testCompare(
            """
            a { b { f g(2) } c { f g(2) } } z >> (a.b.g(2), a.c.g(2))
            """, root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z >> a.b.f(1) >> a˚g(2)`
    func testEdgeVal4b() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b c}.{f g} z >> (a.b.f(1) a˚g(2))"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let z =  root.findPath("z") {

            z.activate(Visitor(.model))

            err += ParStr.testCompare(
            """
            a { b { f(1) g(2) }
                c { f g(2) } }
            z >> (a.b.f(1), a.b.g(2), a.c.g(2))
            """, root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z @ b,c
    func testCopyAt() { headline(#function)
        var err = 0
        err += test("a { b.bb c.cc z @ b,c }",
                    "a { b { bb } c { cc } z @ b,c { bb cc } }")
        XCTAssertEqual(err, 0)
    }

    /// test `a{b(1)} c@a` for copy `b`
    func testCopyAt0() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a { b(1) } c@a <@a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let c = root.findPath("c"),
           let ab = a.findPath("b"),
           let cb = c.findPath("b") {

            if let abv = ab.val?.nameAny.values.first as? FloValScalar,
               let acv = cb.val?.nameAny.values.first as? FloValScalar,
               abv.id == acv.id {
                err += 1
            }
            err += ParStr.testCompare("a.b(1) c @a ←@ a.b(1) ←@ a.b", root.scriptAll)

            ab.setAny(2, .activate)
            err += ParStr.testCompare("a.b(2) c @a ←@ a.b(2) ←@ a.b", root.scriptAll)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z@a ←@a`
    func testCopyAt1() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b(1) c(2)}.{d(3) e(4)} z @a ←@a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
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

            err += ParStr.testCompare("""
            a        { b(1)        { d(3)          e(4)          }
                       c(2)        { d(3)          e(4)          } }
            z @a ←@a { b(1) ←@ a.b { d(3) ←@ a.b.d e(4) ←@ a.b.e }
                       c(2) ←@ a.c { d(3) ←@ a.c.d e(4) ←@ a.c.e } }
            """, root.scriptAll)

            ab.setAny (10, .activate)
            err += ParStr.testCompare("a.b(10) z.b(10)", root.scriptDelta)

            ac.setAny (20, .activate)
            err += ParStr.testCompare("a{b(10) c(20)} z{b(10) c(20)}" ,root.scriptDelta)

            abd.setAny(30, .activate)
            abe.setAny(40, .activate)
            acd.setAny(50, .activate)
            ace.setAny(50, .activate)
            err += ParStr.testCompare("""
            a       { b(10)        { d(30)          e(40)          }
                      c(20)        { d(50)          e(50)          }}
            z@a ←@a { b(10) ←@ a.b { d(30) ←@ a.b.d e(40) ←@ a.b.e }
                      c(20) ←@ a.c { d(50) ←@ a.c.d e(50) ←@ a.c.e }}
            """, root.scriptAll)

            zb.setAny (11, .activate)
            zc.setAny (22, .activate)
            zbd.setAny(33, .activate)
            zbe.setAny(44, .activate)
            zcd.setAny(55, .activate)
            zce.setAny(66, .activate)
            err += ParStr.testCompare("""
             a      { b(10)        { d(30)          e(40)          }
                      c(20)        { d(50)          e(50)          }}
            z@a ←@a { b(11) ←@ a.b { d(33) ←@ a.b.d e(44) ←@ a.b.e }
                      c(22) ←@ a.c { d(55) ←@ a.c.d e(66) ←@ a.c.e }}
            """, root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z@a ←@→ a`
    func testCopyAt2() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a {b(1) c(2)}.{d(3) e(4)} z@a ←@→ a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
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

            ab.setAny (10, .activate)
            ac.setAny (20, .activate)
            abd.setAny(30, .activate)
            abe.setAny(40, .activate)
            acd.setAny(50, .activate)
            ace.setAny(60, .activate)

            err += ParStr.testCompare("""
            a {         b(10)         { d(30)           e(40)           }
                        c(20)         { d(50)           e(60)           }}
            z@a ←@→ a { b(10) ←@→ a.b { d(30) ←@→ a.b.d e(40) ←@→ a.b.e }
                        c(20) ←@→ a.c { d(50) ←@→ a.c.d e(60) ←@→ a.c.e }}
            """, root.scriptAll)

            zb.setAny (11, .activate)
            zc.setAny (22, .activate)
            zbd.setAny(33, .activate)
            zbe.setAny(44, .activate)
            zcd.setAny(55, .activate)
            zce.setAny(66, .activate)
            
            err += ParStr.testCompare("""
            a        { b(11)         { d(33)           e(44)           }
                       c(22)         { d(55)           e(66)           }}
            z@a ←@→a { b(11) ←@→ a.b { d(33) ←@→ a.b.d e(44) ←@→ a.b.e }
                       c(22) ←@→ a.c { d(55) ←@→ a.c.d e(66) ←@→ a.c.e }}
            """, root.scriptAll)
            
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    func testFilter() { headline(#function)
        Par.trace = true
        var err = 0

        let script = "a(x==10, y)<<b b(x:0,y:0)"

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let  b = root.findPath("b") {

            err += ParStr.testCompare("a(x==10, y)<<b b(x:0,y:0)", root.scriptAll)

            b.setAny(FloValExprs(Flo("_t_"), [("x", 0), ("y",0)]), .activate)
            err += ParStr.testCompare("a(x==10, y)<<b b(x:0, y:0)", root.scriptAll)

            b.setAny(FloValExprs(Flo("_t_"), [("x", 10), ("y",20)]), .activate)
            err += ParStr.testCompare("a(x==10, y: 20)<<b b(x: 10, y: 20)", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    func testFilter0() { headline(#function)
        Par.trace = true
        var err = 0

        err += test("a (w == 0, x:1, y:0)")

        err += test("a (w:0, x:1, y:0)")

        err += test("a {b c}.{ d(1) e(2) }",
                    "a { b { d(1) e(2) } c { d(1) e(2) } }")

        err += test("a {b c}.{ d(x:1) e(y:2) }",
                    "a { b { d(x:1) e(y:2) } c { d(x:1) e(y:2) } }")

        err += test("""
                    a {b c}.{ d(x:1) e(y:2) } w(x:0, y:0, z:0)
                    """,
                    """
                    a { b { d (x:1) e (y:2) }
                        c { d (x:1) e (y:2) } }
                    w (x:0, y:0, z:0)
                    """)

        err += test("""
                    a {b c}.{ d(x == 10, y:0, z:0) e(x:0, y == 21, z:0) }
                    """,
                    """
                    a { b { d (x == 10, y:0, z:0) e (x:0, y == 21, z:0) }
                        c { d (x == 10, y:0, z:0) e (x:0, y == 21, z:0) } }
                    """)

        err += test("""
                    a {b c}.{ d(x == 10, y:0, z:0) e(x:0, y == 21, z:0) } w(x:0, y:0, z:0) <> a˚.
                    """,
                    """
                    a { b { d (x == 10, y:0, z:0) e (x:0, y == 21, z:0) }
                        c { d (x == 10, y:0, z:0) e (x:0, y == 21, z:0) } }
                    w (x:0, y:0, z:0) <> (a.b.d, a.b.e, a.c.d, a.c.e)
                    """)
        XCTAssertEqual(err, 0)
    }

    func testFilter1() { headline(#function)
        Par.trace = true
        var err = 0

        let script = """
        a {b c}.{ d(x == 10, y: 0, z: 0)
                  e(x: 0, y == 21, z: 0) }
                  w(x: 0, y: 0, z: 0) <> a˚."
        """
        let root = Flo("√")

        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let ab = root.findPath("a.b"),
           let abd = root.findPath("a.b.d"),
           let ac = root.findPath("a.c"),
           let acd = root.findPath("a.c.d"),
           let w = root.findPath("w") {

            err += ParStr.testCompare("""
            a { b { d(x==10, y: 0, z: 0) e(x: 0, y==21, z: 0) }
                c { d(x==10, y: 0, z: 0) e(x: 0, y==21, z: 0) } }
                    w(x: 0,  y: 0, z: 0) <>( a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

            // 0, 0, 0 --------------------------------------------------

            w.setAny(FloValExprs(Flo("_t0_"), [("x", 0), ("y", 0), ("z", 0)]), .activate)
            err += ParStr.testCompare("""
            a { b { d(x==10, y: 0, z: 0)  e(x: 0, y==21, z: 0) }
                c { d(x==10, y: 0, z: 0)  e(x: 0, y==21, z: 0) } }
                    w(x:0,   y: 0, z: 0) <>(a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)


            // 10, 11, 12 --------------------------------------------------
            w.setAny(FloValExprs(Flo("_t1_"), [("x", 10), ("y", 11), ("z", 12)]), .activate)
            err += ParStr.testCompare("""
            a { b { d(x==10, y: 11, z: 12) e(x: 0, y==21, z: 0) }
                c { d(x==10, y: 11, z: 12) e(x: 0, y==21, z: 0) } }
                    w(x: 10, y: 11, z: 12) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)


            // 20, 21, 22 --------------------------------------------------
            // when match fails, the values revert back to original declaration
            w.setAny(FloValExprs(Flo("_t2_"), [("x", 20), ("y", 21), ("z", 22)]), .activate)
            err += ParStr.testCompare("""
            a { b { d(x == 10, y: 0, z: 0) e(x: 20, y == 21, z: 22) }
                c { d(x == 10, y: 0, z: 0) e(x: 20, y == 21, z: 22) } }
                    w(x: 20, y: 21, z: 22) <> ( a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

            // 10, 21, 33 --------------------------------------------------
            w.setAny( FloValExprs(Flo("_t3_"), [("x", 10), ("y", 21), ("z", 33)]), .activate)
            err += ParStr.testCompare("""
            a { b { d(x==10, y: 21, z: 33) e(x: 10, y==21, z: 33) }
                c { d(x==10, y: 21, z: 33) e(x: 10, y==21, z: 33) } }
                    w(x: 10, y: 21, z: 33) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    func testFilter2() { headline(#function)
        Par.trace = true
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = """
        a {b c}.{ d(x == 10, y, z) e(x, y == 21, z) }
                  w(x, y, z) <> a˚."
        """
        let root = Flo("√")

        if floParse.parseScript(root, script),
           let w = root.findPath("w") {

            // 0, 0, 0 --------------------------------------------------

            w.setAny(FloValExprs(Flo("_t0_"), [("x", 0), ("y", 0), ("z", 0)]), .activate)

            err += ParStr.testCompare("""

            a { b { d(x == 10, y, z) e(x, y == 21, z) }
                c { d(x == 10, y, z) e(x, y == 21, z) } }
                    w(x: 0, y: 0, z: 0) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

            // 10, 11, 12 --------------------------------------------------

            w.setAny(FloValExprs(Flo("_t1_"), [("x", 10), ("y", 11), ("z", 12)]), .activate)

            err += ParStr.testCompare("""

            a { b { d(x==10, y: 11, z: 12) e(x, y==21, z) }
                c { d(x==10, y: 11, z: 12) e(x, y==21, z) } }
                    w(x: 10, y: 11, z: 12) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

            // 20, 21, 22 --------------------------------------------------

            w.setAny( FloValExprs(Flo("_t2_"), [("x", 20), ("y", 21), ("z", 22)]), .activate)

            err += ParStr.testCompare("""

            a { b { d(x==10, y, z) e(x: 20, y==21, z: 22) }
                c { d(x==10, y, z) e(x: 20, y==21, z: 22) } }
                    w(x: 20, y: 21,z: 22) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

            // 10, 21, 33 --------------------------------------------------

            w.setAny(FloValExprs(Flo("_t3_"), [("x", 10), ("y", 21), ("z", 33)]), .activate)

            err += ParStr.testCompare("""
            
            a { b { d(x==10, y: 21, z: 33) e(x: 10, y==21, z: 33) }
                c { d(x==10, y: 21, z: 33) e(x: 10, y==21, z: 33) } }
                    w(x: 10, y: 21, z: 33) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """, root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    //MARK: - Expressions

    /// test `a(x,y) << b, b(x:0, y:0)
    func testExpr0() { headline(#function)

        var err = 0

        let script = "a(x, y) << b, b(x 0, y 0)"

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            err += ParStr.testCompare("a(x, y) << b, b(x:0, y:0)", root.scriptNow)

            b.setAny(CGPoint(x: 1, y: 2), .activate)
            err += ParStr.testCompare("a(x: 1, y: 2) << b, b(x: 1, y: 2)", root.scriptNow)
            err += ParStr.testCompare("a(x, y) << b, b(x 1, y 2)", root.scriptDef)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    /// test `a(x:0) << c, b(y:0) << c, c(x:0, y:0)`
    func testExpr1() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x: 0) << c,  c(x: 0, y: 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let c = root.findPath("c") {

            c.setAny(CGPoint(x: 1, y: 2), .activate)
            err = ParStr.testCompare("a(x:1) << c, c(x:1, y:2)", root.scriptNow)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x:0) << c, b(y:0) << c, c(x:0, y:0)`
    func testExpr2() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x: 0) << c, b(y: 0) << c, c(x: 0, y: 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let c = root.findPath("c") {

            let p = CGPoint(x: 1, y: 2)
            c.setAny(p, .activate)

            err += ParStr.testCompare("a(x:1) << c, b(y:2) << c, c(x:1, y:2)", root.scriptNow)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    /// test `a(x:0…2, y:0…2, z:99), b (x:0…2, y:0…2) << a`
    func testClosure() { headline(#function)
        Par.trace = true
        Par.trace2 = false
        var err = 0

        let script = "a(x:0…2, y:0…2)"

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a") {

            let p0 = CGPoint(x:1, y:1)
            var p1 = CGPoint.zero

            a.addClosure { flo, _ in p1 = flo.cgPoint }
            a.setAny(p0, .activate)
            print("p0:\(p0) => p1:\(p1)")
            err += (p0 == p1) ? 0 : 1

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
        Par.trace = false
        Par.trace2 = false
    }

    /// test `a(x:0…2, y:0…2, z:99), b (x:0…2, y:0…2) << a`
    func testExpr3() { headline(#function)
        Par.trace = true
        Par.trace2 = false
        var err = 0

        let script = "a(x:0…2, y:0…2, z:99), b(x:0…2, y:0…2) << a"

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a") {

            a.setAny(CGPoint(x: 1, y: 1), .activate)

            err += ParStr.testCompare(
                "a(x:0…2, y:0…2, z:99), b(x:0…2, y:0…2) << a", root.scriptDef)
            //⟹ a(x:0…2, y:0…2, z🚫), b(x:0…2, y:0…2)<<a

            err += ParStr.testCompare("a(x:1, y:1, z:99), b(x:1, y:1) << a", root.scriptNow)
            err += ParStr.testCompare("a(x:0…2:1,y:0…2:1,z:99), b(x:0…2:1,y:0…2:1)<<a", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
        Par.trace = false
        Par.trace2 = false
    }

    /// test `a(x in:2…4, y in:3…5) >> b b(x:1…2, y:2…3)`
    func testExpr4() { headline(#function)
        Par.trace = true
        Par.trace2 = false
        var err = 0

        let script = "a(x in 2…4, y in 3…5) >> b b(x:1…2, y:2…3)"

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a") {

            err += ParStr.testCompare("a(x in 2…4, y in 3…5)>>b  b(x:1…2,y:2…3)", root.scriptAll)
            err += ParStr.testCompare("a(x, y) >>  b b(x, y)", root.scriptNow)

            // will fail expression, so no current values
            a.setAny(CGPoint(x: 1, y: 4), .activate)
            err += ParStr.testCompare("a(x in 2…4, y in 3…5) >> b b(x: 1…2, y: 2…3)", root.scriptAll)

            // will pass express, so include current value
            a.setAny(CGPoint(x: 3, y: 4), .activate)
            err += ParStr.testCompare("a(x in 2…4: 3, y in 3…5: 4) >> b b(x: 1…2: 1.5, y: 2…3: 2.5)", root.scriptAll)

            err += ParStr.testCompare("a(x: 3, y: 4) >> b b(x: 1.5, y: 2.5)", root.scriptNow)

            // will fail, so clear out current values for a
            a.setAny(CGPoint(x:1, y:4), .activate)
            err += ParStr.testCompare("a(x, y)>>b b(x:1.5, y:2.5)", root.scriptNow)


        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
        Par.trace = false
        Par.trace2 = false
    }

    /// test `b(sum: x + y + z) << a`
    func testExpr5() { headline(#function)
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = "a(x: 10, y: 20, z: 30), b(sum: x + y + z) << a, c(x + y + z) << a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script, tracePar: false),
           let a = root.findPath("a") {

            a.setAny(FloValExprs(Flo("_t_"), [("x", 1), ("y", 2), ("z", 3)]), .activate)

            err += ParStr.testCompare("a(x: 1, y: 2, z: 3), b(sum: x + y + z: 6) << a, c(x + y + z) << a", root.scriptAll)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `b(sum: x + y + z) << a`
    func testExpr6() { headline(#function)
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = "a(x:10, y:20, z:30), b(x < 0.9, y, z) << a, c(x > 0, y, z) << a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script, tracePar: false),
           let a = root.findPath("a") {

            err += ParStr.testCompare( "a(x:10, y:20, z:30), b(x<0.9,y,z)<<a, c(x>0,y,z)<<a", root.scriptAll)

            a.setAny(FloValExprs(Flo("_t_"), [("x", 1), ("y", 2), ("z", 3)]), .activate)
            err += ParStr.testCompare( "a(x:1,y:2,z:3), b(x<0.9,y,z)<<a, c(x>0:1,y:2,z:3)<<a", root.scriptAll)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    //MARK: - assign

    /// test `a(x, y) b(v:0) >> a(x:v)
    func testAssign0() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v:0) >> a(x:v)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b"),
           let a = root.findPath("a") {

            err += ParStr.testCompare("a(x, y) b(v:0) >> a(x:v)", root.scriptDef)

            b.setAny(FloValExprs(Flo("_t_"), [("v", 1)]), .activate)
            err += ParStr.testCompare( "a(x:1, y) b(v:1) >> a(x:v:1)", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x, y) b(v:0) >> a(x: v/2, y: v*2)`
    func testAssign1() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v: 0) >> a(x: v/2, y: v*2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
            let a = root.findPath("a"),
            let b = root.findPath("b") {

            err += ParStr.testCompare("a(x, y) b(v:0) >> a(x: v/2, y: v*2)", root.scriptAll)

            b.setAny(FloValExprs(Flo("_t_"), [("v", 1)]), .activate)
            err += ParStr.testCompare("a(x: 0.5, y: 2) b(v: 1) >> a(x: v/2:0.5, y: v*2:2)", root.scriptAll)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }



    //MARK: - Midi

    /// test `grid(x: num/12, y: num % 12) << note, note(num: 0…127 = 50)`
    func testMidiGrid() { headline(#function)
        var err = 0
        let script = "grid(x: num / 12, y: num % 12) << note, note(num: 50)"

        let root = Flo("√")
        if floParse.parseScript(root, script, tracePar: false) {

            err += ParStr.testCompare( "grid(x:num/12, y:num%12) << note, note(num:50)", root.scriptAll)

            if let note = root.findPath("note"),
            let grid = root.findPath("note") {

                note.setAny(FloValExprs(Flo("_t_"), [("num", 50)]), .activate)
                err += ParStr.testCompare("grid(x: 4.166667, y: 2) << note, note(num: 50)", root.scriptNow)
            } else {
                err += 1
            }

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }
    
    /// test `grid(num>20, chan==1 x:num/12, y: num%12)<<note ...
    func testMidiFilter() { headline(#function)
        var err = 0

        let script = """
        grid(num > 20, chan==1, x: num / 12, y: num % 12) << note,
        note(num:0_127:0, chan: 2)
        """

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let grid = root.findPath("grid"),
           let note = root.findPath("note") {

            note.setAny(FloValExprs(Flo("_t1_"),[("num",50), ("chan",0)]), .activate)
            err += ParStr.testCompare("""
                grid(num > 20, chan==1, x: num / 12, y: num % 12) << note,
                note(num: 0_127: 50, chan: 0)
                """, root.scriptAll)

            note.setAny( FloValExprs(Flo("_t2_"),[("num",50), ("chan",1)]), .activate)
            err += ParStr.testCompare("""
                grid(num > 20 :50, chan==1, x: num / 12 :4.166667, y: num % 12 :2) << note,
                note(num:0_127 :50, chan:1)
                """, root.scriptAll)

        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    // MARK: - pasthrough

    /// test `a(0…1)<<b, b<<c, c(0…10)<<a`
    func testPassthrough() { headline(#function)
        var err = 0
        let script = "a(0…1)<<b, b<<c, c(0…10)<<a"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let b = root.findPath("b"),
           let c = root.findPath("c") {

            c.setAny(5.0, .activate)
            err += ParStr.testCompare("a(0.5) b(5) c(5)",root.scriptCompact([.now, .comnt]))

            a.setAny(0.1, .activate)
            err += ParStr.testCompare("a(0.1) b(1) c(1)",root.scriptCompact([.now, .comnt]))

            b.setAny(0.2, .activate)
            err += ParStr.testCompare("a(0.02) b(0.2) c(0.2)",root.scriptCompact([.now, .comnt]))
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    //MARK: - Scripts

    /// D3.js script for force directed graph
    func testD3Script() { headline(#function)
        var err = 0
        let root = Flo("√")
        let script = "a.b.c(1) d { e(2) <> a.b.c } f@d"

        if floParse.parseScript(root, script) {

            err += ParStr.testCompare("a.b.c(1) d.e(2) <> a.b.c f.e(2) <> a.b.c", root.scriptNow)

            let d3Script = root.makeD3Script()
            print(d3Script)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test Avatar and Robot definitions
    func testBodySkeleton() { headline(#function)

        var err = 0
        err += testFile("test.body.input", out: "test.body.output")
        err += testFile("test.skeleton.input",  out: "test.skeleton.output", full: true)
        XCTAssertEqual(err, 0)


    }

    //    func testMidi() { headline(#function)
    //        var err = 0
    //        err += testSkyFile("midi",  out: "test.midi.output")
    //        XCTAssertEqual(err, 0)
    //    }
    //
    //    func testShader() { headline(#function)
    //        var err = 0
    //        err += testSkyFile("shader",  out: "test.shader.output")
    //        XCTAssertEqual(err, 0)
    //    }
    //
    //    /// test `DeepMuse` app script
    //    func testMuseSky() { headline(#function)
    //
    //        let root = Flo("√")
    //        var err = 0
    //        err += parseSky("sky", root)
    //        err += parseSky("menu", root)
    //        err += parseSky("shader", root)
    //
    //        let actual = root.scriptRoot([.parens, .def, .edge, .comment, .noLF])
    //        let expect = readSky("test.sky.output") ?? ""
    //        err += ParStr.testCompare(expect, actual)
    //
    //        XCTAssertEqual(err, 0)
    //    }

    // MARK: - all tests

    static var allTests = [

        ("testParseShort", testParseShort),
        ("testParseBasics", testParseBasics),
        ("testParsePathCopy", testParsePathCopy),
        ("testParsePaths", testParsePaths),
        ("testParseValues", testParseValues),
        ("testParseEdges", testParseEdges),
        ("testParseRelativePaths", testParseRelativePaths),

        ("testEdgeVal1", testEdgeVal1),
        ("testEdgeVal2", testEdgeVal2),
        ("testEdgeVal3a", testEdgeVal3a),
        ("testEdgeVal3b", testEdgeVal3b),
        ("testEdgeVal4b", testEdgeVal4b),

        ("testCopyAt", testCopyAt),
        ("testCopyAt1", testCopyAt1),
        ("testCopyAt2", testCopyAt2),
        ("testExpr1", testExpr1),
        ("testExpr2", testExpr2),
        ("testExpr3", testExpr3),
        ("testExpr4", testExpr4),
        ("testExpr5", testExpr5),

        ("testPassthrough", testPassthrough),
        ("testD3Script", testD3Script),
        ("testBodySkeleton", testBodySkeleton),
        //?? ("testMidi", testMidi),
        //?? ("testMuseSky", testMuseSky),
    ]
}
