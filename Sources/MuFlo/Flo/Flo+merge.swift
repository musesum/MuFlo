//  Flo+Merge.swift
//  created by musesum on 4/8/19.


import Foundation
import Collections
extension Flo {

    /// `b.c` in `a { b { c {c1 c2} d {d1 d2} } b.c: c3 }`
    func willMerge(with flo: Flo) -> Bool {
        if flo == self {
            return true
        }
        for child in flo.children {
            if child == self {
                return true
            }
        }
        return parent?.willMerge(with: flo) ?? false
    }

    /// previously declared Flo has a ":"
    ///
    ///  What follows a ":" is either a:
    ///   1) new node to add to tree,
    ///   2) new path synthesized from current location, or
    ///   3) one or more nodes to override
    ///
    /// for example
    ///
    ///     /**/ a { b { c { c1 c2 } d { d1 d2 } } b.c : c3 } ⟹
    ///     √  { a { b { c { c1 c2 c3 } d { d1 d2 } } } }
    ///
    ///     /**/ a { b { c { c1 c2 } d { d1 d2 } } b.c : b.d } ⟹
    ///     √  { a { b { c { c1 c2 d1 d2 } d { d1 d2 } } } }
    func mergeDuplicate(_ merge: Flo) {

        for child in children {
            if child.id == merge.id {
                return
            } else if child.name == merge.name {
                child.merge(merge)
                children = children.filter { $0.type != .remove }
                return
            }
        }
        children.append(merge)
    }

    func merge(_ merge: Flo) {
        if self.id == merge.id { return  }
        merge.type = .remove
        if let mergeExprs = merge.exprs,
           mergeExprs.hasValue {
                exprs = mergeExprs.copy(self)
        }
        /// `z.b.f(->c(2)` in `a {b c}.{d e f(-> b(1)) } z:a z.b.f(->c(2))`
        if !merge.edgeDefs.edgeDefs.isEmpty {
            edgeDefs = merge.edgeDefs.copy()
        }
        comments.mergeComments(self, merge)
        /// `e` in `a { b { c d } } a { e }`
        for mergeChild in merge.children {
            if mergeChild.type == .base {
                //print("*** \(mergeChild.name).\(mergeChild.id)")
            } else {
                mergeDuplicate(mergeChild)
            }
        }
    }

    func bindGraft() -> [Flo] {
        guard let firstChild = children.first else { return [self] }
        var result = [Flo]()
        for grand in firstChild.children {
            // add copy of copy's child
            let copy = Flo(deepcopy: grand, parent: self, via: type)
            result.append(copy)
        }
        return result
    }

    func bindBase() -> [Flo] {

        if let found = expandPathName(),
           let parent {

            if  found.count == 1,
                found.first?.id == id,
                children.isEmpty {

                type = .name
                return [self]
            }
            /// `: _c` in `a.b { _c { c1 c2 } c { d e } : _c }`
            if found.count > 0 {

                var newChildren = [Flo]()
                for foundi in found {
                    for foundChild in foundi.children {
                        let copy = Flo(deepcopy: foundChild, parent: parent, via: type)
                        newChildren.append(copy)
                    }
                }
                type = .remove
                return newChildren
            }
        }
        /// `:e` in `a { b { c {c1 c2} d } } a:e`
        return [self]
    }

    func graft(_ graft: Flo) {

        for child in children {
            if ![.graft,.remove].contains(child.type) {
                var scions = [Flo]()
                for scion in graft.children {
                    let copy = Flo(deepcopy: scion, parent: child, via: .graft)
                    scions.append(copy)
                }
                child.children.append(contentsOf: scions)
            }
        }
    }

    /// either merge a new Flo or deepCopy a reference to existing Flo
    func mergeOrCopy(_ found: [Flo]) -> [Flo] {

        var results = [Flo]()

        for foundi in found {
            if foundi.children.isEmpty {
                /// `*.f(1)` in `a { b f } z:a *.f(1)`
                foundi.merge(self)
            } else if let parent, foundi.willMerge(with: parent) {
                // is adding or appending with a direct ancestor?
                // b.c in `a { b { c {c1 c2} d } b.c:c3 }`
                for child in children {
                    foundi.mergeDuplicate(child)
                }
            } else {
                // b.d in `a { b { c {c1 c2} d {d1 d2} } b.c : b.d  }`
                let copy = Flo(deepcopy: foundi, parent: parent, via: type)
                results.append(copy)
            }
        }
        return results
    }

    func expandPathName() -> [Flo]? {

        guard let found = findAnchors(name) else { return nil }

        if found.count == 1,
           found.first?.id == id,
           self.children.isEmpty {

            type = .name
            return [self]
        }

        if found.count > 0 {
            if edgeDefs.edgeDefs.isEmpty {
                // b.c in `a { b { c {c1 c2} d } b.c { c3 } }`
                let results = mergeOrCopy(found)
                return results
            } else {
                // a.b in `a { b { c } }  a.b(<> c)`
                pathRefs = found
                return [self]
            }
        }
        return nil
    }

    func bindMakePath() -> [Flo] {

        if let found = findPathFlos(name, [.parents, .children]) {
            type = .remove
            return found
        } else if let pathChain = makePath(name, self) {
            type = .remove
            return [pathChain]
        } else {
            return [self]
        }
    }

    func bindPath() -> [Flo] {
        if let found = expandPathName() {
            return found
        } else {
            return bindMakePath()
        }
    }
    /// found unique name
    func bindName(_ siblings: [Flo]) -> [Flo] {

        for sibling in siblings {
            // sibling is candidate, no need to search anymore
            if sibling.id == id {
                return [self]
            }
            // found sibling with same name so merge
            if sibling.name == name {
                sibling.merge(self)
                return []
            }
        }
        // didn't find matching sibling so is unique
        return [self]
    }
    /// find duplicates in children and merge their children
    /// a, a in `a.b { c d } a.e { f g }`
    func mergeAdoptions(_ adoptions: [Flo], _ type: FloType) {

        let adoptions = expandAdoptions(adoptions)

        // some children were copied or promoted so fix their parent
        var combined = OrderedDictionary<String, Flo>()
        if type == .base {
            adoptions.forEach { overload($0) }
            children.forEach { overload($0) }
        } else {
            children.forEach { overload($0) }
            adoptions.forEach { overload($0) }
        }
        self.children = Array(combined.values)

        func overload(_ flo: Flo) {
            if [.remove, .base].contains(flo.type) { return }
            if let original = combined[flo.name] {
                original.merge(flo)
            } else {
                flo.parent = self
                combined[flo.name] = flo
            }
        }
        func expandAdoptions(_ adoptions: [Flo]) -> [Flo] {
            if adoptions.count == 1,
               let adopt = adoptions.first,
               adopt.type == .base,
               let found = parent?.findAnchors(adopt.name) {
                var expanded = [Flo]()
                found.forEach { expanded.append(contentsOf: $0.children) }
                return expanded
            }
            return adoptions
        }
    }

    func bindChildren()  {

        // add base to children with
        var adoptions = [Flo]()
        var childTypes = [(String,FloType)]()
        for child in children {
            childTypes.append((child.name, child.type))
            var adopt: [Flo]
            switch child.type {
            case .remove: adopt = []
            case .path  : adopt = child.bindPath()
            case .name  : adopt = child.bindName(adoptions)
            case .graft : adopt = child.bindGraft()
            case .base  : adopt = child.bindBase()
            default     : adopt = [child]
            }
            adoptions.append(contentsOf: adopt)
        }
        mergeAdoptions(adoptions, type)
        if FloParse.logBindChildren {
            logChildTypes()
        }

        func logChildTypes() {
            var script = "   " + name + " [ "
            var delim = ""
            for (name,type) in childTypes {
                script += delim + name + ": " + type.rawValue
                delim = ", "
            }
            script += " ]"
            print(script)
        }
    }

    /// split path into a solo child that
    /// inherits original's children and edges
    ///
    ///     a.b(0, <- c) { d } // script becomes
    ///     a { b(0, <- c) { d } } // internally
    ///
    func spawnChild(from: String) -> Flo {

        let newFlo = Flo(String(from))   // make new flo from path suffix
        newFlo.children = children      // transfer children to new flo
        newFlo.parent = self
        newFlo.comments = comments
        comments = FloComments()

        for child in newFlo.children {
            child.parent = newFlo
        }

        newFlo.edgeDefs = edgeDefs
        edgeDefs = EdgeDefs()

        newFlo.floEdges = floEdges
        floEdges = [String: Edge]()

        children = [newFlo] // make newFlo my only child
        newFlo.exprs = exprs // transfer my value to newFlo
        exprs = nil
        return newFlo
    }

    /// Expand pure path `a.b.c` into `a { b { c } }`
    @discardableResult
    public func expandDotPath() -> Bool {
        /// search for `.` in `a.b.c`, but
        /// not `*` in `a.*.c` nor `˚` in `a˚c`
        if name.contains("˚") { return false }
        if name.contains("*") { return false }

        var index = 0

        if name.hasPrefix("."),
           let parent {
            
            return parent.promote(self)

        } else {
            for char in name {
                switch char {
                case "˚" : return false
                case "." : divideAndContinue(index); return true
                default  : index += 1
                }
            }
        }
        return false
        /// recursively split path into solo child, grand, etc
        ///
        ///     a.b.c         // becomes after 1st pass:
        ///     a { b.c }     // becomes after 2nd pass:
        ///     a { b { c } } // as final result
        ///
        func divideAndContinue(_ index: Int) {
            if index > 0 {

                let prefix = name.prefix(index)
                let sufCount = name.count-index-1

                if sufCount > 0 { // split `a.b.c` into `a`, `b.c`

                    let suffix = name.suffix(sufCount) // make suffix substring
                    let child = spawnChild(from: String(suffix))

                    name = String(prefix)   // change name to only prefix
                    type = .name            // change my type to .name
                    child.expandDotPath()   // continue with `b.c`

                } else { // special case with `a.`

                    name = String(prefix)   // trim trailing .
                    type = .name            // change my type to .name
                }
            }
        }
    }
    func promote(_ flo: Flo) -> Bool {

        flo.name.removeFirst()

        if flo.name.hasPrefix(".") {
            if let parent {
                return parent.promote(flo)
            } else {
                PrintLog("⁉️ Flo::\(#function) dangling `.` in \(flo.name)")
                flo.type = .remove
                return false
            }
        } else if flo.parent?.id == self.id {
            flo.type = .name
        } else {
            let copy = Flo(deepcopy: flo, parent: self, via: .name)
            copy.type = .name
            children.append(copy)
            flo.type = .remove
        }
        return true
    }
    /// first pass convert `a.b.c` into `a { b { c } }`
    func bindPathName() {

        if type == .base,
            let anchors = parent?.findAnchors(name) {
            //print("*** base: \(name) \(id)")

            var adoptions: [Flo] = []
            for anchor in anchors {
                for child in anchor.children {
                    adoptions.append(Flo(deepcopy: child, parent: self, via: type))
                }
            }
            type = .remove
            parent?.mergeAdoptions(adoptions, .base)
            return
        }
        else if type == .path,
                let anchors = parent?.findAnchors(name) {
            //print("*** path: \(name) \(id)")

            for anchor in anchors {

                if children.count == 0 {
                    anchor.merge(self) /// in `a.b(<> c)` merge `(<> c)` only
                } else {
                    var adoptions: [Flo] = []
                    for child in children {
                        adoptions.append(Flo(deepcopy: child, parent: anchor, via: type))
                    }
                    anchor.mergeAdoptions(adoptions, .path)
                    type = .remove
                }

            }
            /// `a.b:c.d` is a special case in that both
            /// `a.b` and `c.d` refer to values elsewhere
            /// so, remove `a.b:c.d` statement
            if children.count == 1,
               let child = children.first,
               child.type == .base,
               child.children.count == 0 {
                type = .remove
                return
            }
        } else if expandDotPath() {
            parent?.mergeDuplicate(self)
        }
        
        if children.count > 0 {
            for child in children {
                child.bindPathName()
            }
            let filtered = children.filter { $0.type != .remove }
            children = filtered
        }
    }
    func bindEdges(_ nextFrame: NextFrame) {
        edgeDefs.bindEdges(self, nextFrame)
        for child in children {
            child.bindEdges(nextFrame)
        }
    }
    /** bind 2nd a.b in `a.b { c d } a.e:a.b { f g }`

     - note: Needs forward pass for prototype subtree that refer to unexpanded paths.

     Since expansion is bottom up, the first a.b in:

     a.b { c d } a.e:a.b { f g }

     has not been been expanded, when encountering the second a.b.
     So, the deeper a.b was deferred until this forward pass,
     where first a.b has finally expanded and can now bind
     its children.
     */
    func bindTopDown() {
        for child in children {
            if child.children.count > 0 {
                child.bindTopDown()
            }
        }
        bindChildren()
    }

    public func setFloDefaults(_ visit: Visitor, _ withPrior: Bool) {
        exprs?.setDefaults(visit, withPrior)
        for edge in floEdges {
            edge.value.edgeExpress?.setDefaults(visit, withPrior)
        }
        for child in children {
            child.setFloDefaults(visit, withPrior)
        }
    }
    public func bindVals() {
        exprs?.bindVals()
        for edge in floEdges {
            edge.value.edgeExpress?.bindVals()
        }
        for child in children {
            child.bindVals()
        }
    }
}
