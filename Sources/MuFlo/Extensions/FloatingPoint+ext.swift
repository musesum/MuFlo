//  Platonic+defs.swift
//  created by musesum on 2/16/23.


import Foundation

public extension Formatter {
    static let number = NumberFormatter()
}
public extension FloatingPoint {

    func digits(_ range: ClosedRange<Int>) -> String {
        let lowerBound: Int
        let hasMinus: Bool
        if range.lowerBound < 0 {
            lowerBound = -range.lowerBound
            hasMinus = true
        } else {
            lowerBound = range.lowerBound
            hasMinus = false
        }
        Formatter.number.roundingMode = NumberFormatter.RoundingMode.halfEven
        Formatter.number.minimumFractionDigits = lowerBound
        Formatter.number.maximumFractionDigits = range.upperBound
        Formatter.number.usesGroupingSeparator = false
        let number = Formatter.number.string(for:  self) ?? ""
        let placeholder = hasMinus && self >= 0 ? " " : ""
        return placeholder + number
    }

    func digits(_ range: Int) -> String {

        if range == 0 {
            Formatter.number.maximumFractionDigits = 0
            Formatter.number.numberStyle = .decimal
            Formatter.number.roundingMode = .down  // Ensure truncation
            Formatter.number.usesGroupingSeparator = false
            let str = Formatter.number.string(for: self) ?? ""
            return str
        }
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
        Formatter.number.usesGroupingSeparator = false
        let str = Formatter.number.string(for:  self) ?? ""
        return minus && self < 0 ? str : " " + str
    }
}

