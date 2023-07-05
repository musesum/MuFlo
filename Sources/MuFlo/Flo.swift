//  Flo.swift
//
//  Created by warren on 3/7/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar

/// Dictionary of all Flos in graph based on path based hash.
/// This is useful for updating state of a flo node from duplicate
/// graph with exactly the same namespace. Useful for saving and
/// recalling state of a saved graph, or synchronizing between devices
/// which have the same exact graph namespace.
public class FloDispatch {
    public var dispatch = [Int: (Flo,TimeInterval)]()
}

public class Flo {
    public static var IdFlo = [Int:Flo]() // debugging
    
    public static var root˚ = Flo("√")
    public static var LogBindScript = false // debug while binding
    public static var LogMakeScript = false // debug while binding

    public var id = Visitor.nextId()
    public var dispatch: FloDispatch? // Global dispatch for each root

    public var name = ""
    public var exprs: FloExprs?
    public var parent: Flo?         // parent flo
    public var children = [Flo]()   // expanded flo from  wheres˚flo
    public var comments = FloComments()

    public var string  : String   { get { StringVal()  ?? "??"  }}
    public var double  : Double   { get { DoubleVal()  ?? .zero }}
    public var float   : Float    { get { FloatVal()   ?? .zero }}
    public var cgFloat : CGFloat  { get { CGFloatVal() ?? .zero }}
    public var cgPoint : CGPoint  { get { CGPointVal() ?? .zero }}
    public var cgSize  : CGSize   { get { CGSizeVal()  ?? .zero }}
    public var int     : Int      { get { IntVal()     ?? .zero }}
    public var uint32  : UInt32   { get { UInt32Val()  ?? .zero }}
    public var bool    : Bool     { get { BoolVal()             }}
    public var names   : [String] { get { NamesVal()   ?? []    }}

    public var scriptDelta : String { scriptRoot(FloScriptOps.Delta) }
    public var scriptNow   : String { scriptRoot(FloScriptOps.Now  ) }
    public var scriptDef   : String { scriptRoot(FloScriptOps.Def  ) }
    public var scriptAll   : String { scriptRoot(FloScriptOps.All  ) }
    public var scriptFull  : String { scriptRoot(FloScriptOps.Full ) }

    private var time = TimeInterval(0)  // UTC time of last change time
    public func updateTime() { time = Date().timeIntervalSince1970 }

    var hasDelta = false            // any changes to descendants?
    var pathRefs: [Flo]?            // b in `a.b <> c` for `a{b{c}} a.b <> c
    var passthrough = false         // does not have its own FloVal, so pass through events
    var cacheVal: Any? = nil        // cached value is drained
    var edgeDefs = FloEdgeDefs()    // for a<-(b.*++), this saves "++" and "b.*)
    var floEdges = [String: FloEdge]() // some edges are defined by another Flo
    var closures = [FloVisitor]()  // during activate call a list of closures
    var type = FloType.unknown
    var copied = [Flo]()

    var plugDefs: EdgeDefs?
    var plugins = [FloPlugin]()
    public var hasPlugins: Bool { plugins.count > 0 }
    var setOps: FloValOps { hasPlugins ? [.val] : [.twe, .val] }


    public lazy var hash: Int = {
        let hashed = path(9999).strHash()
        if time == 0 { updateTime()}
        return hashed
    }()

    init() {
        Flo.IdFlo[id] = self
    }
    public convenience init(deepcopy from: Flo,
                            parent: Flo,
                            via: FloType) {

        self.init()
        self.parent = parent

        self.name = from.name
        self.type = from.type

        for fromChild in from.children {
            let newChild = Flo(deepcopy: fromChild, parent: self, via: via)
            children.append(newChild)
        }
        passthrough = from.passthrough
        exprs = from.exprs?.copy() ?? nil

        if from.edgeDefs.edgeDefs.count > 0,
           let parent = from.parent {

            if (parent.type == .many) ||
                (via == .copyall) {

                edgeDefs = from.edgeDefs.copy()
            }
        }
        comments = from.comments
    }
    public func makeFloFrom(parItem: ParItem) -> Flo {

        if let value = parItem.value {
            return Flo(value)
        }
        return self
    }

    /** attach to only deepest children

        attach z to a { b c }       ⟹  a { b { z } c { z } }
        attach z to a { b { c } }   ⟹  a { b { c { z } } }

    - Parameters:
        - flo: The parent Flo, which may be a leaf to attach or has children to scan deeper.

        - visit: the same "_:_" clone may be attached to multiple parent before consolication.
     */
    func attachDeep(_ flo: Flo, _ visit: Visitor) {
        guard visit.newVisit(id)  else { return }
        
        if children.count == 0 {
            flo.parent = self
            children.append(flo)
        } else {
            for child in children {
                child.attachDeep(flo, visit)
            }
        }
    }

    /** attach future children to parent's children, for a many:many relationship

         a { b c } . { d e }      ⟹  a { b { d e } c { d e } }
         a { b { c } } . { d e }  ⟹  a { b { c { d e } } }

    initial step is to create a placeholder _:_ for { d e }

         a { b c } : _:_        ⟹  a { b { _:_ } c { _:_ } }

    after subsequent parsing fills _:_ with { d e }, then bind

         a { b {_:_{d e}} c {_:_{d e}}}  ⟹  a { b { d e } c { d e } }
     */
    public func makeMany() -> Flo {
        let many = Flo("_:_", .many)
        attachDeep(many, Visitor(0))
        return many
    }
    @discardableResult
    public func addChild(_ parItem: ParItem, _ type_: FloType)  -> Flo {

        if let value = parItem.nextPars.first?.value {

            let child = Flo(value, type_)
            children.append(child)
            child.parent = self
            return child
        }
        return self
    }
    
    public func makeChild(_ name: String = "") -> Flo {
        let child = Flo(name)
        child.parent = self
        children.append(child)
        return child
    }

    public func addClosure(_ closure: @escaping FloVisitor) {
        closures.append(closure)
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
        if let parent = parent {
            return parent.getRoot()
        }
        return self
    }

    /// all Flos from root share the same dispatch.
    /// There are two main usescases:
    ///    1) app saves .delta and restores .val values
    ///    2) another devices wants to synchronize state
    ///
    public func bindDispatch(_ prior: Flo? = nil) {

        if let prior {
            dispatch = prior.dispatch
            dispatch?.dispatch[hash] = (self,time)
        } else {
            dispatch = FloDispatch()
            dispatch?.dispatch[hash] = (self, Date().timeIntervalSince1970)
        }
        for child in children {
            child.bindDispatch(self)
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

}
