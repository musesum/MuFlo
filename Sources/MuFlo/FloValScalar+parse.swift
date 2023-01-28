//  Created by warren on 1/24/23.

import Foundation

extension FloValScalar { // + Parse
    
    func parseNum(_ n: Double) {

        if valOps.thru {
            if valOps.max {
                now = n
            } else if valOps.min {
                valOps += .max
                max = n
            } else {
                valOps += .min
                min = n
            }
        } else if valOps.modu {
            if valOps.max {
                now = n
            } else {
                valOps += .max
                max = n
            }
        } else {
            valOps += .lit
            dflt = n
            now = n
        }
    }
    func parseDflt(_ n: Double) {
        if !n.isNaN {
            valOps += .dflt
            dflt = n
            now = n
        }
    }
    func parseNow(_ n: Double) {
        if !n.isNaN {
            valOps += .now
            now = n
        }
    }
}
