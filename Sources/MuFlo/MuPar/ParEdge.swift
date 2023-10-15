//  ParEdge.swift
//  created by musesum on 7/3/17.

import Foundation

/// An ParEdge connects and is shrared by two nodes
public class ParEdge {
    
    static let MaxReps = 200
    
    var nodePrev: ParNode?  // edge predecessor
    var nodeNext: ParNode?  // edge successor
    
    init(_ nodePrev: ParNode, _ nodeNext: ParNode) {
        
        self.nodePrev = nodePrev
        self.nodeNext = nodeNext
        
        self.nodePrev?.edgeNexts.append(self)
        self.nodeNext?.edgePrevs.append(self)
    }
}

