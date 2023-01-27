//
//  File.swift
//  
//
//  Created by warren on 1/24/23.
//

import Foundation

extension FloValScalar { // + Parse
    
    func parseNum(_ n: Double) {

        if valFlags.thru {
            if valFlags.max {
                now = n
            } else if valFlags.min {
                valFlags.insert(.max)
                max = n
            } else {
                valFlags.insert(.min)
                min = n
            }
        } else if valFlags.modu {
            if valFlags.max {
                now = n
            } else {
                valFlags.insert(.max)
                max = n
            }
        } else {
            valFlags.insert(.lit)
            dflt = n
            now = n
        }
    }
    func parseDflt(_ n: Double) {
        if !n.isNaN {
            valFlags.insert(.dflt)
            dflt = n
            now = n
        }
    }
    func parseNow(_ n: Double) {
        if !n.isNaN {
            valFlags.insert(.now)
            now = n
        }
    }
}
