//
//  GauseTimeVal.swift
//  DeepMuse
//
//  Created by warren on 8/1/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation

//class GaussTimeVal {
//
//    var duration: TimeInterval
//    var durationSum = TimeInterval(0)
//
//    var valsStart = [Double]()
//    var valsEnd = [Double]()
//
//    private var timeVals = [TimeVals]()
//    var valCount = 0
//    var timeStart = TimeInterval(0) // start time
//    var timePrev = TimeInterval(0)
//    var timeNow  = TimeInterval(0) // next point
//    var timeEnd  = TimeInterval(0) // timeNext + duration
//    var timeEase = TimeInterval(0) // ease-in-out 0...1
//
//    public init(_ duration: TimeInterval) {
//        self.duration = duration
//        self.durationSum = duration
//    }
//
//    func addVals(start : [Double],
//                 end   : [Double]) {
//
//        verifyValCount()
//
//        timeNow = Date().timeIntervalSince1970
//
//        if timeStart == 0 {
//
//            timeStart = timeNow
//            timePrev = timeNow
//            timeEnd = timeNow + duration
//            durationSum = duration
//
//            valsStart = twes
//            valsEnd = vals
//
//        } else {
//            let durationOld = durationSum
//            durationSum = timeNow - timeStart + duration
//            let timeNorm = (timeNow - timeStart) / durationSum
//            timeEase = findIntervalForArea(timeNorm)
//
//            valsEnd = vals
//        }
//
//
//        func verifyValCount() {
//            if valCount == 0 {
//                valCount = vals.count
//            } else if vals.count != valCount {
//                print("⁉️ CubicPolyVal: mismatched vals.count: \(vals.count) != valCount:  \(valCount)")
//            }
//        }
//    }
//
//
//    func finish() {
//        timeVals.removeAll()
//        valCount = 0
//    }
//
//    func getTweenNow(_ time: TimeInterval) -> [Double] {
//
//        let distance = twes ∆ vals
//
//    }
//}
