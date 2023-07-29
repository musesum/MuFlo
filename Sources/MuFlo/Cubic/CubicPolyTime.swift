//  Created by warren on 7/24/23.

import Foundation

typealias TimeVal = (TimeInterval,Double)
typealias Int4 = Val4<Int>

class CubicPolyVal {

    var duration: TimeInterval
    var timeVals = [TimeVal]()
    //var polyTime = CubicPoly<TimeInterval>()
    var polyVal  = CubicPoly<Double>()
    var startIndex = 0
    var timeNow = TimeInterval(0)
    var timeStart = TimeInterval(0)
    var timeDelta = TimeInterval(0)
    var valNow = Double(0)

    public init(_ duration: TimeInterval) {
        self.duration = duration
    }

    func addTimeVal(_ timeVal: TimeVal) {
        timeVals.append(timeVal)
    }
    func finish() {
        timeVals.removeAll()
        timeNow = 0
        timeStart = 0
        valNow = 0
        startIndex = 0
    }

    func getTweenNow(_ time: TimeInterval) -> Double? {

        timeNow = time

        switch timeVals.count {
        case 0 : print("A⃣",terminator:" "); return nil
        case 1 : print("B⃣",terminator:" "); return interval((0,0,0,0))
        case 2 : print("C⃣",terminator:" "); return interval((0,0,1,1))
        case 3 : print("D⃣",terminator:" "); return interval((0,1,2,2))
        case 4 : print("E⃣",terminator:" "); return interval((0,1,2,3))
        default: print("F⃣",terminator:" ")
            let i = advanceSpline()
            startIndex = i
            switch timeVals.count - i {
            case 1 : print("1⃝",terminator:" "); return interval((i+0,i+0,i+0,i+0))
            case 2 : print("2⃝",terminator:" "); return interval((i+0,i+1,i+1,i+1))
            case 3 : print("3⃝",terminator:" "); return interval((i+0,i+1,i+2,i+2))
            default: print("n⃝",terminator:" "); return interval((i+0,i+1,i+2,i+3))
            }

        }
        // advance to spline to interval that spans duration
        func advanceSpline() -> Int {
            let timeCut = timeNow - duration
            var i = startIndex

            while i < timeVals.count - 1,
                  timeVals [i+1].0 < timeCut {
                i += 1
            }
            return i
        }

        func interval(_ indices: Int4) -> Double {

            startIndex = indices.0
            timeStart = timeVals[startIndex].0
            timeDelta = max(0, min(timeNow - timeStart, duration))
            let timeNorm = max(0, min(timeDelta / duration, 1))

            // later warp time for easeInOut
            // polyVal.setVals(timeVals[indices.0].0,
            //                 timeVals[indices.1].0,
            //                 timeVals[indices.2].0,
            //                 timeVals[indices.3].0)

            polyVal.setVals((timeVals[indices.0].1,
                             timeVals[indices.1].1,
                             timeVals[indices.2].1,
                             timeVals[indices.3].1))

            let valNow = polyVal.getInter(timeNorm)
            log(valNow)
            return valNow
        }
        func log(_ valNow: Double) {

            print("i:\(startIndex) ∆t:\(timeDelta.digits(2)) val:\(valNow.digits(3))", terminator: "  ")
        }
    }

}
