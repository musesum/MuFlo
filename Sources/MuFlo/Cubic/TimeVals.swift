//  TimeVals.swift
//  created by musesum on 8/1/23.

import Foundation
class TimeVals {

    let time: TimeInterval
    var vals: [Double] // 1,2,3D
    init(_ time: TimeInterval, _ vals: [Double]) {
        self.time = time
        self.vals = vals
    }
    func add(_ val: Double) {
        vals.append(val)
    }
}
