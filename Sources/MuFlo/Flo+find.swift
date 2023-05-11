//  Flo+find.swift
//
//  Created by warren on 5/2/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar

extension Flo {

    // returns a.b in `a { b { c } } a˚b`
    // returns a.b.c in `a { b { c } } a˚c`
    // returns a.b1.c, a.b2.c in `a { b1 { c } b2 { c } } a˚c`

    // ? in `˚`   // undefined
    // a in `˚a`  // add if matches b and stop, otherwise continue
    // a in `˚˚a` // add if matches b, always continue
    // _ in `˚˚`  // add in all cases, always continue
    // a in `˚.a` // add if matches b and no children and stop, otherwise continue
    // _ in `˚.`  // add if no children, otherwise continue

    func getDegreeFlos(_ wildcard: String, _ suffix: String) -> [Flo] {

        let greedy = wildcard == "˚˚"
        let leafy = wildcard == "˚."
        var found = [Flo]()

        func findDeeper() {
            for child in children {
                let foundChild = child.getDegreeFlos(wildcard, suffix)
                found.append(contentsOf: foundChild)
            }
        }
        // ────────────── begin ──────────────
        // do not incude ˚˚ in `˚˚ <-> ..`
        if type == .path {
            return []
        } else if suffix.isEmpty {                        // for a { b { c } }

            if greedy {                                 //  a, b, c in ˚˚˚
                found.append(self)
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
                    if children.isEmpty { found = [self] }   // c in ˚.c
                    else                { return [] }       // b in ˚.b
                }
                else {
                    found = [self]                          // b in ˚b,˚˚b
                    if greedy { findDeeper() }
                }
            } else {                                          // !b in ˚b,˚˚b
                findDeeper()
            }
            for foundi in found {
                let foundi2 = foundi.getWildSuffix(wild2, suffix2, .children)
                found2.append(contentsOf: foundi2)
            }
            return found2
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
    func getNearDots(_ wildcard: String, _ suffix: String, _ findOps: FloFindOps) -> [Flo] {
        if wildcard == ".*" {
            return children
        }
        if let parent = getDotParent(wildcard.count-1) {
            let nextOps = findOps.intersection([.parents, .children, .makePath])
            return parent.findPathFlos(suffix, nextOps)
        } else {
            return []
        }
    }

    /// find preexisting item 
    public func findAnchor(_ path: String, _ findOps: FloFindOps) -> [Flo] {

        let (prefix, wildcard, suffix) = path.splitWild(".*˚")

        let deeperOps = findOps.intersection([.children, .makePath])

        if name == prefix, type == .name {
            return findPathFlos(wildcard + suffix, [.children])
        } else if name == prefix, wildcard == "", type == .copyat, let parent = parent {
            return parent.findPathFlos(path, findOps)
        } else if prefix == "", let parent = parent {
            return parent.findPathFlos(wildcard + suffix, deeperOps)
        } else if findOps.children {
            for child in children {
                if child.name == prefix, child.type == .name {
                    return child.findPathFlos(wildcard + suffix, deeperOps)
                }
            }
        }
        // still no match, so maybe search parents
        if findOps.parents {
            if let parent {
                return parent.findAnchor(path, findOps)
            } else if prefix == "" {
                return findPathFlos(wildcard + suffix, findOps)
            }
        }
        return []
    }

    func findPrefixFlo(_ prefix: String, _ findOps: FloFindOps) -> Flo? {
        if prefix == ""   {
            return self }
        if name == prefix {
            return self }
        if findOps.children {
            for child in children {
                if child.type == .remove { continue }
                if child.type == .copyat { continue }
                if child.name == prefix {
                    return child }
            }
        }
        // still no match, so maybe search parents
        if findOps.parents,
            let parent = parent {
            return parent.findPrefixFlo(prefix, findOps)
        }
        return nil
    }

    func getWildSuffix(_ wildcard: String, _ suffix: String, _ findOps: FloFindOps) -> [Flo] {
        // after finding starting point, only search children
        // and maybe create a flos, when specified in some cases.
        let nextOps = findOps.intersection([.children, .makePath])

        func getWild(flo: Flo) -> [Flo] {

            switch wildcard.first {
            case ".": return flo.getNearDots(wildcard, suffix, nextOps)
            case "˚": return flo.getDegreeFlos(wildcard, suffix)
            default:  return [flo]
            }
        }

        var found = [Flo]()
        if let pathRefs {
            for pathRef in pathRefs {
                found.append(contentsOf:  getWild(flo: pathRef))
            }
        } else {
            found.append(contentsOf:  getWild(flo: self))
        }
        return found
    }

    func findPathFlos(_ path: String, _ findOps: FloFindOps) -> [Flo] {

        let (prefix, wildcard, suffix) = path.splitWild(".*˚")

        func isStarMatch() -> Bool {

            if wildcard.first == "*",
                (name.hasPrefix(prefix) || prefix == "") {
                // get b in `a*b.c`
                let (suffix2, _, _) = suffix.splitWild(".*˚")
                if name.hasSuffix(suffix2) || suffix2 == "" {
                    // a in `a*`        => [self]
                    // abacab in `a*b`  => [self]
                    // NOT aba in `a*b` => []
                    // TODO `a*b.whatever` is undefined
                    return true
                }
            }
            return false
        }

        // ────────────── begin ──────────────

        if isStarMatch() {
            return [self]

        } else if let prefixFlo = findPrefixFlo(prefix, findOps) {

            let found = prefixFlo.getWildSuffix(wildcard, suffix, findOps)
            if found.count > 0 { return found }
        }

        // still no match, so maybe make a new flo
        // make a.b, c.d in in `a.b { c.d }`
        // make e.f but not g.h in `e.f <- g.h`
        if findOps.makePath {

            if !prefix.isEmpty {
                // cannot make b in `a˚b` or `a.*.b`
                if path.contains("˚") || path.contains("*") {
                    return []
                }

                var found = [Flo]()
                let anchors = findAnchor(prefix, [.parents, .children])
                for anchori in anchors {
                    if let foundi = anchori.makePath(suffix, nil) {
                        found.append(foundi)
                    }
                }
                return found
            }
        }
        return []
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
            let child = makeChild(prefix)
            if suffix.isEmpty, let head = head {

                child.children = head.children
                child.val = head.val

            } else {
                // don't return tail of path chain
                child.makePath(suffix, head)
            }
            // return nead of path chain
            return child
        }
        return nil
    }

    public func findPath(_ path: String) -> Flo? {

        if path == "" { return self }

        let (prefix, _, suffix) = path.splitWild(".")

        if name == prefix { return findPath(suffix) }

        for child in children {
            if child.name == prefix { return child.findPath(suffix) }
        }
        return nil
    }
    public func bind(_ path: String,
                     _ showError: Bool = true,
                     _ closure: FloVisitor? = nil) -> Flo {

        if let flo = findPath(path) {
            if let closure {
                flo.addClosure(closure)
                //??? closure(self, Visitor(0, from: .bind))
            }
            return flo

        } else if showError {
            print("🚫 Flo:: could not find \'\(path)\'")
        }
        return Flo()
    }

}
