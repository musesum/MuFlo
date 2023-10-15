// created by musesum on 8/10/23.

import Foundation

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
