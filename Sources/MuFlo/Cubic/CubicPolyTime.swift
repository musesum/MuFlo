//  Created by warren on 7/24/23.

import Foundation
import simd
typealias Int4 = Val4<Int>


class CubicPolyVal {

    var duration: TimeInterval
    private var timeVals = [TimeVals]()
    var valCount = 0
    let degree = 4

    public init(_ duration: TimeInterval) {
        self.duration = duration
    }


    private let BSpline = matrix_double4x4(rows: [
        SIMD4<Double>( 1, 4, 1, 0) / 6,
        SIMD4<Double>(-3, 0, 3, 0) / 6,
        SIMD4<Double>( 3,-6, 3, 0) / 6,
        SIMD4<Double>(-1, 3,-3, 1) / 6])

    private let Catmull = matrix_double4x4(rows: [
        SIMD4<Double>( 0, 2, 0, 0) / 2,
        SIMD4<Double>(-1, 0, 1, 0) / 2,
        SIMD4<Double>( 2,-5, 4,-1) / 2,
        SIMD4<Double>(-1, 3,-3, 1) / 2])

    func addTweVals(_ twes: [Double],
                    _ vals: [Double]) {

        verifyValCount()
        let time = Date().timeIntervalSince1970

        switch timeVals.count {
            case 0:

            let delta = vals - twes

            let v0 = twes - delta
            let v1 = twes
            let v2 = vals + delta
            let v3 = v2

            let t0 = time - duration
            let t1 = time
            let t2 = time + duration
            let t3 = t2

            timeVals.append(contentsOf: [
                TimeVals(t0, v0),
                TimeVals(t1, v1),
                TimeVals(t2, v2),
                TimeVals(t3, v3)])

        case 4:

            timeVals.removeLast()
            timeVals.append(TimeVals(time+duration, vals))
        default:
            timeVals.append(TimeVals(time+duration, vals))
        }

        func verifyValCount() {
            if valCount == 0 {
                valCount = vals.count
            } else if vals.count != valCount {
                print("⁉️ CubicPolyVal: mismatched vals.count: \(vals.count) != valCount:  \(valCount)")
            }
        }
    }

    func timeSegmentStart(_ time: TimeInterval) -> Int {
        var segStart = 0
        for i in 0 ..< timeVals.count {
            if timeVals[i].time < time {
                segStart = i
            } else {
                break
            }
        }
        return segStart
    }

    func finish() {
        timeVals.removeAll()
        valCount = 0
    }

    func getTweenNow(_ time: TimeInterval) -> [Double] {

        let i = timeSegmentStart(time)
        let maxi = timeVals.count-1
        let ii = (i,
                  min(i+1, maxi),
                  min(i+2, maxi),
                  min(i+3, maxi))
        let t0 = timeVals[ii.0].time
        let t1 = timeVals[ii.3].time
        let t = t1 == t0 ? 1 : (time - t0) / (t1 - t0)
        logiit()

        let T = SIMD4<Double>(1, t, t*t, t*t*t)

        var result = [Double]()

        for j in 0 ..< valCount {

            let M = SIMD4<Double>(timeVals[ii.0].vals[j],
                                  timeVals[ii.1].vals[j],
                                  timeVals[ii.2].vals[j],
                                  timeVals[ii.3].vals[j])

            let sum = (BSpline * M * T).sum()
            logM(M, sum)

            result.append(sum)
        }
        print()

        return result

        func logiit() {

            let tz = timeVals[0].time
            let tDelta = time - tz
            let tseg = (timeVals[ii.0].time-tz,
                        timeVals[ii.1].time-tz,
                        timeVals[ii.2].time-tz,
                        timeVals[ii.3].time-tz)
            print("\(tDelta.digits(2))_\(t.digits(2)) \(ii),(\(tseg.0.digits(2)),\(tseg.1.digits(2)),\(tseg.2.digits(2)),\(tseg.3.digits(2))): ", terminator: "")

        }
        func logM(_ M: SIMD4<Double>,
                  _ sum: Double) {

            print("[\(M[0].digits(2)),\(M[1].digits(2)),\(M[2].digits(2)),\(M[3].digits(2))]: \(sum.digits(3))", terminator: " ")

        }
    }
}

