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
    var interFact   : Double { (durationSum - interNow) / durationNow }
    var interBumpNow: Double { interBump * interFact }

    // value
    var valFrom     : Double
    var valTo       : Double
    var valSpan     : Double { valTo - valFrom }
    var valNow      : Double { valBumpNow + valFrom + valSpan * interNorm }
    var valBump     : Double = 0
    var valBumpNow  : Double { valBump * interFact }

    var isDone = false

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
        interWarp = interBumpNow + interNorm * durationSum
        return interWarp
    }
    func warpNorm(interval: Double) -> Double {
        return warp(interval: interval) / durationSum
    }

    func addPoint(_ val: Double, time: TimeInterval, duration: Double? = nil) {
        timeNow = time
        interNow = timeNow - timeStart
        return addPoint(val, duration: duration)
    }
    func addPoint(_ val: Double, duration: Double? = nil) {

        isDone = false
        
        let oldWarp = warp(interval: interNow)
        let oldVal = valNow

        valTo = val
        if let duration {
            durationNow = duration
        }
        durationSum = interNow + durationNow

        let newWarp = warp(interval: interNow)
        let newVal = valNow

        interBump += oldWarp - newWarp
        valBump   += oldVal - newVal
    }
    func logInter(_ suffix: String = "" ) {
        print("now|warp|sum: (\(interNow.digits(2)) | \(interWarp.digits(2)) | \(durationSum.digits(2))) " +
              "(bump * fact): (\(interBump.digits(2)) * \(interFact.digits(2))) " +
              "norm: \(warpNorm(interval: interNow).digits(4)) " +
              "val: \(valNow.digits(3))" +
              suffix)
    }
    static func test() {

        var lastVal = Double(0)
        let easy = EaseInOut(duration: 2.0, from: 10, to: 20)

        var counter = 0
        let divisions = Double(100)
        var interNow: Double { Double(counter)/divisions }

        while interNow <= easy.durationSum {

            let interWarp = easy.warp(interval: interNow)
            let deltaVal = interWarp - lastVal
            lastVal = interWarp
            easy.logInter("∆ \(deltaVal.digits(3))")

            // some test points that shorten and lengthen total duration
            switch counter {
            case 100: addPoint( 30, duration: 0.5)
            case 150: addPoint(-40, duration: 0.5)
            case 180: addPoint( 50, duration: 1.0)
            case 340: addPoint(-60, duration: 2.0)
            case 520: addPoint( 70, duration: 0.5)
            default: break
            }
            counter += 1

            func addPoint(_ to: Double, duration: TimeInterval) {
                easy.addPoint(to , duration: duration)
                print("--- valTo: \(to.digits(2)) durationNow: \(duration) durationSum: \(easy.durationSum)")
            }

        }
    }
}

class EasyVals {

    var valsFrom  = [Double]()
    var valsNow   = [Double]()
    var valsTo    = [Double]()
    var easys     = [EaseInOut]()
    var duration  = TimeInterval(1)
    var timeStart = TimeInterval(0)
    var timeNow   = TimeInterval(0)
    var isDone    = false

    init(_ duration: Double) {
        self.duration = duration
    }
    func add(from: [Double], to: [Double]) {

        guard from.count == to.count else {
            return print("EasyVals::add from.count:\(from.count) != to.count:\(to.count)")
        }
        isDone = false

        if valsFrom.isEmpty {
            /// setup new  easys[EaseInOut]
            valsTo.removeAll()
            easys.removeAll()

            for i in 0 ..< from.count {

                let fromi = from[i]
                let toi = to[i]
                let easyi = EaseInOut(duration: duration, from: fromi, to: toi)

                valsFrom.append(fromi)
                valsTo.append(toi)
                easys.append(easyi)
            }
        } else {
            /// add to current easys[EaseInOut]
            valsTo.removeAll()

            for i in 0 ..< to.count {
                let toi = to[i]
                valsTo.append(toi)
                easys[i].addPoint(toi, duration: duration)

            }
        }
    }
    func getValNow(_ timeNow: TimeInterval) -> [Double] {
        self.timeNow = timeNow
        valsNow.removeAll()
        var doneCount = 0
        for easy in easys {
            let val = easy.getVal(now: timeNow)
            valsNow.append(val)
            doneCount += easy.isDone ? 1 : 0
        }
        return valsNow
    }

    func finish() {
        easys.removeAll()
        valsFrom.removeAll()
        valsTo.removeAll()
    }

}
