//  created by musesum on 5/13/23.

import UIKit
import Collections

enum EdgeAnimType { case linear, easeinout }

public class EdgePlugin {
    
    var flo: Flo
    
    var duration: TimeInterval = 2.0
    var animType = EdgeAnimType.linear
    var plugExpress: Exprs //  -in
    var blocked: Blocked?
    var distance = CGFloat.zero
    var interStart = CGFloat(0) // start of interval, may be >0 when interrupting animation
    var timeStart = TimeInterval(0)
    var timeNow = TimeInterval(0)
    var timeDelta: TimeInterval { timeNow - timeStart } // 0...duration
    var timeInter: TimeInterval { timeDelta / duration } // 0...1 normalized
    var floScalars = [Scalar]()
    let easyVals: EasyVals

    init(_ flo: Flo,
         _ plugExprs: Exprs) {
        
        self.flo = flo
        self.plugExpress = plugExprs
        self.easyVals = EasyVals(duration)
        extractFloScalars()
        //print("\(flo.path(9))(\(plugExprs.name)) +⃣ \(plugExprs.flo.path(9))")
    }
    
    func extractFloScalars() {
        if let values = flo.exprs?.nameAny.values {
            for value in values {
                if let scalar = value as? Scalar {
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
            twes.append(floScalars[i].tween)
            vals.append(floScalars[i].value)
        }
        easyVals.add(from: twes, to: vals)
        NextFrame.shared.addFrameDelegate(key, self)
    }

    /// Tween is intermediate value for animation plug-in
    func setTween() -> Bool {
       // flo.exprs?.logValTweens()
        timeNow = Date().timeIntervalSince1970
        var hasDelta = false
        let polyTweens = easyVals.getValNow(timeNow)
        for i in 0 ..< polyTweens.count  {
            if i < floScalars.count  {
                let floVal = floScalars[i]
                floVal.tween = polyTweens[i]
                hasDelta = hasDelta || abs(floVal.value - floVal.tween) > 1E-9
            }
        }
        flo.activate(Visitor(plugExpress.id, .tween))
        if hasDelta {
            return true
        } else {
            cancel(flo.id)
            easyVals.finish()
            return false
        }
    }
}
extension EdgePlugin: NextFrameDelegate {

    public func nextFrame() -> Bool {
        return setTween()
    }
    public func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
        blocked = nil
    }

}

