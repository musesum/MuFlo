import Foundation

/// Ease In Out with smooth interuption of new points
///
///     // duration
///     durationNow  : duration of current segment
///     durationSum  : duration of all segments
///
///     // interval
///     interNow     : current interval in seconds
///     interNorm    : normalized from 0...1
///     interWarp    : warp ease in out
///     interBump    : delta of interWarp when adding new point
///     interFact    : factor of interBump goes to 0 towards end
///     interBumpNow : current delta to add to interWarp
///
///     // value
///     valFrom     : starting value
///     valTo       : ending value
///     valSpan     : length of value
///     valNow      : current value between from...to
///     valBump     : delta of valNow when adding new point
///     valBumpNow  : current delta to add to valNow goes to 0
///
/// - note: Interrupting an ease-in-out with a new point adds a jump.
/// To compensate, add a bump, which is the difference of both
/// interWarp and valNow before and after adding a new point. The bump
/// gets smaller as the series heads towards the end.
///
class EaseInOut {

    var timeStart   : Double
    var timeNow     : Double

    // duration
    var durationNow : Double
    var durationSum : Double

    // intervals
    var interNow    : Double = 0
    var interNorm   : Double = 0
    var interWarp   : Double = 0
    var interBump   : Double = 0
    var bumpFactor  : Double { pow(abs(durationSum - interNow) / durationNow, 1.4) }
    var bumpNow     : Double { interBump * bumpFactor }

    // value
    var valFrom     : Double
    var valTo       : Double
    var valSpan     : Double { valTo - valFrom }
    var valNow      : Double { valBumpNow + valFrom + valSpan * interNorm }
    var valBump     : Double = 0
    var valBumpNow  : Double { valBump * bumpFactor }

    var isDone = false
    private var lock = NSLock()

    init(duration: Double,
         from: Double,
         to: Double) {

        let time = Date().timeIntervalSince1970
        self.timeStart = time
        self.timeNow = time
        self.durationNow = duration
        self.durationSum = duration
        self.valFrom = from
        self.valTo = to
        self.isDone = false
    }

    func getVal(now: TimeInterval) -> Double {
        if isDone {
            finish()
            return valTo
        }
        timeNow = now
        
        _ = warp(interval: timeNow - timeStart)
        let warpDelta = abs(1 - warpNorm(interval: interNow))
        isDone = (warpDelta < 1e-6) || interNow >= durationSum

        logInter()
        return valNow
    }
    func warp(interval: Double) -> Double {
        let timeNorm = interval / durationSum
        self.interNow = interval
        interNorm = 3 * pow(timeNorm, 2) - 2 * pow(timeNorm, 3)
        interWarp = bumpNow + interNorm * durationSum
        return interWarp
    }
    func warpNorm(interval: Double) -> Double {
        let norm = warp(interval: interval) / durationSum
        if norm < 0 || norm > 1 {
            //PrintLog("⁉️ err: EaseInOut::warpNorm(interval: \(interval.digits(2))) =>  norm: \(norm)")
            return 1
        }
        return norm
    }

    func addPoint(_ val: Double, duration: Double) {
        isDone = false
        
        let oldWarp = warp(interval: interNow)
        let oldVal = valNow

        valTo = val

        durationNow = duration
        durationSum = interNow + durationNow

        let newWarp = warp(interval: interNow)
        let newVal = valNow

        interBump += oldWarp - newWarp
        valBump   += oldVal - newVal
    }
    
    func logInter(_ suffix: String = "" ) {
        #if false
        PrintLog("now|warp|sum: (\(interNow.digits(2)) | \(interWarp.digits(2)) | \(durationSum.digits(2))) " +
              "(bump * fact): (\(interBump.digits(2)) * \(bumpFactor.digits(2))) " +
              "norm: \(warpNorm(interval: interNow).digits(4)) " +
              "val: \(valNow.digits(3))" +
              suffix)
        #endif
    }
    func finish() {
        interNow = 0
        interNorm = 0
        interWarp = 0
        interBump = 0
    }

}
