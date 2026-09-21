//  created by musesum on 5/13/23.

#if !os(watchOS)
import UIKit
import Collections

enum EdgeAnimType { case linear, easeinout }

public class EdgePlugin {
    var flo: Flo
    /// seconds, read per arm from the plug node's first scalar (`sky.main.anim.x`); 0 = instant
    var duration: TimeInterval {
        for any in plugExpress.nameAny.values {
            if let scalar = any as? Scalar { return scalar.value }
        }
        return 2.0
    }
    var animType = EdgeAnimType.linear
    var plugExpress: Exprs //  -in
    var distance = CGFloat.zero
    var interStart = CGFloat(0) // start of interval, may be >0 when interrupting animation
    var timeStart = TimeInterval(0)
    var timeNow = TimeInterval(0)
    var timeDelta: TimeInterval { timeNow - timeStart } // 0...duration
    var timeInter: TimeInterval { timeDelta / duration } // 0...1 normalized
    var floScalars = [Scalar]()
    let tweenVals: TweenVals

    init(_ flo: Flo,
         _ plugExprs: Exprs,
         _ mapExprs: Exprs? = nil) {
        
        self.flo = flo
        self.plugExpress = plugExprs
        self.tweenVals = TweenVals(0) // startPlugin refreshes duration on every arm
        extractFloScalars(mapExprs)
        //PrintLog("\(flo.path(9))(\(plugExprs.name)) +⃣ \(plugExprs.flo.path(9))")
    }
    
    /// tween only continuous scalars; a `m_n` rangei scalar is discrete.
    /// `^- anim(z: x)` names the host scalars to capture; bare `^- anim` captures all
    func extractFloScalars(_ mapExprs: Exprs?) {
        guard let nameAny = flo.exprs?.nameAny else { return }
        let named = mapExprs?.nameAny.keys
        for (name, value) in nameAny {
            guard let scalar = value as? Scalar,
                  !scalar.scalarOps.rangei,
                  named?.contains(name) ?? true else { continue }
            scalar.plugged = true
            floScalars.append(scalar)
        }
        for name in named ?? [] where !floScalars.contains(where: { $0.name == name }) {
            PrintLog("⁉️ \(flo.path(9)) ^- \(plugExpress.flo.path(9))(\(name):) not a continuous scalar, ignored")
        }
    }
    
    func startPlugin(_ key: Int, _ visit: Visitor) {
        
        let duration = self.duration
        /// a plugged scalar defers tween to its plugin, so zero must snap, not bail
        guard duration > 0 else { return snapTweens() }
        tweenVals.duration = duration

        var vals = [Double]()
        var twes = [Double]()
        for i in 0 ..< floScalars.count {
            twes.append(floScalars[i].tween)
            vals.append(floScalars[i].value)
        }
        tweenVals.add(from: twes, to: vals)
        NextFrame.shared.addFrameDelegate(key, self)
    }

    func snapTweens() {
        for scalar in floScalars {
            scalar.tween = scalar.value
        }
        cancel(flo.id)
        tweenVals.finish()
    }

    /// Tween is intermediate value for animation plug-in
    func setTween(_ setOps: SetOps) -> Bool {
       // flo.exprs?.logValTweens()
        timeNow = Date().timeIntervalSince1970
        var hasDelta = false
        let polyTweens = tweenVals.getValNow(timeNow)
        guard polyTweens.count > 0 else { return false }
        for i in 0 ..< polyTweens.count  {
            if i < floScalars.count  {
                let floVal = floScalars[i]
                floVal.tween = polyTweens[i]
                hasDelta = hasDelta || abs(floVal.value - floVal.tween) > 1E-9
            }
        }
        flo.activate(setOps, Visitor(plugExpress.id, .tween))
        if hasDelta {
            return true
        } else {
            cancel(flo.id)
            tweenVals.finish()
            return false
        }
    }
}
extension EdgePlugin: NextFrameDelegate {

    public func goFrame() -> Bool {
        return setTween([])
    }
    /// on the calling thread: a detached removal could land after the next
    /// arm and delete a delegate that had just been re-registered
    public func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }

}
#endif

