//  Created by warren on 1/24/23.

import Foundation

extension FloValScalar { // + Parse
    
    func parseNum(_ num: Double,
                  _ parset: FloParset) {

        if valOps.thrui {
            if valOps.max {
                val = num
                twe = num
            } else if valOps.min {
                valOps += .max
                max = num
            } else {
                valOps += .min
                min = num
            }
        } else if valOps.modu {
            if valOps.max {
                val = num
                twe = num
            } else {
                valOps += .max
                max = num
            }
        } else {
            valOps += .lit
            if parset.match { valOps += .match }
            if parset.equal { valOps += .equal }
            dflt = num
            val = num
            twe = num
        }
    }
    func parseDflt(_ n: Double) {
        if !n.isNaN {
            valOps += .dflt
            dflt = n
            twe = n
        }
    }
    func parseNow(_ n: Double) {
        if !n.isNaN {
            valOps += [.val]
            twe = n
            val = n
        }
    }
}
