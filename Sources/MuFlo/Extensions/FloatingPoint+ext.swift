//  Platonic+defs.swift
//  created by musesum on 2/16/23.


import Foundation

public extension Formatter {
    static let number = NumberFormatter()
}
public extension FloatingPoint {

    func digits(_ range: ClosedRange<Int>) -> String {
        let lower: Int
        let minus: Bool
        if range.lowerBound < 0 {
            lower = -range.lowerBound
            minus = true
        } else {
            lower = range.lowerBound
            minus = false
        }
        Formatter.number.roundingMode = NumberFormatter.RoundingMode.halfEven
        Formatter.number.minimumFractionDigits = lower
        Formatter.number.maximumFractionDigits = range.upperBound
        let str = Formatter.number.string(for:  self) ?? ""
        return minus && self < 0 ? str : " " + str
    }

    func digits(_ range: Int) -> String {

        let lower: Int
        let minus: Bool
        if range < 0 {
            lower = -range
            minus = true
        } else {
            lower = range
            minus = false
        }
        Formatter.number.roundingMode = NumberFormatter.RoundingMode.halfEven
        Formatter.number.minimumFractionDigits = lower
        Formatter.number.maximumFractionDigits = lower
        let str = Formatter.number.string(for:  self) ?? ""
        return minus && self < 0 ? str : " " + str
    }
}

