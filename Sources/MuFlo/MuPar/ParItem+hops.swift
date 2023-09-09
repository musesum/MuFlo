//  ParItem+hops.swift
//  
//  Created by warren on 9/13/19.
//  License: Apache 2.0 - see License file

import Foundation

extension ParItem {

    public func totalHops() -> Int {
        let value = value ?? ""
        var totalHops =  value.count > 0 ? hops : 0
        for nextPar in nextPars {
            totalHops += nextPar.totalHops()
        }
        return totalHops
    }

    public func foundString(withHops: Bool = true) -> String {
        let value = value ?? ""
        var found = value

        if withHops, value.count > 0 {
            found += ":\(hops)"
        }
        for nextPar in nextPars {
            found += nextPar.foundString()
        }
        if found != "", found.first != " " {
            found = " " + found
        }
        return found
    }
}
