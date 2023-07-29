//  Created by warren on 5/13/23.

import UIKit
import MuVisit
import MuTime
import Collections

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
    var polyVals = [CubicPolyVal]()
    var interNow: TimeInterval {
        
        let interSpan = 1 - interStart
        let inter = interStart + timeInter * interSpan
        let area = gaussianCDF(inter)
        print("*** timeInter: \(timeInter.digits(2)) interStart: \(interStart.digits(2))  interSpan: \(interSpan.digits(2)) inter: \(inter.digits(2)) => area: \(area.digits(2)) ")
        return inter
    }
    
    init(_ flo: Flo,
         _ plugExprs: FloExprs) {
        
        self.flo = flo
        self.plugExprs = plugExprs
        extractFloScalars()
        
        print("\(flo.path(9))(\(plugExprs.name)) +⃣ \(plugExprs.flo.path(9))")
    }
    
    func extractFloScalars() {
        if let values = flo.exprs?.nameAny.values {
            for value in values {
                if let scalar = value as? FloValScalar {
                    floScalars.append(scalar)
                    polyVals.append(CubicPolyVal(duration))
                }
            }
        }
    }
    
    func startPlugin(_ key: Int, _ visit: Visitor) {
        
        guard duration > 0 else { return }
        
        // let interPrev = interNow
        timeNow = Date().timeIntervalSince1970
        for i in 0 ..< floScalars.count {
            let floVal = floScalars[i]
            let polyVal = polyVals[i]
            polyVal.addTimeVal((timeNow,floVal.val))
        }
        NextFrame.shared.addFrameDelegate(key, self)
    }
    func setTween() -> Bool {
        
        flo.exprs?.logValTwees()
        
        timeNow = Date().timeIntervalSince1970
        var hasDelta = false
        
        for i in 0 ..< floScalars.count {
            let floVal = floScalars[i]
            let polyVal = polyVals[i]
            if let val = polyVal.getTweenNow(timeNow) {
                floVal.twe = val
                hasDelta = hasDelta || abs( floVal.val - val) > 1E-9
            }
        }
        flo.activate(Visitor(plugExprs.id, from: .tween))
        if hasDelta {
            return true
        } else {
            cancel(flo.id)
            for polyVal in polyVals {
                polyVal.finish()
            }
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

