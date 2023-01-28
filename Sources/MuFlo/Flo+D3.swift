//
//  Flo+D3.swift
//  FloGraph
//
//  Created by warren on 6/22/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
extension FloEdge {

    func makeD3Edge(_ separator: String) -> String {
        let arrow = edgeOps.script()
        return separator + "'\(leftFlo.id)\(arrow)\(rightFlo.id)'"
    }
}
extension Flo {

    func makeD3Node() -> String {
        
        var script = "\t\t{'id':\(id), 'name':'\(name)'"
        if children.count > 0 {
            script += ", 'children': ["
            var sep = ""
            for child in children {
                script += sep + "\(child.id)"
                sep = ","
            }
            script += "]"
        }
        if floEdges.count > 0 {
            var leftEdgeCount = 0
            for edge in floEdges.values {
                if edge.leftFlo.id == id {
                    leftEdgeCount += 1
                }
            }
            if leftEdgeCount > 0 {
                script += ", 'edges': ["
                var sep = ""
                for edge in floEdges.values {
                    if edge.leftFlo.id == id {
                        script += edge.makeD3Edge(sep)
                        sep = ","
                    }
                }
                script += "]"
            }
        }
        script += "},\n";
        if children.count > 0 {

            for child in children {
                script += child.makeD3Node()
            }
        }
        return script
    }

    func makeD3ChildEdges() -> String {

        var script = ""

        for child in children {
            script += "{'id':'\(id).\(child.id)', 'source':\(id), 'target':\(child.id), 'type':'.'},\n"
        }
        for child in children {
            script += child.makeD3ChildEdges()
        }
        return script
    }

    func makeD3EdgeEdges() -> String {

        var script = ""

        for edge in floEdges.values {
            
            let leftId = edge.leftFlo.id
            let rightId = edge.rightFlo.id
            if leftId == id {

                let type = edge.edgeOps.script(active: false)
                script += "{'id':'\(leftId)\(type)\(rightId)', 'source':\(leftId), 'target':\(rightId), 'type':'\(type)'},\n"
            }
        }
        for child in children {
            script += child.makeD3EdgeEdges()
        }
        return script
    }

    func makeD3Script() -> String  {

        var script = "var graph = {\n\t'nodes': [\n"
        script += makeD3Node()
        script += "\t],\n\t'links': [\n"
        script += makeD3ChildEdges()
        script += makeD3EdgeEdges()
        script += "\t]\n}"
        return script
    }
}

