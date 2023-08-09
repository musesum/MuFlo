//  Created by warren on 5/13/23.

import UIKit
import Collections
import MuVisit
import MuTime
import MuVisit

enum FloAnimType { case linear, easeinout }

public class FloPlugin {
    
    var flo: Flo
    
    var duration: TimeInterval = 2.0
    var type = FloAnimType.linear
    var plugExprs: FloExprs //  -in
    var blocked: Blocked?
    var distance = CGFloat.zero
    var interStart = CGFloat(0) // start of interval, may be >0 when interrupting animation
    var timeStart = TimeInterval(0)
    var timeNow = TimeInterval(0)
    var timeDelta: TimeInterval { timeNow - timeStart } // 0...duration
    var timeInter: TimeInterval { timeDelta / duration } // 0...1 normalized
    var floScalars = [FloValScalar]()
    let easyVals: EasyVals

    init(_ flo: Flo,
         _ plugExprs: FloExprs) {
        
        self.flo = flo
        self.plugExprs = plugExprs
        self.easyVals = EasyVals(duration)
        extractFloScalars()
        
        print("\(flo.path(9))(\(plugExprs.name)) +⃣ \(plugExprs.flo.path(9))")
    }
    
    func extractFloScalars() {
        if let values = flo.exprs?.nameAny.values {
            for value in values {
                if let scalar = value as? FloValScalar {
                    floScalars.append(scalar)
                }
            }
        }
    }
    
    func startPlugin(_ key: Int, _ visit: Visitor) {
        
        guard duration > 0 else { return }

        var vals = [Double]()
        var twes = [Double]()
        for i in 0 ..< floScalars.count {
            twes.append(floScalars[i].twe)
            vals.append(floScalars[i].val)
        }
        easyVals.add(from: twes, to: vals)
        NextFrame.shared.addFrameDelegate(key, self)
    }
    func setTween() -> Bool {
        
       flo.exprs?.logValTwees()

        timeNow = Date().timeIntervalSince1970
        var hasDelta = false
        let polyTweens = easyVals.getValNow(timeNow)
        for i in 0 ..< polyTweens.count {
            let floVal = floScalars[i]
            let polyTwe = polyTweens[i]

            floVal.twe = polyTwe
            hasDelta = hasDelta || abs( floVal.val - floVal.twe) > 1E-9
        }
        flo.activate(Visitor(plugExprs.id, from: .tween))
        if hasDelta {
            return true
        } else {
            cancel(flo.id)
            easyVals.finish()
            return false
        }
    }
}
extension FloPlugin: NextFrameDelegate {

    public func nextFrame() -> Bool {
        return setTween()
    }
    public func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
        blocked = nil
    }

}

