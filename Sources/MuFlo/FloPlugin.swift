//  Created by warren on 5/13/23.

import UIKit
import MuPar
import MuTime

enum FloAnimType { case linear, easeinout }

protocol FloPluginProtocal {
    func startPlugin(_ key: Int)
}

public class FloPlugin {

    var type = FloAnimType.linear
    var delay = TimeInterval(0.25)
    var duration = TimeInterval(0.5)
    var timeStart = TimeInterval(0)
    var steps = 0
    var myExprs: FloExprs
    var piExprs: FloExprs // plug-in

    init(_ myExprs: FloExprs,
         _ piExprs: FloExprs) {

        self.myExprs = myExprs
        self.piExprs = piExprs
    }
    func cancel() {
        NextFrame.shared.removeDelegate(myExprs.id)
        timeStart = 0
    }
}
extension FloPlugin: NextFrameDelegate {

    public func nextFrame() -> Bool {
        let interval = getInterval()
        setTween(interval)
        return interval < 1
    }
    private func setTween(_ interval: Double) {

        var hasDelta = false
        print(interval.digits(0...2), terminator: " ")
        for any in myExprs.nameAny.values {
            if let scalar = any as? FloValScalar {
                let delta = scalar.val - scalar.twe

                // myExprs.logValTwees("* interval: \(interval.digits(2))")
                if delta != 0 {
                    hasDelta = true
                    if abs(delta) < 1E-9 {
                        scalar.twe = scalar.val
                    } else {
                        scalar.twe += delta * interval
                    }
                }
            }
        }
        if hasDelta {
            myExprs.flo.activate(Visitor(myExprs.id, from: .tween))
        } else {
            cancel()
        }
    }
}

extension FloPlugin: FloPluginProtocal {

    func startPlugin(_ key: Int) {
        if duration > 0 {

            let timeNow = Date().timeIntervalSince1970
            let timeDelta = timeNow - timeStart

            if  timeDelta > duration {

                NextFrame.shared.addFrameDelegate(key, self)
                timeStart = timeNow

            } else {

                timeStart = timeNow - timeDelta / 2
            }
        }
    }

    func easeInOut(_ input: Double) -> Double {
        let t = min(max(input, 0), 1) // Clamp input between 0 and 1

        if t <= 0.5 {
            return 0.5 * pow(2 * t, 2)
        } else {
            let x = 2 * t - 1
            return 0.5 * (2 - pow(2, -10 * x))
        }
    }

    func getInterval() -> Double {
        let timeNow = Date().timeIntervalSince1970
        let timeDelta = timeNow - timeStart
        let interval = timeDelta / duration
        let easing = easeInOut(interval/duration) * duration
        return max(0.0, min(easing, duration))
    }

}
