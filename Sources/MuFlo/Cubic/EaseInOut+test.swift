//  created by musesum on 8/10/23.

import Foundation

extension EaseInOut  {
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
