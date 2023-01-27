//  Created by warren on 3/25/21.

import Foundation

extension Formatter {
    static let number = NumberFormatter()
}
public extension FloatingPoint {
    func digits(_ range: ClosedRange<Int>) -> String {
        Formatter.number.roundingMode = NumberFormatter.RoundingMode.halfEven
        Formatter.number.minimumFractionDigits = range.lowerBound
        Formatter.number.maximumFractionDigits = range.upperBound
        return Formatter.number.string(for:  self) ?? ""
    }
}


extension String {

    /// transform `"CamelBackName"` => `"camel back name"`
    /// - note: https://stackoverflow.com/a/50202999/419740
    func titleCase() -> String {
        return self
            .replacingOccurrences(of: "([A-Z])",
                                  with: " $1",
                                  options: .regularExpression,
                                  range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// transform `" one  two   three  "` => `"one two three"`
    public func removeLines() -> String {
        var result = ""
        var prevChar = Character("\0")
        for char in self {
            if char == " ", prevChar == " " { continue }
            if char.isNewline {
                if prevChar == " " { continue }
                result.append(" ")
                prevChar = " "
                continue
            } else {
                result.append(char)
                prevChar = char
            }
        }
        if result.last == " " {
            result.removeLast()
        }
        return result
    }
    /// transform `"one\n\n two\n \n three   "` => `"one\n two\n three   "`
    public func reduceLines() -> String {
        var result = ""
        var prevChar = Character("\n")
        for char in self {
            if prevChar.isNewline, char.isNewline {
                continue
            } else if char == " " {
                result.append(char)
            } else {
                prevChar = char
                result.append(char)
            }
        }
        return result
    }

}
