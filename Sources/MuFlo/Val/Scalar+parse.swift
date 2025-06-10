//  created by muse∂sum on 1/24/23.
//  created by muse∂sum on 1/24/23.

import Foundation

extension Scalar { // + Parse

    func parseRange(_ num: Double) {
        if scalarOps.maxim {
            value = num
            tween = num
        } else if scalarOps.minim {
            scalarOps |= .maxim
            maxim = num
        } else {
            scalarOps |= .minim
            minim = num
        }
    }

    func parseNum(_ num: Double) {
        scalarOps |= .liter
        origin = num
        value = num
        tween = num
    }
    func parseOrigin(_ num: Double) {
        if !num.isNaN {
            scalarOps |= .origin
            origin = num
            tween = num
        }
    }
    func parseNow(_ num: Double) {
        if !num.isNaN {
            scalarOps |= .value
            tween = num
            value = num
        }
    }
}
