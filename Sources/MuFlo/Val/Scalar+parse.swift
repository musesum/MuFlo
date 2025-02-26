//  created by musesum on 1/24/23.

import Foundation

extension Scalar { // + Parse

    func parseRange(_ num: Double) {
        if options.maxi {
            value = num
            tween = num
        } else if options.mini {
            options += .maxi
            maxi = num
        } else {
            options += .mini
            mini = num
        }
    }

    func parseNum(_ num: Double) {
        options += .liter
        dflt = num
        value = num
        tween = num
    }
    func parseDflt(_ num: Double) {
        if !num.isNaN {
            options += .dflt
            dflt = num
            tween = num
        }
    }
    func parseNow(_ num: Double) {
        if !num.isNaN {
            options += .value
            tween = num
            value = num
        }
    }
}
