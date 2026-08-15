import Foundation

/// One graph node: identity, label, dotted path, tree depth, and source comment.
/// `hub` is true only on a synthetic wildcard-declaration node, else omitted.
/// `d3Dad` names a hub's one surviving tree parent; omitted when it has none,
/// or more than one, and always omitted on an ordinary node — a tree node's
/// parent is the `child` link that already reaches it.
public struct FloD3Node: Codable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let path: String
    public let depth: Int
    public let comment: String?
    public let hub: Bool?
    public let d3Dad: Int?
}

/// One directed link; `kind` is "child" for tree edges, else the edge op symbol.
public struct FloD3Link: Codable, Equatable, Sendable {
    public let source: Int
    public let target: Int
    public let kind: String
}

/// Force-directed graph payload for a D3 client.
public struct FloD3Graph: Codable, Equatable, Sendable {
    public let nodes: [FloD3Node]
    public let links: [FloD3Link]
}

/// One authored wildcard declaration, rejoined from the copies `merge`
/// scattered across matched nodes. The pairwise edges it produced are replaced
/// by `source → hub` and `hub → destination` links, so a `*` clique of N
/// siblings reads as N converging plus N fanning instead of N×N.
final class FloD3Decl {

    let id: Int             /// the decl Flo id; no exported node holds it
    let text: String        /// authored pattern, `*` or `˚algo`
    let script: String      /// full authored decl, `˚algo(-> ..(on 1))`
    var members = [Flo]()   /// every flo the hub touches, for its lineage
    var instances = [Int]() /// ids the pattern matched, in walk order
    var froms = [FloD3Link]()
    var intos = [FloD3Link]()
    var keys = Set<String>()  /// edgeKeys the hub replaces
    private var seen = Set<String>()
    private var held = Set<Int>()

    init(_ prov: EdgeDefProv) {
        id = prov.declId
        text = prov.text
        script = prov.script
    }

    /// The leaf a pattern names: `algo` in `˚algo`, `on` in `mix˚on`.
    ///
    /// Empty when the pattern names nothing — the bare `*`, `˚˚`, `radio˚.`,
    /// or a multi-level `*.f`. Those match by shape rather than by name, so
    /// the hub does not stand for its matches and nothing is eliminated.
    var patternLeaf: String {
        guard let mark = text.lastIndex(where: { "*˚".contains($0) })
        else { return "" }
        let leaf = String(text[text.index(after: mark)...])
        return leaf.hasChar(in: ".*˚") ? "" : leaf
    }

    /// One flo the merge stamped, ie one node the pattern matched.
    func addInstance(_ flo: Flo) {
        if held.insert(flo.id).inserted { instances.append(flo.id) }
    }

    /// Fold one stamped edge in, deduping each endpoint per link kind.
    func addEdge(_ edge: Edge) {

        keys.insert(edge.edgeKey)
        let kind = edge.edgeOps.script(active: edge.active)

        if seen.insert("<\(edge.leftFlo.id)\(kind)").inserted {
            froms.append(FloD3Link(source: edge.leftFlo.id, target: id, kind: kind))
            members.append(edge.leftFlo)
        }
        if seen.insert(">\(edge.rightFlo.id)\(kind)").inserted {
            intos.append(FloD3Link(source: id, target: edge.rightFlo.id, kind: kind))
            members.append(edge.rightFlo)
        }
    }
}

extension Flo {

    /// Raw `.branch` comment text, space joined; nil when the node has none.
    func makeD3Comment() -> String? {

        let texts = comments.comments
            .filter { $0.type == .branch }
            .map { $0.text }
        return texts.isEmpty ? nil : texts.joined(separator: " ")
    }

    /// Depth-first node list: self first, then each subtree in child order.
    func makeD3Nodes(_ depth: Int = 0) -> [FloD3Node] {

        var nodes = [FloD3Node(id: id,
                               name: name,
                               path: scriptLineage(),
                               depth: depth,
                               comment: makeD3Comment(),
                               hub: nil,
                               d3Dad: nil)]
        for child in children {
            nodes.append(contentsOf: child.makeD3Nodes(depth + 1))
        }
        return nodes
    }

    /// Outgoing links for this Flo: tree children, then flo edges it owns.
    /// `masked` holds the edgeKeys a wildcard hub has taken over.
    func makeD3OwnLinks(_ masked: Set<String>) -> [FloD3Link] {

        var links = [FloD3Link]()
        for child in children {
            links.append(FloD3Link(source: id, target: child.id, kind: "child"))
        }
        var owned = floEdges.values.filter {
            $0.leftFlo.id == id && !masked.contains($0.edgeKey)
        }
        owned.sort { $0.id < $1.id } // dictionary order is unstable
        for edge in owned {
            links.append(FloD3Link(source: id,
                                   target: edge.rightFlo.id,
                                   kind: edge.edgeOps.script(active: edge.active)))
        }
        return links
    }

    /// Depth-first link list, matching the node walk order.
    func makeD3Links(_ masked: Set<String> = []) -> [FloD3Link] {

        var links = makeD3OwnLinks(masked)
        for child in children {
            links.append(contentsOf: child.makeD3Links(masked))
        }
        return links
    }

    /// Every stamped edge in this subtree, one entry per declaration,
    /// in depth-first first-encounter order.
    func makeD3Decls(_ decls: inout [Int: FloD3Decl], _ order: inout [Int]) {

        for edgeDef in edgeDefs.edgeDefs {
            guard let prov = edgeDef.declProv else { continue }
            var decl = decls[prov.declId]
            if decl == nil {
                decl = FloD3Decl(prov)
                decls[prov.declId] = decl
                order.append(prov.declId)
            }
            decl?.addInstance(self)
            var edges = Array(edgeDef.edges.values)
            edges.sort { $0.id < $1.id } // dictionary order is unstable
            for edge in edges {
                decl?.addEdge(edge)
            }
        }
        for child in children {
            child.makeD3Decls(&decls, &order)
        }
    }

    /// Synthetic node for one declaration, placed at its members' common scope.
    /// The label is the whole authored declaration; the path keeps the pattern.
    func makeD3Hub(_ decl: FloD3Decl,
                   _ depths: [Int: Int],
                   _ dad: Int?) -> FloD3Node {

        let scope = makeD3Common(decl.members)
        let stem = (scope?.parent == nil) ? "" : (scope?.scriptLineage() ?? "")
        return FloD3Node(id: decl.id,
                         name: decl.script,
                         path: stem.isEmpty ? decl.text : stem + "." + decl.text,
                         depth: (scope.flatMap { depths[$0.id] } ?? 0) + 1,
                         comment: nil,
                         hub: true,
                         d3Dad: dad)
    }

    /// Move every endpoint of an eliminated instance onto its hub, dropping the
    /// self links folding makes and the duplicates two instances now share.
    func makeD3Remap(_ links: [FloD3Link], _ onto: [Int: Int]) -> [FloD3Link] {

        var result = [FloD3Link]()
        var seen = Set<String>()
        for link in links {
            let source = onto[link.source] ?? link.source
            let target = onto[link.target] ?? link.target
            let moved = (source != link.source) || (target != link.target)
            if moved, source == target { continue } // instance wired to its hub
            guard seen.insert("\(source)|\(link.kind)|\(target)").inserted
            else { continue }
            result.append(FloD3Link(source: source, target: target, kind: link.kind))
        }
        return result
    }

    /// A hub's one tree parent, nil when the fold left it none or many.
    func makeD3Dad(_ hub: Int, _ links: [FloD3Link]) -> Int? {

        var dads = Set<Int>()
        for link in links where link.kind == "child" && link.target == hub {
            dads.insert(link.source)
        }
        return dads.count == 1 ? dads.first : nil
    }

    /// Whole graph rooted at this Flo, with each wildcard declaration collapsed
    /// to one hub node. A wildcard-free tree exports exactly as before.
    ///
    /// A declaration whose pattern names a leaf stands for the nodes it matched,
    /// so those instances leave the payload and every link that touched one
    /// lands on the hub: `ave > version > ˚version` exports as `ave > ˚version`.
    /// A pattern naming nothing matches by shape alone and eliminates nothing —
    /// the bare `*` matches every sibling, and folding those away is the graph.
    public func makeD3Graph() -> FloD3Graph {

        var decls = [Int: FloD3Decl]()
        var order = [Int]()
        makeD3Decls(&decls, &order)

        var masked = Set<String>()
        for declId in order {
            masked.formUnion(decls[declId]?.keys ?? [])
        }
        var nodes = makeD3Nodes()
        var links = makeD3Links(masked)

        var depths = [Int: Int]()
        for node in nodes { depths[node.id] = node.depth }

        var hubs = [FloD3Decl]()
        for declId in order {
            guard let decl = decls[declId], !decl.froms.isEmpty else { continue }
            hubs.append(decl)
            links.append(contentsOf: decl.froms)
            links.append(contentsOf: decl.intos)
        }
        var onto = [Int: Int]() // instance id → the hub it folds into
        for decl in hubs where !decl.patternLeaf.isEmpty {
            for instance in decl.instances where onto[instance] == nil {
                onto[instance] = decl.id
            }
        }
        if !onto.isEmpty {
            nodes = nodes.filter { onto[$0.id] == nil }
            links = makeD3Remap(links, onto)
        }
        for decl in hubs {
            nodes.append(makeD3Hub(decl, depths, makeD3Dad(decl.id, links)))
        }
        return FloD3Graph(nodes: nodes, links: links)
    }

    /// Deterministic JSON. Client colors: red=child, green=input/observe, blue=output/activate.
    public func makeD3Data() -> Data {

        let coder = JSONEncoder()
        coder.outputFormatting = [.sortedKeys]
        return (try? coder.encode(makeD3Graph())) ?? Data()
    }

    /// String convenience over `makeD3Data`.
    public func makeD3Json() -> String {
        String(data: makeD3Data(), encoding: .utf8) ?? ""
    }

    /// Legacy JS statement form for `var graph = {…}` consumers.
    public func makeD3Script() -> String {
        "var graph = " + makeD3Json()
    }

    /// Own outgoing edges whose op string matches `ops`, in stable id order.
    func makeD3Fan(_ ops: String) -> [Edge] {

        var fan = floEdges.values.filter {
            $0.leftFlo.id == id && $0.edgeOps.script(active: $0.active) == ops
        }
        fan.sort { $0.id < $1.id } // dictionary order is unstable
        return fan
    }

    /// Nearest Flo whose subtree holds every destination.
    func makeD3Common(_ dests: [Flo]) -> Flo? {

        guard var common = dests.first else { return nil }
        for dest in dests.dropFirst() {
            var lineage = Set<Int>()
            var walk: Flo? = common
            while let at = walk { lineage.insert(at.id); walk = at.parent }
            var rise: Flo? = dest
            while let at = rise, !lineage.contains(at.id) { rise = at.parent }
            guard let found = rise else { return nil }
            common = found
        }
        return common
    }

    /// Shorthand candidates: authored `˚` targets first, then anchor names
    /// rising from the fan's common ancestor. The root is never an anchor.
    func makeD3Candidates(_ ops: String, _ dests: [Flo], _ leaf: String) -> [String] {

        var candidates = [String]()
        for edgeDef in edgeDefs.edgeDefs where edgeDef.edgeOps.script(active: true) == ops {
            for path in edgeDef.pathExprs.keys where path.contains("˚") {
                candidates.append(path)
            }
        }
        var anchor = makeD3Common(dests)
        while let at = anchor, at.parent != nil {
            if !at.name.isEmpty, !at.name.hasChar(in: ".*˚") {
                candidates.append(at.name + "˚" + leaf)
            }
            anchor = at.parent
        }
        return candidates
    }

    /// Target paths of this node's provenance-stamped edgeDefs: the text a
    /// wildcard declaration actually authored, `*` for the star form and `..`
    /// for `˚algo(-> ..)`.
    func makeD3Authored(_ ops: String) -> [String] {

        var candidates = [String]()
        for edgeDef in edgeDefs.edgeDefs where edgeDef.declProv != nil {
            if edgeDef.edgeOps.script(active: true) == ops {
                candidates.append(contentsOf: edgeDef.pathExprs.keys)
            }
        }
        return candidates
    }

    /// Verified shorthand for a same-kind fan, else nil.
    ///
    /// The gate is MuFlo's own resolver, never string matching: the candidate
    /// must resolve to exactly the fan's destinations. A resolved flo holding
    /// no edge is a false inclusion, an edge destination the candidate misses
    /// is a false exclusion, and either one refuses the shorthand.
    ///
    /// Authored provenance text runs first and ignores `minFan` — showing what
    /// was written is faithful at any width. The synthesized `anchor˚name`
    /// still needs a wide fan of same-named destinations.
    public func makeD3Shorthand(_ ops: String, minFan: Int = 6) -> String? {

        let fan = makeD3Fan(ops)
        guard let first = fan.first else { return nil }

        var wants = Set<Int>()
        var dests = [Flo]()
        for edge in fan {
            if wants.insert(edge.rightFlo.id).inserted {
                dests.append(edge.rightFlo)
            }
        }
        let opsKey = first.edgeOps.script(active: true)

        for candidate in makeD3Authored(opsKey) where verify(candidate) {
            return candidate
        }
        guard fan.count >= minFan,
              let leaf = dests.first?.name,
              dests.allSatisfy({ $0.name == leaf }) else { return nil }

        for candidate in makeD3Candidates(opsKey, dests, leaf) where verify(candidate) {
            return candidate
        }
        return nil

        func verify(_ candidate: String) -> Bool {
            let found = findPathFlos(candidate, [.parents, .children]) ?? []
            return Set(found.map { $0.id }) == wants
        }
    }
}
