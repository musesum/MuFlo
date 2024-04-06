// created by musesum on 10/16/21.


import Foundation

public extension String {

     subscript(idx: Int) -> String {
        String(self[index(startIndex, offsetBy: idx)])
    }
    subscript(range: ClosedRange<Int>) -> String {
        let startIndex = index(startIndex, offsetBy: range.lowerBound)
        let endIndex = index(startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
    static func pointer(_ object: AnyObject?) -> String {
        guard let object = object else { return "nil" }
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
        return String(describing: opaque)
    }


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
        if self.hasSuffix("= ") { return ""  }
        if self.hasSuffix("=")  { return " " }
        else                    { return " = "}
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
    func removeLines() -> String {

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
    func reduceLines() -> String {

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

    func superScript(_ num: Int) -> String {
        var s = ""
        let numStr = String(num)
        for n in numStr.utf8 {
            let i = Int(n) - 48 // utf8 for '0'
            s += "⁰¹²³⁴⁵⁶⁷⁸⁹"[i]
        }
        return self+s
    }

    func substring(from: Int) -> String {
        return self[min(from, count) ..< count]
    }

    func substring(from: Int, to: Int) -> String {
        return self[min(from, count) ..< min(to, count)]
    }

    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
    }

    subscript (r: Range<Int>) -> String {

        let range = Range(uncheckedBounds: (lower: max(0, min(count, r.lowerBound)),
                                            upper: min(count, max(0, r.upperBound))))
        let s = index(startIndex, offsetBy: range.lowerBound)
        let e = index(s, offsetBy: range.upperBound - range.lowerBound)
        return String(self[s..<e])
    }
    /// split "a~b" into "a","~","b"
    ///
    func splitWild(_ wild: String) -> (String, String, String) {

        var prefix    = "" // a in a~b
        var wildcard  = "" // ~ in a~b
        var suffix    = "" // b in a~b

        // get non wildcard chars for prefix
        var i = 0
        while i < count, !wild.contains(self[i]) { i += 1 }
        if i > 0 {  prefix = self[0 ..< i] }

        // get wildcard chars for wildcard
        var j = i
        while j < count, wild.contains(self[j]) { j += 1 }
        if j > i { wildcard = self[i ..< j] }

        // get remaining chars for extra
        if count > j { suffix = self[j ..< count] }

        return (prefix, wildcard, suffix)
    }

    func matches(pre prefix: String, suf suffix: String) -> Bool {

        return hasPrefix(prefix) && hasSuffix(suffix)
    }

    /// add a space if last character is not a space of left paren
    func parenSpace(delim: String = "") -> String {
    
        if last == "(" { return "" }
        if last == " " { return "" }
        else           { return delim + " "}
    }

    /// append string to self with spacing
    mutating func spacePlus(_ str: String?) {
        
        guard let str else { return }
        if str == "" { return }
        if      str  == "," { self = without(trailing: " ") + str }
        else if last == "(" { self += str }
        else if last == " " { self += str }
        else                { self = isEmpty ? str : with(trailing: " ") + str }
    }

    /// remove trailing spaces before adding character.
    /// often used to insure a single trailing space, instead of two.
    func with(trailing: String) -> String {
    
        var trim = self
        while trim.last == " " { trim.removeLast() }
        return trim + trailing
    }

    /// remove trailing spaces
    /// often used to insure a single trailing space, instead of two.
    func without(trailing: String) -> String {
    
        var trim = self
        while let last = trim.last, trailing.contains(last) { trim.removeLast() }
        return trim
    }

    static func * (lhs: String, rhs: Int) -> String {

        var str = ""
        for _ in 0 ..< rhs {
            str += lhs
        }
        return str
    }

    func strHash() -> Int {
  
        var result = Int (5381)
        let buf = [UInt8](self.utf8)
        for b in buf {
            result = 127 * (result & 0x00ffffffffffffff) + Int(b)
        }
        return result
    }

    // Divider to separate listings
    func divider(_ length: Int = 30) -> String {
    
        return self + "\n" + "─".padding(toLength: 30, withPad: "─", startingAt: 0) + "\n"
    }

}
