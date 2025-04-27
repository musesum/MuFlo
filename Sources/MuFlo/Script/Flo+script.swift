//  Flo+script.swift
//  created by musesum on 4/16/19.

import Foundation

extension Flo { // + script

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

    public func scriptEdgeDefs(_ scriptOps: FloScriptOps) -> String {

        var script = ""

        if let edgesScript = scriptFloEdges(scriptOps) {

            script = edgesScript
            if floEdges.count == 1 {
                let comment = comments.scriptComments(.edge, scriptOps)
                script.spacePlus(comment)
            }
        } else if edgeDefs.edgeDefs.count > 0, scriptOps.edge {

            script.commaPlus(edgeDefs.scriptEdgeVal(self,scriptOps))
        }
        return script
    }

    private func scriptPathRefs(_ edge: Edge) -> String {

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
    
    func scriptTypeEdges(_ edges: [Edge],
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
            
            var leftEdges = [Edge]()
            for edge in floEdges.values {
                if edge.leftFlo == self {
                    leftEdges.append(edge)
                }
            }
            if leftEdges.count > 0 {
                
                leftEdges.sort { $0.id < $1.id }
                var script = ""
                var edgeOps = EdgeOptions()
                var leftTypeEdges = [Edge]()

                for edge in leftEdges {

                    if edge.edgeOps != edgeOps {
                        edgeOps = edge.edgeOps
                        script.commaPlus(scriptTypeEdges(leftTypeEdges, scriptOps))
                        leftTypeEdges.removeAll()
                    }
                    leftTypeEdges.append(edge)
                }
                script.commaPlus(scriptTypeEdges(leftTypeEdges, scriptOps))
                return script.without(trailing: " ")
            }
         }
        return nil
    }

    func scriptChildren(_ scriptOpts: FloScriptOps) -> String {

        let showChildren = showChildren(scriptOpts)
        switch showChildren.count {

            case 0: return ""
            case 1: return maybeCompactChild()
            default: return scriptManyChildren()
        }
        func maybeCompactChild() -> String {

            if (!scriptOpts.compact ||
                comments.have(type: .branch)) {

                return scriptManyChildren()

            } else if let child = showChildren.first {

                guard let firstChild = showChildren.first  else { return "" }
                let symbol =  (child.type == .base ? ":" : ".")
                let script = firstChild.scriptFlo(scriptOpts)
                return symbol + script
            }
            return ""
        }
        func scriptManyChildren() -> String {
            let comment = comments.scriptComments(.branch, scriptOpts).without(trailing: " \n")
            
            var script = "{"
            if comment.count > 0 {
                script += " " + comment + "\n"
            } else if !scriptOpts.noLF {
                script += "\n"
            }

            var childScript = ""
            for showChild in showChildren {
                childScript.spacePlus(showChild.scriptFlo(scriptOpts))
            }

            script.spacePlus(childScript)
            if !scriptOpts.noLF {
                if script.last != "\n" { script += "\n" }
            }
            script.spacePlus("}")
            if !scriptOpts.noLF {
               script += "\n"
            }
            return script
        }
    }

    func showChildren(_ scriptOps: FloScriptOps) -> [Flo] {
        if scriptOps.delta {
            if !deltaTween { return [] }
            var result = [Flo]()
            for child in children {
                if child.deltaTween {
                    result.append(child)
                }
            }
            return result
        } else {
            return children
        }
    }
    /// Populate tree hierarchy of total changes made to each subtree.
    /// When using FloScriptFlag .delta, no changes to subtree are printed out
    func hasDeltas() -> Bool {
        if let exprs {
            for expr in exprs.nameAny.values {
                // does expression have a delta
                if let scalar = expr as? Scalar,
                   scalar.hasDelta() {
                    deltaTween = true
                    break // only need to check for first occurence
                }
            }
        }
        // need to set hasDelta for all descendants
        for child in children {
            if child.hasDeltas() {
                deltaTween = true
            }
        }
        return deltaTween
    }

    public func scriptRoot(_ ops: FloScriptOps) -> String {

        var script = ""
        if ops.delta {
            deltaTween = hasDeltas()
            for child in children {
                if child.deltaTween {
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

    public func scriptOnlyFlo() -> String {
        var script = name
        var scriptExpr = ""
        if let exprs {
            scriptExpr = exprs.scriptVal(self, .All, viaEdge: false)
        } else if let scriptEdge = scriptFloEdges(.All) {
            scriptExpr = "(\(scriptEdge))"
        }
        script += scriptExpr
        return script
    }
    public func scriptPath(_ path: String) -> String {
        return findPath(path)?.scriptOnlyFlo() ?? ""
    }

    /// create a parse ready String
    public func scriptFlo(_ scriptOps: FloScriptOps) -> String {

        if scriptOps.delta, !deltaTween {
             return ""
        }
        var script = name
        var scriptExpr = ""

        if let exprs {
            scriptExpr = exprs.scriptVal(self, scriptOps, viaEdge: false)
        } else if let scriptEdge = scriptFloEdges(scriptOps) {
            scriptExpr = "(\(scriptEdge))"
        }
        script += scriptExpr

        if children.isEmpty {
            if scriptExpr.isEmpty, scriptOps.now, scriptOps.delta {
                return "" // no values to set
            }

            var singleLF = "\n"
            let comment = comments.scriptComments(.branch, scriptOps)
            if comment == "," {
                script += ", "
            } else if comment.count > 0  {
                script += " " + comment + singleLF
                singleLF = ""
            }
            if !scriptOps.noLF,
                scriptExpr.count > 0 {

                script += singleLF // may be ""
            }

        } else {
            let childScript = scriptChildren(scriptOps)
            if ".:".contains(childScript[0]) {
                script += childScript
            } else {
                script.spacePlus(childScript)
            }
        }
        return script
    }
    
    /// create "a.b.c" from c in `a{b{c}}`, but not √.b.c from b
    public func scriptLineage(_ level: Int = 999) -> String {
        if let parent, parent.name != "√", level > 0  {
            return parent.scriptLineage(level-1) + "." + name
        } else {
            return name
        }
    }

    public func scriptLineage(up: Flo) -> String? {
        let myLineage = fullLineage()
        let upLineage = up.fullLineage()

        // Determine the common prefix length.
        var count = 0
        while count < myLineage.count,
              count < upLineage.count,
              myLineage[count] == upLineage[count] {
            count += 1
        }

        // matching lineage
        if count == myLineage.count {
            return self.name
        }
        // Otherwise, return the remaining parts of the target's lineage.
        return myLineage.dropFirst(count).joined(separator: ".")
    }

    private func fullLineage() -> [String] {
        if let parent = self.parent {
            return parent.fullLineage() + [self.name]
        } else {
            return [self.name]
        }
    }

    public func scriptLineage(down: Flo) -> String? {
        if self.id == down.id {
            return ""
        }
        for child in children {
            if child.id == down.id {
                return child.name
            }
        }
        for child in children {
            if let lineage = child.scriptLineage(down: down) {
                if lineage == "" {
                    return name
                } else {
                    return name + "." + lineage
                }
            }
        }
        return nil
    }
}
