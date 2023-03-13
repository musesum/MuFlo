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
              _ scriptOps: FloScriptOps = [.parens, .edge, .comment, .copyAt, .def]) -> Int {

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
    func testParse(_ inScript: String, _ outScript: String) -> Int {

        let root = Flo("√")

        if floParse.parseScript(root, inScript, whitespace: "\n\t ") {
            print (name +  " ✓")
            let actual = root.scriptCompactRoot([.parens, .def, .compact, .edge, .comment])
            let err = ParStr.testCompare(outScript, actual)
            return err
        } else {
            return 1 // error
        }
    }
    func testFile(_ input: String, out: String) -> Int {

        if let inScript = read(input) {
           let outScript = read(out) ?? inScript
            return testParse(inScript, outScript)
        } else {
            return 1 // error
        }
    }

    func testPretty() {
        let root = Flo("√")
        let script = "a { b { // oy\n c // yo\n d } e }"
        if floParse.parseScript(root, script, whitespace: "\n\t ") {
            let result = root.script(.compact)
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

        err += test("a(0…1=0:1)", nil, [.parens, .def, .now])

        err += test("cell.one(1).two(2).three(3)", nil, [.parens, .now, .compact])

        err += test("a b c a << (b ? c : 0)",
                    "a <<(b ? c : 0) b⟐→a c⟐→a",
                    [.parens, .def, .now, .edge])

        err += test("a(0…1=0:1)", nil, [.parens, .def, .now])
        err += test("b(0…1)")
        err += test("c(0…1:1)", nil, [.parens, .now, .def])
        err += test("a(1) b >> a(2)")

        err += test("a(\"b\")")
        err += test("a.b c@a", "a { b } c@a { b }")
        err += test("b(x / 2) a << b(x / 2)")
        err += test("a b << a(* 10)")
        err += test("a (x 1, y 2)")
        err += test("m (1, 2, 3), n >> m(4, 5, 6)")
        
        err += test("a { b c } a.*{ d }",
                    "a { b { d } c { d } }")

        err += test("a { b c } a.* { d(0…1) >> a˚on(0) }",
                    "a { b { d(0…1) >> a˚on(0) } c { d(0…1) >> a˚on(0) } }")

        err += test("a { b c } a˚.{ d(0…1) >> a˚.on(0) }",
                    "a { b { d(0…1) >> a˚.on(0) } c { d(0…1) >> a˚.on(0) } }")

        err += test("i(0…1=0.5, 0…1=0.5, 0…1=0.5)")

        err += test(
            /**/"abcdefghijklmnopqrstu1 abcdefghijklmnopqrstu2")

        err += test("a { b { c(1) } } a.b.c(2)", "a { b { c(2) } }")

        err += test(
            /**/"a { b { c(1) } } z@a { b.c(2) }",
                "a { b { c(1) } } z@a { b { c(2) } }")

        err += test("a b c⟡→a")

        err += test("a b c d a << (b ? c : d)",
                    "a <<(b ? c : d ) b⟐→a c⟐→a d⟐→a ")

        err += test("value(16777200)")
        err += test("value(1.67772e+07)", "value(16777200)")

        err += test("a.b.c(0…1) z@a { b.c(0…1=1) }",
                    "a { b { c(0…1) } } z@a { b { c(0…1=1) } }")

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

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? f.j : 0) ",
                    "a { b { d { f << (f.i ? f.j : 0) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }" +
                    "        e { f << (f.i ? f.j : 0) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }" +
                    "    c { d { f { i j } g { i j } }" +
                    "        e { f { i j } g { i j } } } } a.b˚f << (f.i ? f.j : 0 )" +
                    "")

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? f.j : 0) ",
                    "a { b { d { f << (f.i ? f.j : 0) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }" +
                    "        e { f << (f.i ? f.j : 0) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }" +
                    "    c { d { f { i j } g { i j } }" +
                    "        e { f { i j } g { i j } } } } a.b˚f << (f.i ? f.j : 0 )" +
                    "")

        err += test("a {b c}.{d << (b ? 1 | c ? 2) e } z@a z.b.d << (b ? 5 | c ? 6)",
                    "  a { b⟐→(a.b.d, a.c.d) { d << (b ? 1 | c ? 2) e } " +
                    "      c⟐→(a.b.d, a.c.d) { d << (b ? 1 | c ? 2) e } } " +
                    "z@a{ b⟐→(z.b.d, z.c.d) { d << (b ? 5 | c ? 6) e } " +
                    "      c⟐→(z.b.d, z.c.d) { d << (b ? 1 | c ? 2) e } }" +
                    "")


        err += test("a b >> a(1)")

        err += test("a << (b c)")

        err += test("a, b.c << (a ? 1) d@b ",
                    "a⟐→(b.c, d.c), b { c << (a ? 1 ) } d@b { c << (a ? 1 ) } ")
        
        err += test("a {b << (a ? 1) c} ",
                    "a⟐→a.b { b << (a ? 1 ) c }")
        
        err += test("a {b c}.{d << (b ? 1 | c ? 2) e} ",
                    "a { b⟐→(a.b.d, a.c.d) { d << (b ? 1 | c ? 2) e } " +
                    /**/"c⟐→(a.b.d, a.c.d) { d << (b ? 1 | c ? 2) e } }")

        err += test("a b c w << (a ? 1 : b ? 2 : c ? 3)",
                    "a⟐→w b◇→w c◇→w w << (a ? 1 : b ? 2 : c ? 3)")

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

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? f.j : 0) ",
                    "a { b { d { f << (f.i ? f.j : 0 ) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }" +
                    "        e { f << (f.i ? f.j : 0 ) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }" +
                    "    c { d { f { i j } g { i j } }" +
                    "        e { f { i j } g { i j } } } } a.b˚f << (f.i ? f.j : 0 )" +
                    "", [.parens, .edge, .comment, .copyAt, .def, .now])

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
        err += test("i (1…2=1.5, 3…4=3.5, 5…6=5.5)")
        err += test("b (x 1, y 2)")
        err += test("b (x 1, y 2)")
        err += test("a (%2)")
        err += test("a (x 1…2, y 1…2)")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")
        err += test("a (0…1=0.5) { b(1…2) { c(2…3) } }")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")

        subhead("flo scalars")
        err += test("a { b(2) { c } }")
        err += test("a (1) { b(2) { c(3) } }")
        err += test("a (0…1=0.5) { b(1…2) { c(2…3) } }")
        err += test("a (%2) b(%2)")

       subhead("flo tuples")
        err += test("a (x 0…1=0.5, y 0…1=0.5)")
        err += test("a (x 1…2, y 1…2)")
        err += test("b (x -1, y 2)")
        err += test("c (x 3, y 4)")
        err += test("d (x, y, z)")
        err += test("m (0, 0, 0), n >> m(1, 1, 1)")
        err += test("m (0, 0, 0), n(1, 1, 1) >> m")
        err += test("e (x -16…16, y -16…16)")
        err += test("f (p 0…1, q 0…1, r 0…1)")
        err += test("g (p 0…1=0.5, q 0…1=0.5, r 0…1=0.5)")
        err += test("h (p 0…1=0.5, q 0…1=0.5, r 0…1=0.5)")
        err += test("i (0…1=0.5, 0…1=0.5, 0…1=0.5)")
        err += test("j (one 1, two 2)")
        err += test("k (one \"1\", two \"2\")")
        XCTAssertEqual(err, 0)
    }

    func testParsePaths() { headline(#function)
        var err=0
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
                    "a << (a.b, a.c) { b c }") //TODO: ??

        err += test("a >> (b c) { b c }",
                    "a >> (a.b, a.c) { b c }") //TODO: ??

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

    func testParseTernarys() { headline(#function)
        var err = 0

        err += test("a b c << (a ? b)", "a⟐→c b◇→c c << (a ? b) ")
        err += test("a b x y w << (a ? 1 : b ? 2)", "a⟐→w b◇→w x y w << (a ? 1 : b ? 2) ")
        err += test("a, x, y, w << (a ? x : y)", "a⟐→w, x◇→w, y◇→w, w << (a ? x : y)")
        err += test("a, x, y, w >> (a ? x : y)", "a⟐→w, x←◇w, y←◇w, w >> (a ? x : y)")
        err += test("a(1), x, y, w << (a ? x : y)", "a(1)⟐→w, x⟐→w, y◇→w, w << (a ? x : y)")
        err += test("a(1), x, y, w >> (a ? x : y)", "a(1)⟐→w, x←⟐w, y←◇w, w >> (a ? x : y)")
        err += test("a(0), x, y, w << (a ? x : y)", "a(0)⟐→w, x◇→w,   y◇→w, w << (a ? x : y)")
        err += test("a(0), x, y, w >> (a ? x : y)", "a(0)⟐→w, x←◇w, y←◇w, w >> (a ? x : y)")
        err += test("a, x, y, w <>(a ? x : y)", "a⟐→w, x←◇→w, y←◇→w, w <> (a ? x : y)")
        err += test("a, b, x, y, w << (a ? x : b ? y)", "a⟐→w, b◇→w, x◇→w, y◇→w, w << (a ? x : b ? y)")
        err += test("a, b, x, y, w << (a ? 1 : b ? 2)", "a⟐→w, b◇→w, x, y, w << (a ? 1 : b ? 2)")
        err += test("a b c w << (a ? 1 : b ? 2 : c ? 3)","a⟐→w b◇→w c◇→w w<<(a ? 1 : b ? 2 : c ? 3)")
        err += test("a, b, c, w << (a ? 1 : b ? 2 : c ? 3)","a⟐→w, b◇→w, c◇→w, w << (a ? 1 : b ? 2 : c ? 3)")
        err += test("a, b, c, x << (a ? b ? c ? 3 : 2 : 1)","a⟐→x, b◇→x, c◇→x, x << (a ? b ? c ? 3 : 2 : 1)")
        err += test("a, b, c, y << (a ? (b ? (c ? 3) : 2) : 1)","a⟐→y, b◇→y, c◇→y, y << (a ? b ? c ? 3 : 2 : 1)")
        err += test("a, b, c, z << (a ? 1) << (b ? 2) << (c ? 3)","a⟐→z, b⟐→z, c⟐→z, z << (a ? 1) << (b ? 2) << (c ? 3)")
        err += test("a, b, w << (a ? 1 : b ? 2 : 3)","a⟐→w, b◇→w, w << (a ? 1 : b ? 2 : 3)")
        err += test("a, b, w <> (a ? 1 : b ? 2 : 3)","a⟐→w, b◇→w, w <> (a ? 1 : b ? 2 : 3)"  )

        subhead("ternary conditionals")

        err += test("a1, b1, a2, b2, w << (a1 == a2 ? 1 : b1 == b2 ? 2 : 3)", //TODO b1◇→w
                    "a1⟐→w, b1◇→w, a2⟐→w, b2⟐→w, w << (a1 == a2 ? 1 : b1 == b2 ? 2 : 3 )")

        err += test("d {a1 a2}.{b1 b2}.{c1 c2} h << (d.a1 ? b1 ? c1 : 1)",
                    "d { a1⟐→h { b1◇→h { c1◇→h c2 } b2 { c1 c2 } } a2 { b1 { c1 c2 } b2 { c1 c2 } } } h << (d.a1 ? b1 ? c1 : 1)")

        subhead("ternary paths")

        err += test("a {b c}.{d e}.{f g} a << a˚d.g",
                    "a << (a.b.d.g, a.c.d.g) { b { d { f g } e { f g } } c { d { f g } e { f g } } }")

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i == f.j ? 1 : 0) ",
                    """
                    a { b { d { f << (f.i == f.j ? 1 : 0 ) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }
                            e { f << (f.i == f.j ? 1 : 0 ) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }
                        c { d { f { i j } g { i j } }
                            e { f { i j } g { i j } } } } a.b˚f << (f.i == f.j ? 1 : 0)
                    """)

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? f.j : 0) ",
                    """
                    a { b { d { f << (f.i ? f.j : 0 ) { i⟐→a.b.d.f j⟐→a.b.d.f } g { i j } }
                            e { f << (f.i ? f.j : 0 ) { i⟐→a.b.e.f j⟐→a.b.e.f } g { i j } } }
                        c { d { f { i j } g { i j } }
                            e { f { i j } g { i j } } } } a.b˚f << (f.i ? f.j : 0 )
                    """)

        subhead("ternary radio")

        err += test("a, b, c, x, y, z, w << (a ? 1 | b ? 2 | c ? 3)",
                    "a⟐→w, b⟐→w, c⟐→w, x, y, z, w << (a ? 1 | b ? 2 | c ? 3 ) ")

        err += test("a, b, c, x, y, z, w << (a ? x | b ? y | c ? z)",
                    "a⟐→w, b⟐→w, c⟐→w, x◇→w, y◇→w, z◇→w, w << (a ? x | b ? y | c ? z)")

        err += test("a, b, c, x, y, z, w <> (a ? x | b ? y | c ? z)",
                    "a⟐→w, b⟐→w, c⟐→w, x←◇→w, y←◇→w, z←◇→w, w <> (a ? x | b ? y | c ? z)")

        err += test("a {b c}.{d e}.{f g}.{i j} a.b˚f << (f.i ? 1 | a˚j ? 0)",
                    """
                    a { b { d { f << (f.i ? 1 | a˚j ? 0 ) { i⟐→a.b.d.f j⟐→(a.b.d.f, a.b.e.f) }
                                g { i j⟐→(a.b.d.f, a.b.e.f) } }
                            e { f << (f.i ? 1 | a˚j ? 0 ) { i⟐→a.b.e.f j⟐→(a.b.d.f, a.b.e.f) }
                                g { i j⟐→(a.b.d.f, a.b.e.f) } } }
                        c { d { f { i j⟐→(a.b.d.f, a.b.e.f) }
                                g { i j⟐→(a.b.d.f, a.b.e.f) } }
                            e { f { i j⟐→(a.b.d.f, a.b.e.f) }
                                g { i j⟐→(a.b.d.f, a.b.e.f) } } } }
                    a.b˚f << (f.i ? 1 | a˚j ? 0 )
                    """)
        XCTAssertEqual(err, 0)
    }

    func testParseRelativePaths() { headline(#function)
        var err = 0
        err += test("d {a1 a2}.{b1 b2} e << d˚b1",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e << (d.a1.b1, d.a2.b1)")

        err += test("d {a1 a2}.{b1 b2} e << d˚˚",
                    "d { a1 { b1 b2 } a2 { b1 b2 } } e << (d, d.a1, d.a1.b1, d.a1.b2, d.a2, d.a2.b1, d.a2.b2)")

        err += test("d {a1 a2}.{b1 b2} e << (d˚b1 ? d˚b2)",
                    "d { a1 { b1⟐→e b2◇→e } a2 { b1⟐→e b2◇→e } } e << (d˚b1 ? d˚b2)")

        err += test("d {a1 a2}.{b1 b2} e << (d.a1 ? a1.* : d.a2 ? a2.*)",
                    "d { a1⟐→e { b1◇→e b2◇→e } a2◇→e { b1◇→e b2◇→e } } e << (d.a1 ? a1.* : d.a2 ? a2.*)")

        err += test("d {a1 a2}.{b1 b2} e << (d.a1 ? .*   : d.a2 ? .*)",
                    "d { a1⟐→e { b1◇→e b2◇→e } a2◇→e { b1◇→e b2◇→e } } " +
                    "e << (d.a1 ? .* : d.a2 ? .*)")

        err += test("d {a1 a2}.{b1 b2} e << (d˚a1 ? a1˚. : d˚a2 ? a2˚.)",
                    "d { a1⟐→e { b1◇→e b2◇→e } a2◇→e { b1◇→e b2◇→e } } " +
                    "e << (d˚a1 ? a1˚. : d˚a2 ? a2˚.)")

        err += test("d {a1 a2}.{b1 b2}.{c1 c2} e << (d˚b1 ? b1˚. : d˚b2 ? b2˚.)",
                    "d { a1 { b1⟐→e { c1◇→e c2◇→e } b2◇→e { c1◇→e c2◇→e } } " +
                    "    a2 { b1⟐→e { c1◇→e c2◇→e } b2◇→e { c1◇→e c2◇→e } } } " +
                    "e<<(d˚b1 ? b1˚. : d˚b2 ? b2˚.)")

        err += test("d {a1 a2}.{b1 b2}.{c1 c2} e << (d˚b1 ? b1˚. | d˚b2 ? b2˚.)",
                    "d { a1 { b1⟐→e { c1◇→e c2◇→e } b2⟐→e { c1◇→e c2◇→e } } " +
                    "    a2 { b1⟐→e { c1◇→e c2◇→e } b2⟐→e { c1◇→e c2◇→e } } } " +
                    "e<<(d˚b1 ? b1˚. | d˚b2 ? b2˚.)")

        err += test("d {a1 a2}.{b1 b2}.{c1 c2} h << (d.a1 ? b1 ? c1 : 1)",
                    """
                    d { a1⟐→h { b1◇→h { c1◇→h c2 } b2 { c1 c2 } }
                        a2 { b1 { c1 c2 } b2 { c1 c2 } } }
                    h<<(d.a1 ? b1 ? c1 : 1)

                    """)

        err += test("""
                    d {a1 a2}.{b1 b2}.{c1 c2}
                    e << (d˚b1 ? b1˚. : d˚b2 ? b2˚.)
                    f << (d˚b1 ? b1˚. : b2˚.)
                    g << (d˚b1 ? b1˚.) <<(d˚b2 ? b2˚.)
                    h << (d.a1 ? b1 ? c1 : 1)
                    i << (d˚b1 ? b1˚. | d˚b2 ? b2˚.)
                    """,
                    """
                    d { a1⟐→h { b1⟐→(e, f, g, h, i) { c1◇→(e, f, g, h, i) c2◇→(e, f, g, i) }
                                b2◇→(e,    g,    i) { c1◇→(e, f, g,    i) c2◇→(e, f, g, i) } }
                        a2    { b1⟐→(e, f, g,    i) { c1◇→(e, f, g,    i) c2◇→(e, f, g, i) }
                                b2◇→(e,    g,    i) { c1◇→(e, f, g,    i) c2◇→(e, f, g, i) } } }
                    e << (d˚b1 ? b1˚. : d˚b2 ? b2˚.)
                    f << (d˚b1 ? b1˚. : b2˚.)
                    g << (d˚b1 ? b1˚.) << (d˚b2 ? b2˚.)
                    h << (d.a1 ? b1 ? c1 : 1)
                    i << (d˚b1 ? b1˚. | d˚b2 ? b2˚.)
                    """)

        err += test("d {a1 a2}.{b1 b2}.{c1 c2} e << (d˚b1 ? b1˚. : d˚b2 ? b2˚.)",
                    """
                    d {  a1 { b1⟐→e { c1◇→e c2◇→e } b2◇→e { c1◇→e c2◇→e } }
                         a2 { b1⟐→e { c1◇→e c2◇→e } b2◇→e { c1◇→e c2◇→e } } }
                    e << (d˚b1 ? b1˚. : d˚b2 ? b2˚.)
                    """)

        err += test("w {a b}.{c d}.{e f}.{g h} x << (w˚c ? c˚. : w˚d ? d˚.)",
                    """
                    w { a { c⟐→x { e { g◇→x h◇→x } f { g◇→x h◇→x } }
                            d◇→x { e { g◇→x h◇→x } f { g◇→x h◇→x } } }
                        b { c⟐→x { e { g◇→x h◇→x } f { g◇→x h◇→x } }
                            d◇→x { e { g◇→x h◇→x } f { g◇→x h◇→x } } } }
                    x << (w˚c ? c˚. : w˚d ? d˚.)
                    """)
        XCTAssertEqual(err, 0)
    }

    // TODO: this is areally bad kludge
    /// global result to tes callback
    var TestResult = ""

    /// add result of callback to result
    func addCallResult(_ flo: Flo, _ val: FloVal?) {
        var val = val?.printVal() ?? "nil"
        if val.first == " " { val.removeFirst() }
        TestResult += flo.name + "(" + val + ") "
    }

    /// test `b >> a(2)` for `b!`
    func testEdgeVal1() { headline(#function)
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(1) b >> a(2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           //let a =  root.findPath("a"),
           let b =  root.findPath("b") {

            b.activate(Visitor(.model))
            let result =  root.scriptRoot([.parens, .now, .edge])
            err = ParStr.testCompare("a(:2) b >> a(2)", result)
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
           //let a = root.findPath("a"),
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
           //let a =  root.findPath("a"),
           let z =  root.findPath("z") {

            z.activate(Visitor(.model))

            let result1 =  root.scriptRoot([.parens, .def, .edge])
            err += ParStr.testCompare(
            """
            a { b { f g(2) }
                c { f g(2) } }
            z >> (a.b.g(2), a.c.g(2))
            """, result1)
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
           //let a =  root.findPath("a"),
           let z =  root.findPath("z") {

            z.activate(Visitor(.model))

            let result1 =  root.scriptRoot([.parens, .def, .edge])
            err += ParStr.testCompare(
            """
            a { b { f(1) g(2) }
                c { f    g(2) } }
            z >> (a.b.f(1), a.b.g(2), a.c.g(2))
            """, result1)
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

    /// test `z@a ←@a`
    func testCopyAtR1() { headline(#function)
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

            let z =  root.findPath("z"),
           let zb = z.findPath("b"),
           let zc = z.findPath("c"),
           let zbd = zb.findPath("d"),
           let zbe = zb.findPath("e"),
           let zcd = zc.findPath("d"),
           let zce = zc.findPath("e") {

            ab.setAny (10, .activate)
            let result01 =  root.scriptRoot([.parens, .now, .delta, .compact])
            let expect01 = """

            a.b(:10)
            z.b(:10)
            """
            err += ParStr.testCompare(expect01, result01)

            ac.setAny (20, .activate)
            let result02 = root.scriptRoot([.parens, .now, .delta, .compact])
            let expect02 = """

            a  { b(:10) c(:20) }
            z  { b(:10) c(:20) }
            """
            err += ParStr.testCompare(expect02, result02)

            abd.setAny(30, .activate)
            abe.setAny(40, .activate)
            acd.setAny(50, .activate)
            ace.setAny(50, .activate)

            let result11 =  root.scriptRoot([.parens, .now, .edge, .copyAt])
            let expect11 = """

            a       { b(:10)       { d(:30)         e(:40)         }
                      c(:20)       { d(:50)         e(:50)         }}
            z@a ←@a { b(:10) ←@a.b { d(:30) ←@a.b.d e(:40) ←@a.b.e }
                      c(:20) ←@a.c { d(:50) ←@a.c.d e(:50) ←@a.c.e }}
            """
            err += ParStr.testCompare(expect11, result11)

            zb.setAny (11, .activate)
            zc.setAny (22, .activate)
            zbd.setAny(33, .activate)
            zbe.setAny(44, .activate)
            zcd.setAny(55, .activate)
            zce.setAny(66, .activate)

            let result12 =  root.scriptRoot([.parens, .now, .edge, .copyAt])
            let expect12 = """

             a      { b(:10)       { d(:30)         e(:40)         }
                      c(:20)       { d(:50)         e(:50)         }}
            z@a ←@a { b(:11) ←@a.b { d(:33) ←@a.b.d e(:44) ←@a.b.e }
                      c(:22) ←@a.c { d(:55) ←@a.c.d e(:66) ←@a.c.e }}
            """
            err += ParStr.testCompare(expect12, result12)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `z@a ←@→ a`
    func testCopyAtR2() { headline(#function)
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

            let result1 =  root.scriptRoot([.parens, .now, .edge, .copyAt])
            let expect1 = """

            a {        b(:10)        { d(:30)          e(:40)          }
                       c(:20)        { d(:50)          e(:60)          }}
            z@a ←@→a { b(:10) ←@→a.b { d(:30) ←@→a.b.d e(:40) ←@→a.b.e }
                       c(:20) ←@→a.c { d(:50) ←@→a.c.d e(:60) ←@→a.c.e }}
            """
            err += ParStr.testCompare(expect1, result1)

            zb.setAny (11, .activate)
            zc.setAny (22, .activate)
            zbd.setAny(33, .activate)
            zbe.setAny(44, .activate)
            zcd.setAny(55, .activate)
            zce.setAny(66, .activate)

            let result2 =  root.scriptRoot([.parens, .now, .edge, .copyAt])
            let expect2 = """

            a        { b(:11)       { d(:33)         e(:44)         }
                       c(:22)       { d(:55)         e(:66)         }}
            z@a ←@→a { b(:11)←@→a.b { d(:33)←@→a.b.d e(:44)←@→a.b.e }
                       c(:22)←@→a.c { d(:55)←@→a.c.d e(:66)←@→a.c.e }}
            """
            err += ParStr.testCompare(expect2, result2)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    ///
    func testFilter0() { headline(#function)
        Par.trace = true
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
                    a {b c}.{ d(x == 10, y 0, z 0) e(x 0, y == 21, z  0) } w(x 0, y 0, z 0) <> a˚.
                    """,
                    """
                    a { b { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) }
                        c { d (x == 10, y 0, z 0) e (x 0, y == 21, z 0) } }
                    w (x 0, y 0, z 0) <> (a.b.d, a.b.e, a.c.d, a.c.e)
                    """)
        XCTAssertEqual(err, 0)
    }
    func testFilter1() { headline(#function)
        Par.trace = true
        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = """
        a {b c}.{ d(x == 10, y 0, z 0)
                  e(x 0, y == 21, z 0) }
                  w(x 0, y 0, z 0) <> a˚."
        """
        let root = Flo("√")

        if floParse.parseScript(root, script),
           let w = root.findPath("w") {

            _ = root.scriptRoot([.parens, .now])
            // 0, 0, 0 --------------------------------------------------
            let t0 = FloValExprs(Flo("t0"), nameNums: [("x", 0), ("y", 0), ("z", 0)])
            w.setAny(t0, .activate)
            let result0 = root.scriptRoot([.parens, .now, .edge])
            let expect0 = """
            a { b { d (x  , y 0, z 0) e (x 0, y, z 0) }
                c { d (x  , y 0, z 0) e (x 0, y, z 0) } }
                    w (x 0, y 0, z 0) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """
            err += ParStr.testCompare(expect0, result0)

            // 10, 11, 12 --------------------------------------------------
            let t1 = FloValExprs(Flo("t1"), nameNums: [("x", 10), ("y", 11), ("z", 12)])
            w.setAny(t1, .activate)
            let result1 = root.scriptRoot([.parens, .now, .edge])
            let expect1 = """
            a { b { d (x:10, y:11, z:12) e (x 0, y, z 0) }
                c { d (x:10, y:11, z:12) e (x 0, y, z 0) } }
                    w (x:10, y:11, z:12) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """
            err += ParStr.testCompare(expect1, result1)

            // 20, 21, 22 --------------------------------------------------
            let t2 = FloValExprs(Flo("t2"), nameNums: [("x", 20), ("y", 21), ("z", 22)])

            w.setAny(t2, .activate)

            let result2 = root.scriptRoot([.parens, .now, .edge])
            let expect2 = """
            a { b { d (x:10, y:11, z:12) e (x:20, y:21, z:22) }
                c { d (x:10, y:11, z:12) e (x:20, y:21, z:22) } }
                    w (x:20, y:21, z:22) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """
            err += ParStr.testCompare(expect2, result2)

            // 10, 21, 33 --------------------------------------------------
            let t3 = FloValExprs(Flo("t3"), nameNums: [("x", 10), ("y", 21), ("z", 33)])
            w.setAny(t3, .activate)
            let result3 = root.scriptRoot([.parens, .now, .edge])
            let expect3 = """
            a { b { d (x:10, y:21, z:33) e (x:10, y:21, z:33) }
                c { d (x:10, y:21, z:33) e (x:10, y:21, z:33) } }
                    w (x:10, y:21, z:33) <> (a.b.d, a.b.e, a.c.d, a.c.e)
            """
            err += ParStr.testCompare(expect3, result3)

        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    //MARK: - Expressions

    /// test `a(x,y) << b, b(x 0, y 0)
    func testExpr0() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) << b, b(x 0, y 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            b.setAny(CGPoint(x: 1, y: 2), .activate)
            let result0 = root.scriptRoot([.parens, .now, .edge, .comment])
            let expect0 = "a(x:1, y:2) << b, b(x:1, y:2)"
            err = ParStr.testCompare(expect0, result0, echo: true)

            let result1 = root.scriptRoot([.parens, .def, .edge, .comment])
            let expect1 = "a(x, y) << b, b(x 1, y 2)"
            err = ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x 0) << c, b(y 0) << c, c(x 0, y 0)`
    func testExpr1() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x 0) << c,  c(x 0, y 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let c = root.findPath("c") {

            c.setAny(CGPoint(x: 1, y: 2), .activate)
            let result = root.scriptRoot([.parens, .now, .edge, .comment])
            let expect = "a(x:1) << c, c(x:1, y:2)"
            err = ParStr.testCompare(expect, result, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x 0) << c, b(y 0) << c, c(x 0, y 0)`
    func testExpr2() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x 0) << c, b(y 0) << c, c(x 0, y 0)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let c = root.findPath("c") {
            let p = CGPoint(x: 1, y: 2)
            c.setAny(p, .activate)
            let result = root.scriptRoot([.parens, .now, .edge, .comment])
            let expect = "a(x:1) << c, b(y:2) << c, c(x:1, y:2)"
            err = ParStr.testCompare(expect, result, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x 0…2, y 0…2, z 99), b (x 0…2, y 0…2) << a`
    func testExpr3() { headline(#function)
        Par.trace = true
        Par.trace2 = false
        var err = 0

        let script = "a(x 0…2, y 0…2, z 99), b (x 0…2, y 0…2) << a"
        print("\n" + script)

        let p0 = CGPoint(x: 1, y: 1)
        var p1 = CGPoint.zero

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a") {
            a.addClosure { flo, _ in
                p1 = flo.CGPointVal() ?? .zero
                print("p0\(p0) => p1\(p1)")
            }
            a.setAny(p0, .activate)

            let result0 = root.scriptRoot([.parens, .now, .edge, .comment])
            let expect0 = "a(x:1, y:1, z 99), b(x:1, y:1) << a"
            err += ParStr.testCompare(expect0, result0, echo: true)

            let result1 = root.scriptRoot([.parens, .def, .edge, .comment])
            let expect1 = "a(x 0…2, y 0…2, z 99), b(x 0…2, y 0…2) << a"
            err += ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
        XCTAssertEqual(p0, p1)
        Par.trace = false
        Par.trace2 = false
    }

    /// test `a(x in 2…4, y in 3…5) >> b b(x 1…2, y 2…3)`
    func testExpr4() { headline(#function)
        Par.trace = true
        Par.trace2 = false
        var err = 0

        let script = "a(x in 2…4, y in 3…5) >> b b(x 1…2, y 2…3)"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a") {

            let result0 = root.scriptRoot([.parens, .now, .edge])
            let expect0 = "a (x:2, y:3) >> b b(x:1, y:2)"
            err += ParStr.testCompare(expect0, result0, echo: true)

            a.setAny(CGPoint(x: 1, y: 4), .activate)

            let result1 = root.scriptRoot([.parens, .now, .edge])
            let expect1 = "a(x:1, y:4) >> b  b(x:1, y:2)"
            err += ParStr.testCompare(expect1, result1, echo: true)

            a.setAny(CGPoint(x: 3, y: 4), .activate)

            let result2 = root.scriptRoot([.parens, .now, .edge])
            let expect2 = "a(x:3, y:4) >> b  b(x:1.5, y:2.5)"
            err += ParStr.testCompare(expect2, result2, echo: true)

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
        let script = "a(x 10, y 20, z 30), b(sum: x + y + z) << a, c(x + y + z) << a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script, tracePar: false),
           let a = root.findPath("a") {

            let t0 = FloValExprs(Flo("t0"), nameNums: [("x", 1), ("y", 2), ("z", 3)])
            a.setAny(t0, .activate)

            let result = root.scriptRoot([.parens, .now, .edge, .comment])
            err = ParStr.testCompare("a(x:1, y:2, z:3), b(sum:6) << a, c(x:6) << a", result)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `b(sum: x + y + z) << a`
    func testExpr6() { headline(#function)
        var err = 0

        // selectively set tuples by name, ignore the reset
        let script = "a(x 10, y 20, z 30), b(x < 1, y, z) << a, c(x > 0, y, z) << a"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script, tracePar: false),
           let a = root.findPath("a") {

            let t0 = FloValExprs(Flo("t0"), nameNums: [("x", 1), ("y", 2), ("z", 3)])
            a.setAny(t0, .activate)

            let result = root.scriptRoot([.parens, .now, .edge, .comment])
            err = ParStr.testCompare("a(x:1, y:2, z:3), b(x, y, z)<<a, c(x:1, y:2, z:3)<<a", result)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    //MARK: - assign

    /// test `a(x, y) b(v 0) >> a(x:v)
    func testAssign0() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v 0) >> a(x:v)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            let result0 = root.scriptRoot([.parens, .def, .edge])
            let expect0 = "a(x, y) b(v 0) >> a(x:v)"
            err = ParStr.testCompare(expect0, result0, echo: true)

            let t1 = FloValExprs(Flo("t0"), nameNums: [("v", 1)])
            b.setAny(t1, .activate)
            let result1 = root.scriptRoot([.parens, .now, .edge])
            let expect1 = "a(x:1, y) b(v:1) >> a(x:1)"
            err = ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    /// test `a(x, y) b(v 0) >> a(x: v/2, y: v*2)`
    func testAssign1() { headline(#function)

        var err = 0
        // selectively set tuples by name, ignore the reset
        let script = "a(x, y) b(v 0) >> a(x: v/2, y: v*2)"
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script),
           let b = root.findPath("b") {

            let result0 = root.scriptRoot([.parens, .def, .edge])
            let expect0 = "a(x, y) b(v 0) >> a(x: v/2, y: v*2)"
            err = ParStr.testCompare(expect0, result0, echo: true)

            let t1 = FloValExprs(Flo("t1"), nameNums: [("v", 1)])
            b.setAny(t1, .activate)
            let result1 = root.scriptRoot([.parens, .now, .edge])
            let expect1 = "a(x:0.5, y:2) b(v:1)>>a(x:0.5, y:2)"
            err = ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }



    //MARK: - Midi

    /// test `grid(x: num _/ 12, y: num % 12) << note, note(num: 0…127 = 50)`
    func testMidiGrid() { headline(#function)
        var err = 0
        /// `_/` symbol is akin to python-style floor of division
        /// instead of the `//` symbol, which is used for comment
        let script = "grid(x: num _/ 12, y: num % 12) << note, note(num 0…127=50)"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseScript(root, script, tracePar: false),
           let note = root.findPath("note") {

            let num = FloValExprs(Flo("num"), nameNums: [("num", 50)])
            note.setAny(num, .activate)

            let result = root.scriptRoot([.parens, .now, .edge, .comment])
            err = ParStr.testCompare("grid(x:4, y:2) << note, note(num:50)", result)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }
    /// test `grid(num > 20, chan == 1 x: num _/ 12, y: num % 12) << note, note(num: 0…127 = 50, chan 1)`
    func testMidiFilter() { headline(#function)
        var err = 0

        /// `_/` symbol is akin to python-style floor of division
        /// instead of the `//` symbol, which is used for comment
        let script = """
        grid(num > 20, chan == 1, x: num _/ 12, y: num % 12) << note,
        note(num 0…127=50, chan 2)
        """
        print("\n" + script)

        let root = Flo("√")

        if floParse.parseScript(root, script, tracePar: false),
           let note = root.findPath("note") {

            let t0 = FloValExprs(Flo("t0"), nameNums: [("num", 50), ("chan", 0)])
            note.setAny(t0, .activate)
            let result0 = root.scriptRoot([.parens, .now, .edge, .comment])
            err += ParStr.testCompare( "grid(num, chan, x, y)<<note, note(num :50, chan :0)", result0) //TODO `num:50`, not `num 50`

            let t1 = FloValExprs(Flo("t1"), nameNums: [("num", 50), ("chan", 1)])
            note.setAny(t1, .activate)
            let result1 = root.scriptRoot([.parens, .now, .edge, .comment])
            err += ParStr.testCompare( "grid(num:50, chan:1, x:4, y:2)<<note, note(num:50, chan:1)", result1)
        } else {
            err = 1
        }
        XCTAssertEqual(err, 0)
    }

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

            a.addClosure { flo, _ in self.addCallResult(a, flo.val!) }
            b.addClosure { flo, _ in self.addCallResult(b, flo.val!) }
            c.addClosure { flo, _ in self.addCallResult(c, flo.val!) }

            err += testAct("c(5.0)", "c(5.0) b(5.0) a(0.5)") {
                c.setAny(5.0, .activate) }
            err += testAct("a(0.1)", "a(0.1) c(1.0) b(1.0) ") {
                a.setAny(0.1, .activate) }
            err += testAct("b(0.2)", "b(0.2) a(0.020000000000000004) c(0.20000000000000004)") {
                b.setAny(0.2, .activate) }
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    // MARK: - ternary

    /// setup new result string, call the action, print the appended result
    func testAct(_ before: String, _ after: String, callTest: @escaping CallVoid) -> Int {
        var err = 0
        TestResult = ""

        callTest() // side effect changed TestResult
        let result = TestResult.removeLines()
        if let (expected, actual) = ParStr.compare(after, result) {
            print (TestResult + "🚫 mismatch")
            print("expected ⟹ \(expected)")
            print("actual   ⟹ \(actual.removeLines())")
            err += 1
        } else {
            print ("⟹ " + TestResult + " ✓")
        }
        return err
    }

    func testTernary0() { headline(#function)
        var err  = 0
        let script = "a b c<<(a ? b)"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let b = root.findPath("b") {

            let expect1 = "a⟐→c b◇→c c << (a ? b)"
            let result1 = root.scriptRoot([.parens, .now, .edge])
            err += ParStr.testCompare(expect1, result1, echo: true)

            b.setAny(20, .activate)
            let expect2 = "a⟐→c b(:20)◇→c c<<(a ? b)"
            let result2 = root.scriptRoot([.parens, .now, .edge])
            err += ParStr.testCompare(expect2, result2, echo: true)

            a.setAny(10, .activate) // opens the gate
            b.activate(Visitor(.model)) // now passes through

            let expect3 =  "a(:10)⟐→c b(:20)⟐→c c(:20)<<(a ? b)"
            let result3 = root.scriptRoot([.parens, .now, .edge]).removeLines()
            err += ParStr.testCompare(expect3, result3, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    func testTernary1() { headline(#function)
        var err  = 0
        let script = "a b c w(0) << (a ? 1 : b ? 2 : c ? 3)"
        print("\n" + script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let b = root.findPath("b"),
           let c = root.findPath("c"),
           let w = root.findPath("w") {

            let expect0 = "a⟐→w b◇→w c◇→w w(0)<<(a ? 1 : b ? 2 : c ? 3)"
            let result0 = root.scriptRoot([.parens, .now, .edge])
            err += ParStr.testCompare(expect0, result0, echo: true)
            w.addClosure { flo, _ in self.addCallResult(w, flo.val!) }
            err += testAct("a !",  "w(1.0) ") { a.activate(Visitor(.model)) }
            err += testAct("a(0)", "w(1.0)")  { a.setAny(0, .activate) }
            err += testAct("b !",  "w(2.0) ") { b.activate(Visitor(.model)) }
            err += testAct("b(0)", "w(2.0)")  { b.setAny(0, .activate) }
            err += testAct("c !",  "w(3.0) ") { c.activate(Visitor(.model)) }

            let expect1 = "a(:0)⟐→w b(:0)⟐→w c⟐→w w(:3)<<(a ? 1 : b ? 2 : c ? 3)"
            let result1 = root.scriptRoot([.parens, .now, .edge])
            err += ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    func testTernary2() { headline(#function)
        var err = 0
        let script = "a(0) x(10) y(20) w<<(a ? x : y)"
        print(script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let x = root.findPath("x"),
           let y = root.findPath("y"),
           let w = root.findPath("w") {

            let expect0 = "a(0)⟐→w x(10)◇→w y(20)◇→w w<<(a ? x : y)"
            let result0 = root.scriptRoot([.parens, .now, .edge, .expand]).removeLines()
            err += ParStr.testCompare(expect0, result0, echo: true)

            w.addClosure { flo, _ in self.addCallResult(w, flo.val!) }
            err += testAct("a(0)",  "w(20.0)")  { a.setAny( 0, .activate) }
            err += testAct("x(11)", "")         { x.setAny(11, .activate) }
            err += testAct("y(21)", "w(21.0)")  { y.setAny(21, .activate) }
            err += testAct("a(1)",  "w(11.0)")  { a.setAny( 1, .activate) }
            err += testAct("x(12)", "w(12.0)")  { x.setAny(12, .activate) }
            err += testAct("y(22)", "")         { y.setAny(22, .activate) }
            err += testAct("a(0)", "w(22.0)")   { a.setAny(0, .activate) }

            //TODO:     = "a(0)⟐→w x(12)◇→w y(22)⟐→w w(22)<<(a ? x : y)"
            let expect1 = "a(0)⟐→w x(:12)◇→w y(:22)⟐→w w(y)<<(a ? x : y)"
            let result1 = root.scriptRoot([.parens, .now, .edge, .expand])
            err += ParStr.testCompare(expect1, result1, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    func testTernary3() { headline(#function)
        var err = 0
        let script = "a x(10) y(20) w<>(a ? x : y)"
        print(script)

        let root = Flo("√")
        if floParse.parseScript(root, script),
           let a = root.findPath("a"),
           let x = root.findPath("x"),
           let y = root.findPath("y"),
           let w = root.findPath("w") {

            err += ParStr.testCompare("a⟐→w x(10)←◇→w y(20)←◇→w w<>(a ? x : y)",
                                      root.scriptRoot([.parens, .now, .edge]), echo: true)

            w.addClosure { flo, _ in self.addCallResult(w, flo.val!) }
            x.addClosure { flo, _ in self.addCallResult(x, flo.val!) }
            y.addClosure { flo, _ in self.addCallResult(y, flo.val!) }

            err += testAct("a(0)", "w(20.0) y(20.0)") { a.setAny(0, .activate) }
            err += testAct("w(3)", "w(3.0)  y(3.0)")  { w.setAny(3, .activate) }
            err += testAct("a(1)", "w(3.0)  x(3.0)")  { a.setAny(1, .activate) }
            err += testAct("w(4)", "w(4.0)  x(4.0)")  { w.setAny(4, .activate) }

            let expect0 = "a(:1)⟐→w x(:4)←⟐→w y(:3)←◇→w w(:4)<>(a ? x : y)"
            let result0 = root.scriptRoot([.parens, .now, .edge]).removeLines()
            err += ParStr.testCompare(expect0, result0, echo: true)
        } else {
            err += 1
        }
        XCTAssertEqual(err, 0)
    }

    //MARK: - Scripts

    func testD3Script() { headline(#function)
        var err = 0
        let root = Flo("√")
        let script = "a.b.c(1) d { e(2) <> a.b.c } f@d"

        if floParse.parseScript(root, script) {

            let pretty = root.script([.compact, .parens])
            err += ParStr.testCompare(pretty, "√ { a.b.c(1) d.e(2) <> a.b.c f.e(2) <> a.b.c }" )

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
        err += testFile("test.skeleton.input",  out: "test.skeleton.output")
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
//        let actual = root.scriptRoot([.parens, .def, .edge, .comment]).reduceLines()
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
        ("testParseTernarys", testParseTernarys),
        ("testParseRelativePaths", testParseRelativePaths),
        ("testParseRelativePaths", testParseRelativePaths),

        ("testEdgeVal1", testEdgeVal1),
        ("testEdgeVal2", testEdgeVal2),
        ("testEdgeVal3a", testEdgeVal3a),
        ("testEdgeVal3b", testEdgeVal3b),
        ("testEdgeVal4b", testEdgeVal4b),

        ("testCopyAt", testCopyAt),
        ("testCopyAtR1", testCopyAtR1),
        ("testCopyAtR2", testCopyAtR2),
        ("testExpr1", testExpr1),
        ("testExpr2", testExpr2),
        ("testExpr3", testExpr3),
        ("testExpr4", testExpr4),
        ("testExpr5", testExpr5),

        ("testPassthrough", testPassthrough),
        ("testTernary1", testTernary1),
        ("testTernary2", testTernary2),
        ("testTernary3", testTernary3),

        ("testD3Script", testD3Script),
        ("testBodySkeleton", testBodySkeleton),
        //?? ("testMidi", testMidi),
        //?? ("testMuseSky", testMuseSky),
    ]
}
