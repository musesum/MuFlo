//  Flo+script.swift
//  created by musesum on 4/16/19.

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

    public func script(_ scriptOps: FloScriptOps) -> String {
        
        var script = name
        if let str = exprs?.scriptVal(scriptOps, /* viaEdge */ false),
           str.count > 0 {
            script.spacePlus(str)
        }

        if scriptOps.compact {
            switch children.count {
                case 0: script.spacePlus(comments.getComments(.child, scriptOps))
                case 1: scriptAddOnlyChild()
                default: scriptAddChildren()
            }
        } else { // not pretty
            switch children.count {
                case 0: script.spacePlus(comments.getComments(.child, scriptOps))
                default: scriptAddChildren()
            }
        }
        script.spacePlus(edgeDefs.scriptEdgeVal(scriptOps))
        script.spacePlus(comments.getComments(.edges, scriptOps))
        return script
        
        func scriptAddChildren() {
            script.spacePlus("(")
            script.spacePlus(comments.getComments(.child, scriptOps))
            optionalLineFeed()
            
            for child in children {
                script.spacePlus(child.script(scriptOps))
                optionalLineFeed()
            }
            script.spacePlus(")")
            script += scriptOps.noLF ? "" : "\n"
        }
        /// print `a.b.c` instead of `a { b { c } } }`
        func scriptAddOnlyChild() {
            script += "."
            for child in children {
                script += child.script(scriptOps)
            }
        }
        func optionalLineFeed() {
            // optional line feed
            if !scriptOps.noLF,
               script.last != "\n",
               script.last != "," {
                script += "\n"
            }
        }
    }
    
    func getCopiedFrom() -> String {
        var result = ""
        var delim = ""
        var lastType = FloType.unknown
        for copyFlo in copied {
            if lastType != copyFlo.type {
                lastType = copyFlo.type
                delim = lastType == .copyall ? "©" : "@"
            }
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
                script.spacePlus(comments.getComments(.edges, scriptOps))
            }
        } else if edgeDefs.edgeDefs.count > 0 {

            script.spacePlus(edgeDefs.scriptEdgeVal(scriptOps))
            script.spacePlus(comments.getComments(.edges, scriptOps))
        }
        return script
    }

    private func scriptPathRefs(_ edge: FloEdge) -> String {

        if let pathRefs = edge.rightFlo.pathRefs, pathRefs.count > 0  {

            var script = pathRefs.count > 1 ? "(" : ""
            var delim = ""
            
            for pathRef in pathRefs {
                script += delim + pathRef.scriptLineage(2)
                delim = ", "
            }
            if pathRefs.count > 1 { script += ")" }
            return script
        }
        return ""
    }
    
    func scriptTypeEdges(_ edges: [FloEdge],
                         _ scriptOps: FloScriptOps) -> String {

        guard let firstEdge = edges.first else { return "" }
        var script = firstEdge.edgeOps.script(active: firstEdge.active)
        var delim = ""
        if edges.count > 1 {
            script.spacePlus("(")
        } else {
            delim = " "
        }

        for edge in edges  {
            
            let pathScript = scriptPathRefs(edge)
            if pathScript.count > 0 {
                script += delim + pathScript
            } else {
                script += delim + edge.scriptEdgeVal(self, scriptOps)
                delim = ", "
            }
        }
        if edges.count > 1 { script += ")" }
        return script
    }
    
    private func scriptFloEdges(_ scriptOps: FloScriptOps) -> String? {
        
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
                        result.spacePlus(scriptTypeEdges(leftTypeEdges, scriptOps))
                        leftTypeEdges.removeAll()
                    }
                    leftTypeEdges.append(edge)
                }
                result.spacePlus(scriptTypeEdges(leftTypeEdges, scriptOps))
                return result.without(trailing: " ")
            }
        }
        return nil
    }

    func scriptChildren(_ scriptOpts: FloScriptOps) -> String {

        let showChildren = showChildren(scriptOpts)
        switch showChildren.count {

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
            return "." + (showChildren.first?.scriptFlo(scriptOpts) ?? "")
        }
        func scriptManyChildren() -> String {
            let comment = comments.getComments(.child, scriptOpts).without(trailing: " \n")

            var script = "{"
            script += (comment.count > 0 ? " " + comment + "\n"
                        : scriptOpts.noLF ? "" : "\n")

            var childScript = ""
            for showChild in showChildren {
                childScript.spacePlus(showChild.scriptFlo(scriptOpts))
            }

            script.spacePlus(childScript)
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
    public func scriptFlo(_ scriptOps: FloScriptOps) -> String {

        if scriptOps.delta, !hasDelta {
             return ""
        }

        var script = name
        if scriptOps.def {
            script.spacePlus(getCopiedFrom())
        }
        let scriptExprs = exprs?.scriptVal(scriptOps, /*viaEdge*/ false) ?? ""
        script += scriptExprs
        if scriptOps.edge {
            script.spacePlus(scriptEdgeDefs(scriptOps))
        }
        if children.isEmpty {
            let comments = comments.getComments(.child, scriptOps)
            script.spacePlus(comments)
            // optional line feed
            if !scriptOps.noLF,
               scriptExprs.count > 0,
               comments.count == 0 {

                script += "\n"
            }
        } else {
            let childScript = scriptChildren(scriptOps)
            if childScript.first == "." {
                script += childScript
            } else {
                script.spacePlus(childScript)
            }
        }
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
