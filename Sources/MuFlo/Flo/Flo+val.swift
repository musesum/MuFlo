// Flo+val.swift

import QuartzCore
import Collections
import UIKit

extension Flo {
    
    func StringVal() -> String? {
        if let exprs,
           let str = exprs.evalAnys.first?.any as? String {
            // anonymous String inside expression
            // example `color ("kernel.color.metal")`
            return str
        }
        return nil
    }
    
    func BoolVal() -> Bool {
        if let exprs {
            for any in exprs.nameAny.values {
                if let scalar  = any as? Scalar {
                    return scalar.tween > 0
                }
            }
        }
        return false
    }
    func XyzVal() -> SIMD3<Float>? {
        var x: Float?
        var y: Float?
        var z: Float?
        if let exprs {
            for (name,any) in exprs.nameAny {
                if let scalar = any as? Scalar {
                    switch name {
                    case "x": x = Float(scalar.tween)
                    case "y": y = Float(scalar.tween)
                    case "z": z = Float(scalar.tween)
                    default: continue
                    }
                }
            }
            if let x, let y, let z {
                return SIMD3<Float>(x: x, y: y, z: z)
            }
        }
        return nil
    }

    func ScalarVal() -> Scalar? {
        if let exprs {
            for any in exprs.nameAny.values {
                if any is Scalar {
                    return any as? Scalar
                }
            }
        }
        return nil
    }

    func DoubleVal() -> Double? {
        return ScalarVal()?.tween ?? nil
    }
    func IntVal() -> Int? {
        if let v = DoubleVal() { return Int(v) }
        return nil
    }
    func UInt32Val() -> UInt32? {
        if let v = DoubleVal() { return UInt32(v) }
        return nil
    }
    func CGFloatVal() -> CGFloat? {
        if let v = DoubleVal() { return CGFloat(v) }
        return nil
    }
    
    func FloatVal() -> Float? {
        if let v = DoubleVal() { return Float(v) }
        return nil
    }
    
    func CGPointVal() -> CGPoint? {
        
        if let exprs {
            if let x = (exprs.nameAny["x"] as? Scalar)?.tween,
               let y = (exprs.nameAny["y"] as? Scalar)?.tween {
                
                return CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
        return nil
    }
    
    func CGSizeVal() -> CGSize? {
        if let exprs {
            if let w = (exprs.nameAny["w"] as? Scalar)?.tween,
               let h = (exprs.nameAny["h"] as? Scalar)?.tween {
                
                return CGSize(width: CGFloat(w), height: CGFloat(h))
            }
        }
        return nil
    }
    
    func CGRectVal() -> CGRect? {
        if let exprs {
            let ns = exprs.nameAny
            if ns.count >= 4,
               let x = (ns["x"] as? Scalar)?.tween,
               let y = (ns["y"] as? Scalar)?.tween,
               let w = (ns["w"] as? Scalar)?.tween,
               let h = (ns["h"] as? Scalar)?.tween {
                let rect = CGRect(x: CGFloat(x),
                                  y: CGFloat(y),
                                  width: CGFloat(w),
                                  height: CGFloat(h))
                return rect
            }
        }
        return nil
    }
    
    func NamesVal() -> [String]? {
        if let exprs,
           exprs.nameAny.count > 0 {
            return Array<String>(exprs.nameAny.keys)
        }
        return nil
    }
    /// get first occurence name in Set of types (there should only be one)
    public func getName(in types: Set<String>) -> String? {
        if let exprs {
            for evalAny in exprs.evalAnys {
                if [.path,.name].contains(evalAny.op),
                   let name = evalAny.any as? String,
                   types.contains(name) {
                    return name
                }
            }
        }
        return nil
    }
    /// contains all the keyword names in `names`
    public func contains(names: [String]) -> Bool {
        func inNames(_ exprName: String) -> Bool {
            for name in names {
                if name == exprName {
                    return true
                }
            }
            return false
        }
        if let exprs {
            var matchCount = 0
            for evalAny in exprs.evalAnys {
                if [.path,.name].contains(evalAny.op),
                   let name = evalAny.any as? String,
                   inNames(name) {
                    matchCount += 1
                }
            }
            if matchCount >= names.count {
                return true
            }
        }
        return false
    }
    
    /// get nameed value
    public func component(named: String) -> Any? {
        return exprs?.nameAny[named] ?? nil
    }

    /// convert Express contiguous array to dictionary
    public func nameScalars() -> [(String, Scalar)] {
        var result = [(String, Scalar)] ()
        if let exprs {
            for (name,any) in exprs.nameAny {
                if let scalar = any as? Scalar {
                    result.append((name,scalar))
                }
            }
        }
        return result
    }
    /// convert Express contiguous array to dictionary
    public func scalars() -> [Scalar] {
        var result = [Scalar] ()
        if let exprs {
            for any in exprs.nameAny.values {
                if let scalar = any as? Scalar {
                    result.append(scalar)
                }
            }
        }
        return result
    }
    
    /// convert Express contiguous array to dictionary
    public func components(named: [String]) -> [(String,Any?)] {
        var result = [(String, Any?)] ()
        for name in named {
            let val = exprs?.nameAny[name] ?? nil
            result.append((name,val))
        }
        return result
    }
    
    /// convert Express contiguous array to dictionary
    public func components() ->  OrderedDictionaryClass<String,Any>? {
        return exprs?.nameAny ?? nil
    }

    public func getRanges(named: [String]) -> [(String,ClosedRange<Double>)] {
        var ranges = [(String,ClosedRange<Double>)]()
        for name in named {
            let range = getRange(named: name)
            ranges.append((name,range))
        }
        return ranges
    }
    public func getRange(named: String) ->  ClosedRange<Double> {
        if let comp = component(named: named),
           let scalar = comp as? Scalar {
            return scalar.range()
        }
        return getFirstRange()
    }
    public func getFirstRange() -> ClosedRange<Double> {
        if let exprs {
            for value in exprs.nameAny.values {
                if let scalar = value as? Scalar {
                    return scalar.range()
                }
            }
        }
        return 0...1
    }
}
