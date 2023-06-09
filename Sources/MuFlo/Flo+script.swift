//  Flo+script.swift
//
//  Created by warren on 4/16/19.
//  Copyright © 2019 DeepMuse

import Foundation


extension Flo {
    
    /** Is this Flo elegible to shorten with a dot?
     
     shorten `a { z }` to `a.z`,
     but not `a(1) { z }` to a(1).z,
     and not `a<<b { z }` to a<<b.z,
     */
    private func canShortenWithDot() -> Bool {
        if exprs != nil, edgeDefs.edgeDefs.count > 0 {
            return true
        }
        return false
    }

    public func script(_ scriptOpts: FloScriptOps) -> String {
        
        var script = name
        script.spacePlus(exprs?.scriptVal(scriptOpts))
        
        if scriptOpts.compact {
            switch children.count {
                case 0: script.spacePlus(comments.getComments(.child, scriptOpts))
                case 1: scriptAddOnlyChild()
                default: scriptAddChildren()
            }
        } else { // not pretty
            switch children.count {
                case 0: script.spacePlus(comments.getComments(.child, scriptOpts))
                default: scriptAddChildren()
            }
        }
        script += edgeDefs.scriptVal(scriptOpts)
        script += comments.getComments(.edges, scriptOpts)
        return script
        
        func scriptAddChildren() {
            script.spacePlus("(")
            script.spacePlus(comments.getComments(.child, scriptOpts))
            optionalLineFeed()
            
            for child in children {
                script.spacePlus(child.script(scriptOpts))
                optionalLineFeed()
            }
            script.spacePlus(")")
            script += scriptOpts.noLF ? "" : "\n"
        }
        /// print `a.b.c` instead of `a { b { c } } }`
        func scriptAddOnlyChild() {
            script += "."
            for child in children {
                script += child.script(scriptOpts)
            }
        }
        func optionalLineFeed() {
            // optional line feed
            if !scriptOpts.noLF,
               script.last != "\n",
               script.last != "," {
                script += "\n"
            }
        }
    }
    
    func getCopiedFrom() -> String {
        var result = ""
        var delim = "@"
        for copyFlo in copied {
            result += delim + copyFlo.name
            delim = ", "
        }
        if result.count > 0 {
            result += " "
        }
        return result
    }
    
    private func scriptEdgeDefs(_ scriptOps: FloScriptOps) -> String {
        var script = ""
        if let edgesScript = scriptFloEdges(scriptOps) {
            
            script = edgesScript
            if floEdges.count == 1 {
                script += comments.getComments(.edges, scriptOps)
            }
        } else if edgeDefs.edgeDefs.count > 0 {

            script += edgeDefs.scriptVal(scriptOps)
            script += comments.getComments(.edges, scriptOps)
        }
        return script
    }
    
    private func scriptPathRefs(_ edge: FloEdge) -> String {
        if let pathRefs = edge.rightFlo.pathRefs, pathRefs.count > 0  {
            var script = pathRefs.count > 1 ? "(" : ""
            var delim = ""
            
            for pathRef in pathRefs {
                script += delim + pathRef.scriptLineage(2)
                delim = comments.getEdgesDelim()
            }
            if pathRefs.count > 1 { script += ") " }
            return script
        }
        return ""
    }
    
    func scriptTypeEdges(_ edges: [FloEdge],
                         _ scriptOps: FloScriptOps) -> String {

        guard let firstEdge = edges.first else { return "" }
        var script = firstEdge.edgeOps.script(active: firstEdge.active)
        if edges.count > 1 { script += "(" }
        var delim = " "
        for edge in edges  {
            
            let pathScript = scriptPathRefs(edge)
            if pathScript.count > 0 {
                script += delim + pathScript
            } else {
                script += delim + edge.scriptEdgeVal(self, scriptOps)
                delim = comments.getEdgesDelim()
            }
        }
        if edges.count > 1 { script += ")" }
        return script
    }
    
    private func scriptFloEdges(_ scriptOpts: FloScriptOps) -> String? {
        
        if floEdges.count > 0 {
            
            var leftEdges = [FloEdge]()
            for edge in floEdges.values {
                if edge.leftFlo == self {
                    leftEdges.append(edge)
                }
            }
            if leftEdges.count > 0 {
                
                leftEdges.sort { $0.id < $1.id }
                var result = ""
                var edgeOps = FloEdgeOps()
                var leftTypeEdges = [FloEdge]()
                for edge in leftEdges {
                    if edge.edgeOps != edgeOps {
                        
                        edgeOps = edge.edgeOps
                        result += scriptTypeEdges(leftTypeEdges, scriptOpts)
                        leftTypeEdges.removeAll()
                    }
                    leftTypeEdges.append(edge)
                }
                result += scriptTypeEdges(leftTypeEdges, scriptOpts)
                return result
            }
        }
        return nil
    }

    func scriptChildren(_ scriptOpts: FloScriptOps) -> String {

        let showKids = showChildren(scriptOpts)
        switch showKids.count {

            case 0: return ""
            case 1:
                if scriptOpts.compact {
                    return scriptCompactChild()
                } else {
                    return scriptManyChildren()
                }
            default: return scriptManyChildren()
        }
        func scriptCompactChild() -> String {
            return "." + (showKids.first?.scriptFlo(scriptOpts) ?? "")
        }
        func scriptManyChildren() -> String {
            let comment = comments.getComments(.child, scriptOpts).without(trailing: " \n")

            var script = "{"
            script += (comment.count > 0 ? comment + "\n"
                        : scriptOpts.noLF ? " " : "\n")

            var kidScript = ""
            for kid in showKids {
                kidScript.spacePlus(kid.scriptFlo(scriptOpts))
            }

            script.spacePlus(kidScript)
            script.spacePlus("}")
            script += scriptOpts.noLF ? "" : "\n"
            return script
        }
    }

    func showChildren(_ scriptOpts: FloScriptOps) -> [Flo] {
        if scriptOpts.delta {
            if !hasDelta { return [] }
            var result = [Flo]()
            for child in children {
                if child.hasDelta {
                    result.append(child)
                }
            }
            return result
        } else {
            return children
        }
    }
    public func scriptCompactRoot(_ scriptOpts: FloScriptOps) -> String {
        var script = ""
        for child in children {
            script += child.script(scriptOpts)
        }
        return script
    }

    /// Populate tree hierarchy of total changes made to each subtree.
    /// When using FloScriptFlag .delta, no changes to subtree are printed out
    func hasDeltas() -> Bool {
        hasDelta = false
        if let exprs {
            for v in exprs.nameAny.values {
                // does expression have a delta
                if let vv = v as? FloValScalar,
                   !vv.valOps.isTransient,
                   vv.hasDelta() {
                    hasDelta = true
                    break // only need to check for first occurence
                }
            }
        }
        // need to set hasDelta for all descendants
        for child in children {
            if child.hasDeltas() {
                hasDelta = true
            }
        }
        return hasDelta
    }
    
    public func scriptRoot(_ ops: FloScriptOps) -> String {

        var script = ""
        if ops.delta {
            hasDelta = hasDeltas()
            for child in children {
                if child.hasDelta {
                    let childScript = child.scriptFlo(ops)
                    script.spacePlus(childScript)
                }
            }
        } else {
            for child in children {
                let childScript = child.scriptFlo(ops)
                script.spacePlus(childScript)
            }
        }
        return script
    }
    
    /// create a parse ready String
    ///
    public func scriptFlo(_ scriptOpts: FloScriptOps) -> String {

        if scriptOpts.delta, !hasDelta {
             return ""
        }

        var script = name
        if scriptOpts.def {
            script.spacePlus(getCopiedFrom())
        }
        let scriptVal = exprs?.scriptVal(scriptOpts) ?? ""
        script += scriptVal
        if scriptOpts.edge {
            script += scriptEdgeDefs(scriptOpts)
        }
        if children.isEmpty {
            
            let comments = comments.getComments(.child, scriptOpts)
            script.spacePlus(comments)
            // optional line feed
            if !scriptOpts.noLF,
               scriptVal.count > 0,
               comments.count == 0 {
                script += "\n"
            }
        } else {
            let childScript = scriptChildren(scriptOpts)
            if childScript.first == "." {
                script += childScript
            } else {
                script.spacePlus(childScript)
            }
        }
        return script
    }
    
    
    static func scriptFlos(_ flos: [Flo]) -> String {
        
        if flos.isEmpty { return "" }
        var script = flos.count > 1 ? "(" : ""
        for flo in flos {
            script.spacePlus(flo.scriptLineage(2))
        }
        script += flos.count > 1 ? ")" : ""
        return script
    }
    
    /// create "a.b.c" from c in `a{b{c}}`, but not √.b.c from b
    public func scriptLineage(_ level: Int = 999) -> String {
        if let parent = parent, parent.name != "√", level > 0  {
            return parent.scriptLineage(level-1) + "." + name
        } else {
            return name
        }
    }
    
}
