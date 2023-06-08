//  Created by warren on 1/24/23.

import Foundation

extension FloValScalar { // + Parse
    
    func parseNum(_ num: Double,
                  _ parset: FloParset) {

        if valOps.thrui {
            if valOps.max {
                next = num
                now = num
            } else if valOps.min {
                valOps += .max
                max = num
            } else {
                valOps += .min
                min = num
            }
        } else if valOps.modu {
            if valOps.max {
                next = num
                now = num
            } else {
                valOps += .max
                max = num
            }
        } else {
            valOps += .lit
            if parset.match { valOps += .match }
            if parset.equal { valOps += .equal }
            dflt = num
            next = num
            now = num
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
            valOps += [.now_,.next]
            now = n
            next = n
        }
    }
}
