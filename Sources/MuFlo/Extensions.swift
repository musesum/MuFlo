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
    func digits(_ num: Int) -> String {
        return digits(num...num)
    }
}


extension String {

    func pad(_ len: Int) -> String {
        let ofs = len < 0 ? max(0, count+len) : 0
        let last = min(ofs + abs(len), count)
        let start = index(startIndex,offsetBy: ofs)
        let until = index(startIndex,offsetBy: last)
        let range = start..<until

        let str =  String(self[range])
        if abs(len) <= count {
            return str
        }
        let padLen = abs(len) - count
        let padStr = " ".padding(toLength: padLen, withPad: " ", startingAt: 0)
        return len > 0 ? str + padStr : padStr + str
    }

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

    func roundColonSpace() -> String {
        if self.hasSuffix(": ") { return ""  }
        if self.hasSuffix(":")  { return " " }
        else                    { return ": "}
    }
    func singleSuffix(_ suf: String) -> String {
        if hasSuffix(suf) { return self }
        var dropCount = 0
        for char in self.reversed() {
            if suf.contains(char) {
                dropCount += 1
            } else {
               break
            }
        }
        return String(dropLast(dropCount)) + suf
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
