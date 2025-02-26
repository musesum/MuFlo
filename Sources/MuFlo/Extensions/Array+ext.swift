//  created by musesum on 12/20/22.


import Foundation

public extension Array where Element == Double {

    static func - (lhs: [Double], rhs: [Double]) -> [Double] {
        var result = [Double]()
        for index in 0 ..< lhs.count {
            let left = lhs[index]
            let right = index < rhs.count ? rhs[index] : 0
            result.append(left - right)
        }
        return result
    }

    static func + (lhs: [Double], rhs: [Double]) -> [Double] {
        var result = [Double]()
        for index in 0 ..< lhs.count {
            let left = lhs[index]
            let right = index < rhs.count ? rhs[index] : 0
            result.append(left + right)
        }
        return result
    }
    
    static func * (lhs: [Double], rhs: [Double]) -> [Double] {
        var result = [Double]()
        for  index in 0 ..< lhs.count {
            let left = lhs[index]
            let right = index < rhs.count ? rhs[index] : 0
            result.append(left * right)
        }
        return result
    }
    
    static func * (lhs: [Double], rhs: Double) -> [Double] {
        var result = [Double]()
        for  left in lhs {
            result.append(left * rhs)
        }
        return result
    }

    func distance(_ from: [Double]) -> Double {
        let result = sqrt( (self[0]-from[0]) * (self[0]-from[0]) +
                           (self[1]-from[1]) * (self[1]-from[1]) )
        return result
    }
}
public extension Array where Element: Numeric, Element: ExpressibleByIntegerLiteral {

    static func + (lhs: Array, rhs: Array) -> Array {
        guard lhs.count == rhs.count else {
            fatalError("Arrays must have the same size to be added")
        }

        var result = Array()
        for i in 0..<lhs.count {
            result.append(lhs[i] + rhs[i])
        }
        return result
    }
    
    static func - (lhs: Array, rhs: Array) -> Array {
        guard lhs.count == rhs.count else {
            fatalError("Arrays must have the same size to be added")
        }

        var result = Array()
        for i in 0..<lhs.count {
            result.append(lhs[i] - rhs[i])
        }
        return result
    }
}
public extension Array where Element: FloatingPoint {

    static func / (lhs: Array, rhs: Element) -> Array {
        return lhs.map { $0 / rhs }
    }
    
    static func * (lhs: Array, rhs: Element) -> Array {
        return lhs.map { $0 * rhs }
    }
}


public extension Array where Element == UInt8 {

    var data: Data {
        return Data(self)
    }
}
public extension Array where Element == UInt8 {

    func toAsciiString() -> String? {
        String(bytes: self, encoding: .ascii)
    }
}

public extension Array where Element == UInt8 {

    func toString() -> String? {
        String(bytes: self, encoding: .utf8)
    }
}



