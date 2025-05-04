//  Flo+find.swift
//  created by musesum on 5/2/19.

import Foundation

extension Flo { // + find

    // returns a.b in `a { b { c } } a˚b`
    // returns a.b.c in `a { b { c } } a˚c`
    // returns a.b1.c, a.b2.c in `a { b1 { c } b2 { c } } a˚c`

    // ? in `˚`   // undefined
    // a in `˚a`  // add if matches b and stop, otherwise continue
    // a in `˚˚a` // add if matches b, always continue
    // _ in `˚˚`  // add in all cases, always continue
    // a in `˚.a` // add if matches b and no children and stop, otherwise continue
    // _ in `˚.`  // add if no children, otherwise continue

    func getDegreeFlos(_ wildcard: String, _ suffix: String) -> [Flo]? {

        let greedy = wildcard == "˚˚"
        let leafy = wildcard == "˚."
        var found = [Flo]()

        // do not incude ˚˚ in `˚˚ <> ..`
        if type == .path {
            return nil
        } else if suffix.isEmpty {                      // for a { b { c } }

            if greedy {  //  a, b, c in ˚˚
                if parent != nil {
                    found.append(self)
                }
                findDeeper()
            }
            if leafy  {
                if children.isEmpty { return [self] }   // c   in ˚.
                else                { findDeeper() }    // a, b in ˚.
            }
            return found
        } else {
            var found2 = [Flo]()
            let (prefix2, wild2, suffix2) = suffix.splitWild(".*˚")
            if name == prefix2 {
                if leafy {
                    if children.isEmpty { found = [self] } // c in ˚.c
                    else                { return nil }     // b in ˚.b
                }
                else {
                    found = [self]                         // b in ˚b,˚˚b
                    if greedy { findDeeper() }
                }
            } else {                                       // !b in ˚b,˚˚b
                findDeeper()
            }
            for foundi in found {
                if  let foundi2 = foundi.getWildSuffix(wild2, suffix2, .children) {
                    found2.append(contentsOf: foundi2)
                }
            }
            return found2
        }
        func findDeeper() {
            for child in children {
                let foundChild = child.getDegreeFlos(wildcard, suffix)
                found.append(contentsOf: foundChild ?? [])
            }
        }
    }


    // returns a in `a.b.c <- …`
    func getDotParent(_ count: Int) -> Flo? {
        if count < 1 {
            return self
        } else if let parent {
            return parent.getDotParent(count-1)
        } else {
            return nil
        }
    }

    // `..`, `...`, `..a`
    func getNearDots(_ wildcard: String, _ suffix: String, _ findOps: FloFindOps) -> [Flo]? {
        if wildcard == ".*" {
            return children
        }
        if let parent = getDotParent(wildcard.count-1) {
            return parent.findPathFlos(suffix, findOps)
        } else {
            return nil
        }
    }

    /// find preexisting item  //TODO: redo after testing is working again
    public func findPathNames(_ path: String, _ findOps: FloFindOps = [.parents, .children]) -> [Flo]? {

        let (prefix, wildcard, suffix) = path.splitWild(".*˚")
        let deeperOps = findOps.intersection([.children, .makePath])
        let anchors = (noPrefixFlos() ??
                       prefixFlos() ??
                       selfFlos() ??
                       parentFlos() ??
                       nil)
        return anchors?.isEmpty ?? true ? nil : anchors

        func noPrefixFlos() -> [Flo]? {
            guard prefix == "" else { return nil } 
            if parent?.name == suffix { return err("wildcard:\(wildcard) parent.name == suffix \(suffix)") }

            var found = [Flo]()

            switch wildcard {
            case "."        : return collectChildSuffix(self)
            case "*","*."   : return collectChildren(self)
            case ".*.",".*" : return collectChildren(self)
            case "˚."       : collectLeaves(&found, self); return found
            default         : return nil
            }

            func collectChildSuffix(_ flo: Flo) -> [Flo]? {
                for sibling in flo.children  {
                    if sibling.name == suffix {
                        return [sibling]
                    }
                }
                return nil
            }
            func collectChildren(_ flo: Flo) -> [Flo]? {

                for sibling in flo.children  {
                    if !sibling.name.hasChar(in: ".*˚") {
                        found.append(sibling)
                    }
                }
                if suffix == "" {
                    return found // done
                }
                var results = [Flo]()
                found.forEach { flo in
                    if let pathNames = flo.findPathNames(suffix, findOps) {
                        results.append(contentsOf: pathNames)
                    }
                }
                if results.isEmpty {
                    found.forEach {
                        results.append(Flo(suffix, parent: $0))
                    }
                }
                return results.isEmpty ? nil : results

            }
            func err(_ msg: String) -> [Flo]? {
                print("⁉️ findAnchor: \(msg)")
                return nil
            }

        }
        func prefixFlos() -> [Flo]? {
            if name == prefix {
                switch type {
                case .remove : return findOriginalPathFlos(wildcard + suffix, [.children])
                case .name   : return findPathFlos(wildcard + suffix, [.children])
                case .base   : return parent?.findPathFlos(path, findOps) ?? nil
                default      : break
                }
            }
            for child in children {
                if child.name == prefix,
                   child.type == .name {
                    let wildSuffix = wildcard + suffix
                    if !wildSuffix.isEmpty {
                        return child.findPathFlos(wildSuffix, deeperOps)
                    } else {
                        return [child]
                    }
                }
            }
            return nil
        }
        func selfFlos() -> [Flo]? {
            guard let parent, wildcard.isEmpty else { return nil }
            for sibling in parent.children {
                if sibling.name == prefix {
                    return [sibling]
                }
            }
            return nil
        }
        func parentFlos() -> [Flo]? {
            guard findOps.parents else { return nil }
            if let parent {
                return parent.findPathNames(path, findOps)
            } else if prefix == "" {
                return findPathFlos(wildcard + suffix, findOps)
            }
            return nil
        }
        func collectLeaves(_ leaves: inout [Flo],_ flo: Flo) {
            if flo.children.isEmpty,
               !flo.name.hasChar(in: ".*˚") {
                leaves.append(flo)
            } else {
                for child in flo.children {
                    if !flo.name.hasChar(in: ".*˚"),
                       flo.type != .base {
        
                        collectLeaves(&leaves, child)
                    }
                }
            }
        }
    }

    func findPrefixFlo(_ prefix: String, _ findOps: FloFindOps) -> Flo? {
        if prefix == ""   { return self }
        if name == prefix { return self }
        if findOps.children {
            for child in children {
                if [.remove, .base].contains(child.type) {
                    continue
                }
                if child.name == prefix { return child }
            }
        }
        // still no match, so maybe search parents
        if findOps.parents,
            let parent = parent {
            return parent.findPrefixFlo(prefix, findOps)
        }
        return nil
    }

    func getWildSuffix(_ wildcard: String, _ suffix: String, _ findOps: FloFindOps) -> [Flo]? {
        // after finding starting point, only search children
        // and maybe create a flos, when specified in some cases.
        let nextOps = findOps.intersection([.children, .makePath])

        var found = [Flo]()
        if let pathRefs {
            for pathRef in pathRefs {
                found.append(contentsOf: getWild(flo: pathRef) ?? [])
            }
        } else {
            found.append(contentsOf: getWild(flo: self) ?? [])
        }
        return found.isEmpty ? nil : found

        func getWild(flo: Flo) -> [Flo]? {
            switch wildcard.first {
            case ".": return flo.getNearDots(wildcard, suffix, nextOps)
            case "˚": return flo.getDegreeFlos(wildcard, suffix)
            default:  return [flo]
            }
        }
    }

    /// find for original, not merged refeference
    func findOriginalPathFlos(_ path: String, _ findOps: FloFindOps) -> [Flo]? {

        let (_, wildcard, suffix) = path.splitWild(".*˚")

        for siblings in parent?.children ?? [] {
            if siblings.name == name {
                let found = siblings.findPathFlos(wildcard + suffix, [.children])
                return found
            }
        }
        return nil
    }

    func findPathFlos(_ path: String, _ findOps: FloFindOps) -> [Flo]? {
        guard !path.isEmpty else { return nil }

        let (prefix, wildcard, suffix) = path.splitWild(".*˚")

        return (findDotName() ??
                findStarName() ??
                findPrefix() ??
                makePath() ??
                nil)


        func findDotName() -> [Flo]? {
            if prefix.count > 0 {  return nil }
            var dotCount = 0
            for char in wildcard {
                if char != "." { break  }
               dotCount += 1
            }
            if dotCount == 0 { return nil }
            var anchor = self
            var countdown = dotCount
            while countdown > 1, let parent = anchor.parent {
                anchor = parent
                countdown -= 1
            }
            let nextPath = wildcard.dropFirst(dotCount) + suffix
            if nextPath.isEmpty {
                return [anchor]
            } else {
                return anchor.findPathFlos(String(nextPath), .children)
            }
        }

        func findPrefix() -> [Flo]? {
            if let prefixFlo = findPrefixFlo(prefix, findOps) {
                return prefixFlo.getWildSuffix(wildcard, suffix, findOps)
            }
            return nil
        }
        
        /// still no match, so maybe make a new flo
        /// make a.b, c.d in in `a.b { c.d }`
        /// make e.f but not g.h in `e.f <- g.h`
        func makePath() -> [Flo]? {
            var found = [Flo]()
            if findOps.makePath,
               prefix.count > 0,
               !path.contains("˚"), // cannot make b in `a˚b` or `a.*.b`
               !path.contains("*") {
                
                for pathNames in findPathNames(prefix) ?? [] {
                    if let newPath = pathNames.makePath(suffix, nil) {
                        found.append(newPath)
                    }
                }
            }
            return found.isEmpty ? nil : found
        }
        
        /// a in `a*`        => [self]
        /// abacab in `a*b`  => [self]
        /// NOT aba in `a*b` => []
        /// TODO `a*b.whatever` is undefined
        func findStarName() -> [Flo]? {
            guard wildcard == "*" else { return nil }
            if (prefix.count > 0 && name.hasPrefix(prefix)) ||
                (suffix.count > 0 && name.hasSuffix(suffix)) {

                return [self]
            } else if suffix.isEmpty, prefix.isEmpty {

                var found = [Flo]()
                let startFlo = findOps.parents ? parent ?? self : self
                for child in startFlo.children {
                    if !child.name.hasChar(in: ".*˚") {
                        found.append(child)
                    }
                }
                return found
            } else if let parent {
                var found = [Flo]()
                for child in parent.children {
                    if !child.name.hasChar(in: ".*˚") {
                        found.append(child)
                    }
                }
                return found
            }
            return nil
        }
    }

    /// expand path to new flos
    ///
    ///     a.b.c.d { e.f } ⟹
    ///     √ { a { b { c { d { e { f } } } } } }
    ///
    @discardableResult
    func makePath(_ path: String, _ head: Flo?) -> Flo? {

        let (prefix, _, suffix) = path.splitWild(".")
        if prefix != "" {
            let child = findOrMakeChild(prefix)
            if suffix.isEmpty, let head = head {

                child.children = head.children
                child.exprs = head.exprs

            } else {
                // don't return tail of path chain
                child.makePath(suffix, head)
            }
            // return nead of path chain
            return child
        }
        return nil
        
        func findOrMakeChild(_ name: String = "") -> Flo {
            for child in parent?.children ?? [] { // replace with orderedDictionary parent?[name]
                if child.name == name {
                    return child
                }
            }
            let child = Flo(name)
            child.parent = self
            children.append(child)
            return child
        }
    }

    public func findPath(_ path: String) -> Flo? {

        if path == "" { return self }

        let (prefix, _, suffix) = path.splitWild(".")

        for child in children {
            if child.name == prefix { return child.findPath(suffix) }
        }
        return nil
    }
    public func findPath_(_ path: String) -> Flo? {

        if let flo = findPath(path) { return flo }
        if let flo = findPath("_" + path) { return flo }
        return nil
    }
    public func bind(_ path: String,
                     _ closure: FloVisitor? = nil) -> Flo {

        if let flo = findPath_(path) {
            if let closure {
                flo.addClosure(closure) 
            }
            return flo
        }
        PrintLog("⁉️ Flo::bind \'\(path)\' not found")
        return Flo(path + "?")
    }

    public func superBindPath(_ path: String) -> Flo? {

        if let flo = superBind(path) {

            flo.soloClosure { flo, visit in

                if let fromExprs = visit.from?.exprs,
                   let toExprs = self.exprs {

                    for name in toExprs.nameAny.keys {
                        if let fromAny = fromExprs.nameAny[name] {
                            toExprs.nameAny[name] = fromAny
                        }
                    }
                }
            }
            return flo
        }
        return nil
    }

    public func superBind(_ path: String,
                          _ depth: Int = 0,
                          _ closure: FloVisitor? = nil) -> Flo? {

        if let flo = findPath(path) {
            if let closure {
                // only one closure to avoid duplicates for subFlo 
                flo.soloClosure(closure)
            }
            return flo
        }
        if let flo = parent?.superBind(path,  depth + 1, closure) {
            return flo
        } else if depth == 0 {
            PrintLog("⁉️ Flo::superBind \'\(path)\' not found")
        }
        return nil
    }

}
