import XCTest
import Foundation
@testable import MuFlo

final class FloD3Tests: XCTestCase {

    /// Parse a script into a fresh root, mirroring MuFloTests helpers.
    private func parseRoot(_ script: String) -> Flo? {
        let root = Flo("√")
        guard FloParse().parseRoot(root, script) else { return nil }
        return root
    }

    /// Load a Resources/test fixture the way MuFloTests+utils does.
    private func fixture(_ named: String) -> String? {
        guard let url = Bundle.module.url(forResource: named, withExtension: "flo.h")
        else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Export and decode back, proving the payload is valid JSON.
    private func decoded(_ root: Flo) -> FloD3Graph? {
        try? JSONDecoder().decode(FloD3Graph.self, from: root.makeD3Data())
    }

    private func count(_ graph: FloD3Graph, _ kind: String) -> Int {
        graph.links.filter { $0.kind == kind }.count
    }

    func testTreeOnlyGraph() {
        guard let root = parseRoot("a { b c }"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 4) // √ a b c
        XCTAssertEqual(graph.links.count, 3)
        XCTAssertEqual(count(graph, "child"), 3)
        XCTAssertEqual(graph.nodes.map(\.path), ["√", "a", "a.b", "a.c"])
        XCTAssertEqual(graph.nodes.map(\.depth), [0, 1, 2, 2])
    }

    func testInputEdge() {
        guard let root = parseRoot("a(1) b(<- a(2))"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 3) // √ a b
        XCTAssertEqual(count(graph, "child"), 2)
        XCTAssertEqual(count(graph, "<-"), 1)
        XCTAssertEqual(graph.links.count, 3)
    }

    func testOutputAndSyncEdges() {
        guard let root = parseRoot("a(1) b(-> a(2)) c(<> a)"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 4) // √ a b c
        XCTAssertEqual(count(graph, "child"), 3)
        XCTAssertEqual(count(graph, "->"), 1)
        XCTAssertEqual(count(graph, "<>"), 1)
        XCTAssertEqual(graph.links.count, 5)
    }

    /// `a.b(…)` pathRefs resolve into floEdges, so no separate "ref" kind is emitted.
    func testPathRefsResolveIntoEdges() {
        guard let root = parseRoot("a { b c } a.b(-> c(1))"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 4) // √ a a.b a.c — no placeholder node
        XCTAssertEqual(count(graph, "child"), 3)
        XCTAssertEqual(count(graph, "->"), 1)
        XCTAssertEqual(count(graph, "ref"), 0)

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        let arrow = graph.links.first { $0.kind == "->" }
        XCTAssertEqual(arrow?.source, byPath["a.b"])
        XCTAssertEqual(arrow?.target, byPath["a.c"])
    }

    /// Base copy `f : d` duplicates the subtree and its sync edge.
    func testBaseCopyEdges() {
        guard let root = parseRoot("a.b.c(1) d { e(2, <> a.b.c) } f : d"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 8) // √ a a.b a.b.c d d.e f f.e
        XCTAssertEqual(count(graph, "child"), 7)
        XCTAssertEqual(count(graph, "<>"), 2)
        XCTAssertEqual(graph.links.count, 9)
    }

    func testEveryLinkEndpointExists() {
        let scripts = ["a { b c }",
                       "a(1) b(<- a(2))",
                       "a(1) b(-> a(2)) c(<> a)",
                       "a.b.c(1) d { e(2, <> a.b.c) } f : d",
                       Self.starDecl,
                       Self.degreeDecl,
                       Self.aveDecl,
                       Self.deepDecl]
        for script in scripts {
            guard let root = parseRoot(script),
                  let graph = decoded(root) else { return XCTFail("parse or decode \(script)") }

            let ids = Set(graph.nodes.map(\.id))
            XCTAssertEqual(ids.count, graph.nodes.count, "duplicate ids in \(script)")
            for link in graph.links {
                XCTAssertTrue(ids.contains(link.source), "missing source in \(script)")
                XCTAssertTrue(ids.contains(link.target), "missing target in \(script)")
            }
        }
    }

    func testExportIsDeterministic() {
        guard let root = parseRoot("a.b.c(1) d { e(2, <> a.b.c) } f : d")
        else { return XCTFail("parse") }

        XCTAssertEqual(root.makeD3Data(), root.makeD3Data())
        XCTAssertEqual(root.makeD3Json(), root.makeD3Json())
    }

    func testScriptWrapsJson() {
        guard let root = parseRoot("a { b c }") else { return XCTFail("parse") }

        let script = root.makeD3Script()
        XCTAssertTrue(script.hasPrefix("var graph = {"))
        XCTAssertEqual(String(script.dropFirst("var graph = ".count)), root.makeD3Json())
    }

    /// A trailing `// text` parses as a `.branch` comment on the preceding node.
    func testNodeComments() {
        let script = """
        a {
            b(1) // bb
            c
        }
        """
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0) })
        XCTAssertEqual(byPath["a.b"]?.comment, "// bb")
        XCTAssertNil(byPath["a.c"]?.comment) // no comment decodes as nil
        XCTAssertNil(byPath["a"]?.comment)
        XCTAssertNil(byPath["√"]?.comment)

        guard let plain = parseRoot("a { b c }") else { return XCTFail("parse") }
        XCTAssertFalse(plain.makeD3Json().contains("comment")) // nil omits the key
        XCTAssertTrue(root.makeD3Json().contains("comment"))
        XCTAssertEqual(root.makeD3Data(), root.makeD3Data())

        // grammar folds `,+` into comment, so a separator lands as branch text
        guard let comma = parseRoot("a { b(1), c }"),
              let commaGraph = decoded(comma) else { return XCTFail("parse or decode") }

        XCTAssertEqual(commaGraph.nodes.first { $0.path == "a.b" }?.comment, ",")
    }

    // MARK: - shorthand checker

    /// six `on` leaves under `mix`, every one of them wired from `go`
    private let sixFan = """
    mix { a { on(x 0) } b { on(x 0) } c { on(x 0) }
          d { on(x 0) } e { on(x 0) } f { on(x 0) } }
    go(-> (mix.a.on, mix.b.on, mix.c.on, mix.d.on, mix.e.on, mix.f.on))
    """

    /// A fan of six same-named destinations collapses to its anchor shorthand.
    func testShorthandVerifiesAnchor() {
        guard let root = parseRoot(sixFan),
              let go = root.findPath("go") else { return XCTFail("parse") }

        XCTAssertEqual(go.makeD3Fan("->").count, 6)
        XCTAssertEqual(go.makeD3Shorthand("->"), "mix˚on")
    }

    /// The authored `˚` target wins over the synthesized anchor, and still
    /// has to pass the same runtime gate.
    func testShorthandPrefersAuthoredHint() {
        let script = """
        sky { joint { thumb { pos(x 0) } index { pos(x 0) } middle { pos(x 0) }
                      ring { pos(x 0) } pinky { pos(x 0) } wrist { pos(x 0) } } }
        hand(<- sky˚pos)
        """
        guard let root = parseRoot(script),
              let hand = root.findPath("hand") else { return XCTFail("parse") }

        XCTAssertEqual(hand.makeD3Fan("<-").count, 6)
        // common ancestor is `joint`, so `sky˚pos` can only come from the hint
        XCTAssertEqual(hand.makeD3Shorthand("<-"), "sky˚pos")
    }

    /// Decoy: `mix.g.on` matches `mix˚on` but carries no edge, so the
    /// shorthand would silently add a destination — refused.
    func testShorthandRefusesFalseInclusion() {
        let script = """
        mix { a { on(x 0) } b { on(x 0) } c { on(x 0) }
              d { on(x 0) } e { on(x 0) } f { on(x 0) } g { on(x 0) } }
        go(-> (mix.a.on, mix.b.on, mix.c.on, mix.d.on, mix.e.on, mix.f.on))
        """
        guard let root = parseRoot(script),
              let go = root.findPath("go") else { return XCTFail("parse") }

        XCTAssertEqual(go.makeD3Fan("->").count, 6)
        XCTAssertEqual(root.findPathFlos("mix˚on", [.children])?.count, 7)
        XCTAssertNil(go.makeD3Shorthand("->"))
    }

    /// Mirror decoy: `other.pos` is wired but sits outside `sky˚pos`, so the
    /// shorthand would silently drop a destination — refused.
    func testShorthandRefusesFalseExclusion() {
        let script = """
        sky { joint { thumb { pos(x 0) } index { pos(x 0) } middle { pos(x 0) }
                      ring { pos(x 0) } pinky { pos(x 0) } wrist { pos(x 0) } } }
        other { pos(x 0) }
        hand(<- sky˚pos, <- other.pos)
        """
        guard let root = parseRoot(script),
              let hand = root.findPath("hand") else { return XCTFail("parse") }

        XCTAssertEqual(hand.makeD3Fan("<-").count, 7) // the hint resolves only 6
        XCTAssertNil(hand.makeD3Shorthand("<-"))
    }

    /// Narrow fans are left verbose; the gate only runs past `minFan`.
    func testShorthandNeedsWideFan() {
        guard let root = parseRoot(sixFan),
              let go = root.findPath("go") else { return XCTFail("parse") }

        XCTAssertNil(go.makeD3Shorthand("->", minFan: 7))
        XCTAssertEqual(go.makeD3Shorthand("->", minFan: 6), "mix˚on")
        XCTAssertNil(go.makeD3Shorthand("<-")) // no fan of that kind at all
    }

    // MARK: - shorthand from provenance

    /// Authored text is faithful at any width, so a provenance candidate skips
    /// `minFan`: a four-wide star clique compresses to the authored `*` target
    /// form, and a single `..` edge compresses to `..`.
    func testShorthandUsesProvenance() {
        guard let root = parseRoot("rule(on 1) { a(on 0) b(on 0) c(on 0) d(on 0) *(-> *(on 0)) }"),
              let a = root.findPath("rule.a") else { return XCTFail("parse") }

        XCTAssertEqual(a.makeD3Fan("->").count, 4) // under the default minFan of 6
        XCTAssertEqual(a.makeD3Authored("->"), ["*"])
        XCTAssertEqual(a.makeD3Shorthand("->"), "*")
        XCTAssertNil(a.makeD3Authored("<-").first) // wrong op contributes nothing

        guard let deg = parseRoot("rule(on 1) { shape(on 0) { algo(x 0) } wave(on 0) { algo(x 0) } ˚algo(-> ..(on 1)) }"),
              let algo = deg.findPath("rule.shape.algo") else { return XCTFail("parse") }

        XCTAssertEqual(algo.makeD3Fan("->").count, 1)
        XCTAssertEqual(algo.makeD3Authored("->"), [".."])
        XCTAssertEqual(algo.makeD3Shorthand("->"), "..")
    }

    /// A decoy target beside the stamped fan widens the fan past what either
    /// authored path resolves, so the same runtime gate refuses both.
    func testShorthandRefusesDecoyBesideStamp() {
        let script = "out(x 0) rule(on 1) { a(on 0) b(on 0) c(on 0) d(on 0) *(-> (*(on 0), out)) }"
        guard let root = parseRoot(script),
              let a = root.findPath("rule.a") else { return XCTFail("parse") }

        XCTAssertEqual(a.makeD3Fan("->").count, 5) // 4 siblings plus the decoy
        XCTAssertEqual(a.makeD3Authored("->"), ["*", "out"])
        XCTAssertEqual(root.findPathFlos("out", [.children])?.count, 1)
        XCTAssertNil(a.makeD3Shorthand("->"))
    }

    // MARK: - wildcard dispatch export

    /// Flos in `root` whose edgeDefs were merged from a wildcard declaration.
    private func stamped(_ root: Flo) -> [(Flo, EdgeDefProv)] {
        var found = [(Flo, EdgeDefProv)]()
        if let prov = root.edgeDefs.edgeDefs.compactMap({ $0.declProv }).first {
            found.append((root, prov))
        }
        for child in root.children { found += stamped(child) }
        return found
    }

    /// Target paths recorded on every stamped edgeDef of `flo`.
    private func stampedKeys(_ flo: Flo) -> [String] {
        flo.edgeDefs.edgeDefs
            .filter { $0.declProv != nil }
            .flatMap { Array($0.pathExprs.keys) }
    }

    /// four siblings under one `*`, each with a child of its own
    static let starDecl = """
    rule(on 1) { a(on 0) { v(x 0) } b(on 0) { v(x 0) }
                 c(on 0) { v(x 0) } d(on 0) { v(x 0) } *(-> *(on 0)) }
    """

    /// two `algo` leaves reached by a named pattern
    static let degreeDecl = "rule(on 1) { shape(on 0) { algo(x 0) } wave(on 0) { algo(x 0) } ˚algo(-> ..(on 1)) }"

    /// Dev's `ave > version > ˚version`: one parent survives the fold
    static let aveDecl = "rule(on 1) { ave(on 0) { version(x 0…1 : 0) loops(y 0) } ˚version(-> ..(on 1)) }"

    /// each eliminated instance carries a child that has to be re-parented
    static let deepDecl = """
    rule(on 1) { shape(on 0) { algo(x 0) { deep(y 0) } }
                 wave (on 0) { algo(x 0) { deep(y 0) } } ˚algo(-> ..(on 1)) }
    """

    /// `*(-> *(on 0))` merges into each of four siblings, which then fan to the
    /// whole sibling set. The 4×4 clique collapses to 4 converging plus 4
    /// fanning through one hub, and no sibling wires to a sibling.
    ///
    /// `*` names no leaf, so it eliminates nothing: it matched every sibling,
    /// and folding those away would be folding away the graph.
    func testStarDeclCollapsesCliqueToHub() {
        guard let root = parseRoot(Self.starDecl),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 11) // √ rule + 4 rules + 4 v + hub
        XCTAssertEqual(count(graph, "child"), 9)

        let hubs = graph.nodes.filter { $0.hub == true }
        XCTAssertEqual(hubs.count, 1)
        XCTAssertEqual(hubs.first?.name, "*(-> *(on 0))") // the whole declaration
        XCTAssertEqual(hubs.first?.path, "rule.*")
        XCTAssertEqual(hubs.first?.depth, 2)
        XCTAssertNil(hubs.first?.d3Dad) // no tree link reaches an uneliminated hub
        guard let hub = hubs.first?.id else { return XCTFail("no hub") }

        // every matched sibling is still its own node under `rule`
        let kept = Set(graph.nodes.map(\.path))
        XCTAssertTrue(["rule.a", "rule.b", "rule.c", "rule.d"].allSatisfy(kept.contains))

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        let sibs = Set(["rule.a", "rule.b", "rule.c", "rule.d"].compactMap { byPath[$0] })
        XCTAssertEqual(sibs.count, 4)

        let arrows = graph.links.filter { $0.kind == "->" }
        XCTAssertEqual(arrows.count, 8) // 16 pairwise edges, self included
        XCTAssertEqual(Set(arrows.filter { $0.target == hub }.map(\.source)), sibs)
        XCTAssertEqual(Set(arrows.filter { $0.source == hub }.map(\.target)), sibs)
        XCTAssertFalse(arrows.contains { sibs.contains($0.source) && sibs.contains($0.target) })

        // the stamp keeps the authored text and one identity per declaration
        let provs = stamped(root)
        XCTAssertEqual(provs.count, 4)
        XCTAssertEqual(Set(provs.map { $0.1.text }), ["*"])
        XCTAssertEqual(Set(provs.map { $0.1.script }), ["*(-> *(on 0))"])
        XCTAssertEqual(Set(provs.map { $0.1.declId }).count, 1)
        XCTAssertEqual(provs.first?.1.declType, .path)
        XCTAssertEqual(provs.first.map { stampedKeys($0.0) }, ["*"])
    }

    /// `˚algo(-> ..(on 1))` names the leaf `algo`, so the hub stands for the
    /// two matched instances: both leave the payload, the tree links that held
    /// them land on the hub, and the parents each match reached fan out of it.
    func testDegreeDeclEliminatesInstances() {
        guard let root = parseRoot(Self.degreeDecl),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 5) // √ rule shape wave + hub, no algo
        XCTAssertEqual(count(graph, "child"), 5)

        let kept = Set(graph.nodes.map(\.path))
        XCTAssertFalse(kept.contains("rule.shape.algo"))
        XCTAssertFalse(kept.contains("rule.wave.algo"))

        let hubs = graph.nodes.filter { $0.hub == true }
        XCTAssertEqual(hubs.count, 1)
        XCTAssertEqual(hubs.first?.name, "˚algo(-> ..(on 1))")
        XCTAssertEqual(hubs.first?.path, "rule.˚algo")
        XCTAssertEqual(hubs.first?.depth, 2)
        XCTAssertNil(hubs.first?.d3Dad) // two parents survive, so no single dad
        guard let hub = hubs.first?.id else { return XCTFail("no hub") }

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        let parents = Set(["rule.shape", "rule.wave"].compactMap { byPath[$0] })
        XCTAssertEqual(parents.count, 2)

        // each parent now wires straight to the hub, in both directions
        let kids = graph.links.filter { $0.kind == "child" && $0.target == hub }
        XCTAssertEqual(Set(kids.map(\.source)), parents)

        let arrows = graph.links.filter { $0.kind == "->" }
        XCTAssertEqual(arrows.count, 2) // the 2 converging folded into the hub
        XCTAssertEqual(Set(arrows.map(\.source)), [hub])
        XCTAssertEqual(Set(arrows.map(\.target)), parents)

        // authored text is `˚algo`, the copied target key is only `..`
        let provs = stamped(root)
        XCTAssertEqual(provs.count, 2)
        XCTAssertEqual(Set(provs.map { $0.1.text }), ["˚algo"])
        XCTAssertEqual(Set(provs.map { $0.1.script }), ["˚algo(-> ..(on 1))"])
        XCTAssertEqual(Set(provs.map { $0.1.declId }).count, 1)
        XCTAssertEqual(provs.first.map { stampedKeys($0.0) }, [".."])
    }

    /// Dev's shape: `ave > version > ˚version` exports as `ave > ˚version`.
    /// One parent survives the fold, so the hub names it as its `d3Dad`.
    func testNamedDeclLeavesOneDad() {
        guard let root = parseRoot(Self.aveDecl),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(graph.nodes.count, 5) // √ rule ave ave.loops + hub
        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        XCTAssertNil(byPath["rule.ave.version"]) // the instance is gone
        XCTAssertNotNil(byPath["rule.ave.loops"]) // its sibling is not

        guard let hub = graph.nodes.first(where: { $0.hub == true }),
              let ave = byPath["rule.ave"] else { return XCTFail("no hub") }

        XCTAssertEqual(hub.name, "˚version(-> ..(on 1))")
        XCTAssertEqual(hub.d3Dad, ave)

        // `ave > version` became `ave > ˚version`; nothing points at `version`
        XCTAssertTrue(graph.links.contains(FloD3Link(source: ave, target: hub.id, kind: "child")))
        XCTAssertTrue(graph.links.contains(FloD3Link(source: hub.id, target: ave, kind: "->")))
        XCTAssertEqual(count(graph, "child"), 4)
        XCTAssertEqual(count(graph, "->"), 1) // the converging edge folded away
    }

    /// An eliminated instance hands its children to the hub, and the two links
    /// a shared source aimed at two instances arrive as one.
    func testEliminationReparentsAndDedupes() {
        let script = Self.deepDecl + "\ngo(-> (rule.shape.algo, rule.wave.algo))"
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        guard let hub = graph.nodes.first(where: { $0.hub == true })?.id,
              let go = byPath["go"] else { return XCTFail("no hub") }

        XCTAssertNil(byPath["rule.shape.algo"])
        // a grandchild of an eliminated instance keeps its own node and path
        guard let shapeDeep = byPath["rule.shape.algo.deep"],
              let waveDeep = byPath["rule.wave.algo.deep"]
        else { return XCTFail("no re-parented children") }

        XCTAssertTrue(graph.links.contains(FloD3Link(source: hub, target: shapeDeep, kind: "child")))
        XCTAssertTrue(graph.links.contains(FloD3Link(source: hub, target: waveDeep, kind: "child")))

        // `go` listed two instances; both endpoints fold onto one hub link
        let fromGo = graph.links.filter { $0.source == go && $0.kind == "->" }
        XCTAssertEqual(fromGo.count, 1)
        XCTAssertEqual(fromGo.first?.target, hub)

        // no link survives twice, and none loops the hub onto itself
        let keys = graph.links.map { "\($0.source)|\($0.kind)|\($0.target)" }
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertFalse(graph.links.contains { $0.source == $0.target })
    }

    /// A node named exactly like the pattern's leaf, that the resolver never
    /// matched, is not an instance and stays. `shape˚algo` reaches only the
    /// `algo` under `shape`; `wave.algo` is the decoy and keeps its node.
    func testDecoyNotMatchedSurvives() {
        let script = "rule(on 1) { shape(on 0) { algo(x 0) } wave(on 0) { algo(x 0) } shape˚algo(-> ..(on 1)) }"
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        XCTAssertEqual(stamped(root).count, 1) // the resolver matched one node
        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        XCTAssertNil(byPath["rule.shape.algo"])      // matched, eliminated
        XCTAssertNotNil(byPath["rule.wave.algo"])    // same name, never matched

        guard let hub = graph.nodes.first(where: { $0.hub == true }),
              let shape = byPath["rule.shape"] else { return XCTFail("no hub") }
        XCTAssertEqual(hub.name, "shape˚algo(-> ..(on 1))")
        XCTAssertEqual(hub.d3Dad, shape)
    }

    /// A trailing comment on the declaration is source, not title: the hub
    /// label carries the declaration and nothing else.
    func testHubTitleStripsComments() {
        let script = """
        rule(on 1) { shape(on 0) { algo(x 0) }
                     wave(on 0) { algo(x 0) }
                     ˚algo(-> ..(on 1)) // dispatch every algo up
        }
        """
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        guard let hub = graph.nodes.first(where: { $0.hub == true })
        else { return XCTFail("no hub") }

        XCTAssertEqual(hub.name, "˚algo(-> ..(on 1))")
        XCTAssertFalse(hub.name.contains("//"))
        XCTAssertNil(hub.comment)
    }

    /// The compact channel reads the Flo tree, not the payload, so eliminating
    /// instances leaves every provenance-authored shorthand row intact.
    func testShorthandSurvivesElimination() {
        guard let root = parseRoot(Self.degreeDecl),
              let graph = decoded(root),
              let algo = root.findPath("rule.shape.algo")
        else { return XCTFail("parse or decode") }

        XCTAssertNil(graph.nodes.first { $0.path == "rule.shape.algo" }) // gone
        XCTAssertEqual(algo.makeD3Fan("->").count, 1)                    // still wired
        XCTAssertEqual(algo.makeD3Authored("->"), [".."])
        XCTAssertEqual(algo.makeD3Shorthand("->"), "..")

        guard let star = parseRoot(Self.starDecl),
              let a = star.findPath("rule.a") else { return XCTFail("parse") }
        XCTAssertEqual(a.makeD3Shorthand("->"), "*")
    }

    /// The live `pipe.flo.h` shape: one scope declaring `*`, `˚version` and
    /// `˚algo` together. Each declaration keeps its own identity, so each gets
    /// its own hub instead of one merged blob.
    func testMultipleDeclsEachGetOwnHub() {
        let script = """
        main { rule(on 0) {
            slide(on 1) { version(x 0…1 : 0) algo(x 0…3=0) }
            wave (on 0) { version(x 0…1 : 0) algo(x 0…67 : 0) }
            field(on 0) { version(x 0…1 : 0) algo(x 0…23=0) }
            *(-> *(on 0))
            ˚version(-> ..(on 1))
            ˚algo(-> ..(on 1)) } }
        """
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        let hubs = graph.nodes.filter { $0.hub == true }
        XCTAssertEqual(hubs.map(\.name), ["*(-> *(on 0))",
                                          "˚version(-> ..(on 1))",
                                          "˚algo(-> ..(on 1))"])
        XCTAssertEqual(hubs.map(\.path), ["main.rule.*", "main.rule.˚version", "main.rule.˚algo"])
        XCTAssertEqual(Set(hubs.map(\.id)).count, 3)
        XCTAssertTrue(hubs.allSatisfy { $0.d3Dad == nil }) // three parents each

        // the six named instances are gone; `*` matched by shape and kept its own
        XCTAssertEqual(graph.nodes.count, 9) // 6 tree nodes + 3 hubs
        XCTAssertEqual(count(graph, "child"), 11)
        XCTAssertEqual(count(graph, "->"), 12) // 3+3 for `*`, 3 fanning each named

        let byPath = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.path, $0.id) })
        let rules = Set(["main.rule.slide", "main.rule.wave", "main.rule.field"]
            .compactMap { byPath[$0] })
        XCTAssertEqual(rules.count, 3)
        for path in ["main.rule.slide.version", "main.rule.slide.algo"] {
            XCTAssertNil(byPath[path])
        }
        let arrows = graph.links.filter { $0.kind == "->" }
        let kids = graph.links.filter { $0.kind == "child" }

        for (index, hub) in hubs.map(\.id).enumerated() {
            // only `*` still has instances left to converge on it
            let want = index == 0 ? rules : Set<Int>()
            XCTAssertEqual(Set(arrows.filter { $0.target == hub }.map(\.source)), want)
            XCTAssertEqual(Set(arrows.filter { $0.source == hub }.map(\.target)), rules)
            // each named hub inherited the tree links its instances held
            let dads = Set(kids.filter { $0.target == hub }.map(\.source))
            XCTAssertEqual(dads, index == 0 ? Set<Int>() : rules)
        }
        // every arrow now touches a hub; none is sibling to sibling
        XCTAssertTrue(arrows.allSatisfy { link in
            hubs.contains { $0.id == link.source || $0.id == link.target }
        })
    }

    /// A base copy shares one `Exprs` instance across its clones exactly the
    /// way a wildcard fan does, so shared identity cannot tell them apart.
    /// The merge-site stamp can: `f : d` exports no hub, the wildcard does.
    func testBaseCopyStaysUnstamped() {
        guard let wild = parseRoot("rule(on 1) { shape(on 0) { algo(x 0) } wave(on 0) { algo(x 0) } ˚algo(-> ..(on 1)) }"),
              let base = parseRoot("d(on 0) { e(x 2, -> ..(on 1)) } f : d"),
              let wildGraph = decoded(wild),
              let baseGraph = decoded(base)
        else { return XCTFail("parse or decode") }

        XCTAssertEqual(targetIds(wild, "..").count, 1) // one shared Exprs, two owners
        XCTAssertEqual(targetIds(base, "..").count, 1) // indistinguishable
        XCTAssertEqual(owners(wild, "..").count, 2)
        XCTAssertEqual(owners(base, "..").count, 2)

        XCTAssertEqual(stamped(wild).count, 2) // provenance separates them
        XCTAssertEqual(stamped(base).count, 0)
        XCTAssertEqual(wildGraph.nodes.filter { $0.hub == true }.count, 1)
        XCTAssertEqual(baseGraph.nodes.filter { $0.hub == true }.count, 0)
        XCTAssertFalse(base.makeD3Json().contains("hub"))
        XCTAssertEqual(count(baseGraph, "->"), 2) // both copies stay pairwise

        /// hand-written twins each parse their own Exprs, so identity differs
        guard let hand = parseRoot("rule(on 1) { shape(on 0) { algo(x 0, -> ..(on 1)) } wave(on 0) { algo(x 0, -> ..(on 1)) } }")
        else { return XCTFail("parse") }
        XCTAssertEqual(targetIds(hand, "..").count, 2)
        XCTAssertEqual(stamped(hand).count, 0)

        func owners(_ flo: Flo, _ path: String) -> [Flo] {
            var found = flo.edgeDefs.edgeDefs.contains { $0.pathExprs.keys.contains(path) } ? [flo] : []
            for child in flo.children { found += owners(child, path) }
            return found
        }
        func targetIds(_ flo: Flo, _ path: String) -> Set<ObjectIdentifier> {
            var found = Set<ObjectIdentifier>()
            for edgeDef in flo.edgeDefs.edgeDefs {
                if let exprs = edgeDef.pathExprs[path] ?? nil {
                    found.insert(ObjectIdentifier(exprs))
                }
            }
            for child in flo.children { found.formUnion(targetIds(child, path)) }
            return found
        }
    }

    /// Wildcard-free export is byte-frozen, with ids normalized to node order
    /// since `Visitor.nextId()` is a process-wide counter. Hub synthesis adds
    /// nothing here: no stamp, no hub node, no `hub` key.
    func testWildcardFreeExportIsFrozen() {
        guard let root = parseRoot("a.b.c(1) d { e(2, <> a.b.c) } f : d"),
              let graph = decoded(root) else { return XCTFail("parse or decode") }

        var rank = [Int: Int]()
        for (index, node) in graph.nodes.enumerated() { rank[node.id] = index }
        let nodes = graph.nodes.map { "\(rank[$0.id] ?? -1):\($0.name):\($0.path):\($0.depth)" }
        let links = graph.links.map { "\(rank[$0.source] ?? -1)\($0.kind)\(rank[$0.target] ?? -1)" }
        XCTAssertEqual(nodes.joined(separator: " "), Self.frozenNodes)
        XCTAssertEqual(links.joined(separator: " "), Self.frozenLinks)
        XCTAssertEqual(root.makeD3Data(), root.makeD3Data()) // .sortedKeys stability
        XCTAssertTrue(graph.nodes.allSatisfy { $0.hub == nil })
        XCTAssertTrue(graph.nodes.allSatisfy { $0.d3Dad == nil })
        XCTAssertFalse(root.makeD3Json().contains("hub"))
        XCTAssertFalse(root.makeD3Json().contains("d3Dad")) // nil omits the key
    }

    static let frozenNodes = "0:√:√:0 1:a:a:1 2:b:a.b:2 3:c:a.b.c:3 4:d:d:1 5:e:d.e:2 6:f:f:1 7:e:f.e:2"
    static let frozenLinks = "0child1 0child4 0child6 1child2 2child3 4child5 5<>3 6child7 7<>3"

    func testSkyFixtureGraph() {
        guard let script = fixture("test.sky") else { return XCTFail("missing test.sky") }
        guard let root = parseRoot(script),
              let graph = decoded(root) else { return XCTFail("parse or decode test.sky") }

        XCTAssertGreaterThan(graph.nodes.count, 10)
        XCTAssertGreaterThan(count(graph, "child"), 10)
        XCTAssertEqual(count(graph, "child"), graph.nodes.count - 1) // tree links = nodes - root

        let ids = Set(graph.nodes.map(\.id))
        for link in graph.links {
            XCTAssertTrue(ids.contains(link.source))
            XCTAssertTrue(ids.contains(link.target))
        }
        XCTAssertEqual(root.makeD3Data(), root.makeD3Data())
    }
}
