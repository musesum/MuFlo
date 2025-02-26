//  Flo.swift
//  created by musesum on 3/7/19.

import Foundation
import Metal

/// Dictionary of all Flos in graph based on path based hash.
/// This is useful for updating state of a flo node from duplicate
/// graph with exactly the same namespace. Useful for saving and
/// recalling state of a saved graph, or synchronizing between devices
/// which have the same exact graph namespace.

public class HashFlo {
    var hashFlo =  [Int: Flo]()
}

public enum LogBind { case none, value, def }

public class Flo {

    public static var IdFlo = [Int:Flo]() // debugging
    public static var root˚ = Flo("√")
    public var hashFlos : HashFlo!

    public var id = Visitor.nextId()
    public var name = ""
    public var type = FloType.unknown
    public var exprs: Exprs?
    public var parent: Flo?
    public var children = [Flo]()

    var pathRefs: [Flo]?            /// `b` in `a.b(<> c)` for `a.b.c a.b(<> c)
    var edgeDefs = EdgeDefs()       /// `b` and `c` in `a(<-(b c)`
    var floEdges = [String: Edge]() /// some edges are defined by another Flo
                                    ///
    var closures = [FloVisitor]()   /// during activate call a list of closures
    var comments = FloComments()
    var plugDefs: EdgeDefArray?     /// class reference to [EdgeDef]
    var plugins = [EdgePlugin]()
    var setOps: ScalarOptions { hasPlugins ? [.value] : [.tween, .value] }
    var deltaTween = false          /// any changes to descendants?

    public var youngest : Flo          { get { children.last ?? self }}
    public var string   : String       { get { StringVal()  ?? "??"  }}
    public var scalar   : Scalar?      { get { ScalarVal()           }}
    public var double   : Double       { get { DoubleVal()  ?? .zero }}
    public var float    : Float        { get { FloatVal()   ?? .zero }}
    public var cgFloat  : CGFloat      { get { CGFloatVal() ?? .zero }}
    public var cgPoint  : CGPoint      { get { CGPointVal() ?? .zero }}
    public var cgSize   : CGSize       { get { CGSizeVal()  ?? .zero }}
    public var int      : Int          { get { IntVal()     ?? .zero }}
    public var uint32   : UInt32       { get { UInt32Val()  ?? .zero }}
    public var bool     : Bool         { get { BoolVal()             }}
    public var xyz      : SIMD3<Float> { get { XyzVal()     ?? .zero }}
    public var names    : [String]     { get { NamesVal()   ?? []    }}

    public func addComment(_ type: FloCommentType, _ text: String?) {
        guard let text else { return }
        let index = type == .edge ? edgeDefs.edgeDefs.count : children.count
        let comment = FloComment(type, name, text, index)
        comments.hasType.insert(type)
        comments.comments.append(comment)
    }
    public func hasExpr(_ name: String) -> Bool {
        exprs?.nameAny.keys.contains(name) ?? false
    }
    public func setExpr(_ name: String, _ any: Any) {
        if exprs == nil { exprs = Exprs(self, name, any) }
        exprs?.nameAny[name] = any
    }
    public func getExpr(_ name: String) -> Any? {
        exprs?.nameAny[name]
    }

    public func val(_ name: String) -> Double? {
        return ((exprs?.nameAny[name] as? Scalar)?.value ?? nil)}
    public func intVal(_ name: String) -> Int? {
        if let num = val(name) { return Int(num) } else { return nil } }
    public func boolVal(_ name: String) -> Bool { (val(name) ?? 0) > 0 }

    public var scriptDelta : String { scriptRoot(FloScriptOps.Delta) }
    public var scriptNow   : String { scriptRoot(FloScriptOps.Now  ) }
    public var scriptVal   : String { scriptRoot(FloScriptOps.Val  ) }
    public var scriptDef   : String { scriptRoot(FloScriptOps.Def  ) }
    public var scriptAll   : String { scriptRoot(FloScriptOps.All  ) }
    public var scriptFull  : String { scriptRoot(FloScriptOps.Full ) }

    private var time = TimeInterval(0)  // UTC time of last change time
    public func updateTime() { time = Date().timeIntervalSince1970 }
    public var bound: Bool { !name.hasSuffix("?") }

    public var texture: MTLTexture? {
        get { (exprs?.nameAny["tex"] as? MTLTexture?) ?? nil }
        set { if exprs == nil { exprs = Exprs(self, "tex", newValue) }
            else { exprs?.nameAny["tex"] = newValue }
        }
    }
    public var buffer: MTLBuffer? {
        get { (exprs?.nameAny["buf"] as? MTLBuffer?) ?? nil }
        set { if exprs == nil { exprs = Exprs(self, "buf", newValue) }
            else { exprs?.nameAny["buf"] = newValue }
        }
    }

    public var passthrough = false // does not have its own FloVal, so pass through events
    public var hasPlugDefs: Bool { plugDefs?.count ?? 0 > 0 }
    public var hasPlugins: Bool { plugins.count > 0 }

    public func hasChanged() -> Bool {
        guard let exprs else { return false }
        for val in exprs.nameAny.values {
            if let scalar = val as? Scalar {
                if !scalar.hasDelta() {
                    return false
                }
            }
        }
        return true
    }
    public func hasPrior() -> Bool {
        guard let exprs else { return false }
        for val in exprs.nameAny.values {
            if let scalar = val as? Scalar {
                if scalar.hasPrior() {
                    return true
                }
            }
        }
        return false
    }
    public lazy var inputs: [Flo] = {
        floEdges.values.filter {
            $0.edgeOps.contains(.input) &&
            $0.leftFlo.id == self.id
        }.map { $0.rightFlo }
    }()
    public lazy var outputs: [Flo] = {
        floEdges.values.filter {
            $0.edgeOps.contains(.output) &&
            $0.leftFlo.id == self.id
        }.map { $0.rightFlo }
    }()
    public lazy var hash: Int = {
        if time == 0 { updateTime() }
        let hashed = path(9999).strHash()
        return hashed
    }()

    init() {
        Flo.IdFlo[id] = self
    }
    public convenience init(_ name: String, parent: Flo?, type: FloType = .name) {
        self.init()
        self.name = name
        self.parent = parent
        self.type = type
        parent?.children.append(self)
    }
    public convenience init(deepcopy: Flo,
                            parent: Flo?,
                            via: FloType) {
        self.init()
        self.parent = parent
        self.name = deepcopy.name
        self.type = deepcopy.type

        for copyChild in deepcopy.children {
            let newChild = Flo(deepcopy: copyChild, parent: self, via: via)
            children.append(newChild)
        }
        passthrough = deepcopy.passthrough
        exprs = deepcopy.exprs?.copy(self)
        edgeDefs = deepcopy.edgeDefs.copy()
        comments = deepcopy.comments.copy()
    }

    public convenience init(decorate: Flo,
                            parent: Flo,
                            exprs: Exprs) {
        self.init()
        self.parent = parent
        self.name = decorate.name
        self.type = decorate.type
        self.exprs = exprs.copy(self)
        parent.children.append(self)

        for decorChild in decorate.children {
            _ = Flo(decorate: decorChild, parent: self, exprs: exprs)
        }
    }

    public func makeFloFrom(parsed: Parsed) -> Flo {

        if let value = parsed.result {
            return Flo(value)
        }
        return self
    }

    public func makeGraft() -> Flo {
        let graft = Flo("𐂷", .graft)
        return graft 
    }
    public func makeBase(_ name: String?) {
        if let name {
            let base  = Flo(name, parent: self, type: .base)
            base.parent = self
        }
    }
    @discardableResult
    public func  addChild(_ parsed: Parsed, _ type: FloType) -> Flo {

        if let pathName = parsed.nextResult {
            let child = Flo(pathName, type)
            children.append(child)
            child.parent = self
            return child
        }
        return self
    }

    public func addClosure(_ closure: @escaping FloVisitor) {
        closures.append(closure)
    }
    public func soloClosure(_ closure: @escaping FloVisitor) {
        if closures.isEmpty {
            closures.append(closure)
        }
    }
    public func path(_ depth: Int = 2, withId: Bool = false) -> String {
        var path = name
        if withId { path += "." + String(id) }
        if depth > 1, let parentPath =  parent?.path(depth-1) {
            path = parentPath + "." + path
        }
        return path
    }

    public func getRoot() -> Flo {
        if let parent {
            return parent.getRoot()
        }
        return self
    }

    /// all Flos from root share the same dispatch.
    /// There are two main use cases:
    ///    1) app saves .delta and restores .val values
    ///    2) another devices wants to synchronize state
    ///
    public func bindHashFlo(_ prior: Flo? = nil) {

        hashFlos = prior?.hashFlos ?? HashFlo()
        hashFlos.hashFlo[hash] = self

        for child in children {
            child.bindHashFlo(self)
        }
    }
}

extension Flo: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }

    public static func == (lhs: Flo, rhs: Flo) -> Bool {
        return lhs.id == rhs.id
    }

    public convenience init(_ name: String, _ type: FloType = .name) {
        self.init()
        self.name = name
        self.type = type
    }
    public func makeAnyExprs(_ any: Any) -> Exprs? {
        switch any {
        case let v as Int:     return Exprs(self, [(name, Double(v))])
        case let v as Double:  return Exprs(self, [(name, v)])
        case let v as CGFloat: return Exprs(self, [(name, Double(v))])
        case let v as CGPoint: return Exprs(self, v)
        case let v as CGRect:  return Exprs(self, v)
        case let v as CGSize:  return Exprs(self, v)
        case let v as [(String, Double)]: return  Exprs(self, v)
        default: PrintLog("⁉️ unknown val(\(any))"); return nil
        }
    }
}
extension Flo {

    func mergeFloValues(_ mergeRoot: Flo) {

        if let mergeFlo = mergeRoot.hashFlos.hashFlo[hash],
           let mergeExprs = mergeFlo.exprs,
            let exprs {

            NoDebugLog {
                P("# \(exprs.name)_\(self.id) <- \(mergeFlo.name)_\(mergeFlo.id)") }
            exprs.setFromAny(mergeExprs, Visitor(0))
        }
        children.forEach { $0.mergeFloValues(mergeRoot) }
    }
    func activateAllValues() {

        activate(Visitor(0))
        children.forEach { $0.activateAllValues() }
    }
}
