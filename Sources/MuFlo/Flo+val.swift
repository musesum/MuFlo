// Flo+val.swift
//
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import MuPar

extension Flo {
    
    func StringVal() -> String? {
        if let exprs,
           let str = exprs.opAnys.first?.any as? String {
            // anonymous String inside expression
            // example `color ("compute.color.metal")`
            return str
        }
        return nil
    }
    
    func BoolVal() -> Bool {
        if let exprs {
            for any in exprs.nameAny.values {
                if let scalar  = any as? FloValScalar {
                    return scalar.val > 0
                }
            }
        }
        return false
    }
    
    func DoubleVal() -> Double? {
        if let exprs {
            for any in exprs.nameAny.values {
                if let scalar  = any as? FloValScalar {
                    return scalar.twe  //??? or .val
                }
            }
        }
        return nil
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
            if let x = (exprs.nameAny["x"] as? FloValScalar)?.twe,
               let y = (exprs.nameAny["y"] as? FloValScalar)?.twe {
                
                return CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
        return nil
    }
    
    func CGSizeVal() -> CGSize? {
        if let exprs {
            if let w = (exprs.nameAny["w"] as? FloValScalar)?.twe,
               let h = (exprs.nameAny["h"] as? FloValScalar)?.twe {
                
                return CGSize(width: CGFloat(w), height: CGFloat(h))
            }
        }
        return nil
    }
    
    func CGRectVal() -> CGRect? {
        if let exprs {
            let ns = exprs.nameAny
            if ns.count >= 4,
               let x = (ns["x"] as? FloValScalar)?.twe,
               let y = (ns["y"] as? FloValScalar)?.twe,
               let w = (ns["w"] as? FloValScalar)?.twe,
               let h = (ns["h"] as? FloValScalar)?.twe {
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
            for opAny in exprs.opAnys {
                if opAny.op.pathName,
                   let name = opAny.any as? String,
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
            for opAny in exprs.opAnys {
                if opAny.op.pathName,
                   let name = opAny.any as? String,
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

    /// convert FloExprs contiguous array to dictionary
    public func nameScalars() -> [(String, FloValScalar)] {
        var result = [(String, FloValScalar)] ()
        if let exprs {
            for (name,any) in exprs.nameAny {
                if let scalar = any as? FloValScalar {
                    result.append((name,scalar))
                }
            }
        }
        return result
    }
    /// convert FloExprs contiguous array to dictionary
    public func scalars() -> [FloValScalar] {
        var result = [FloValScalar] ()
        if let exprs {
            for any in exprs.nameAny.values {
                if let scalar = any as? FloValScalar {
                    result.append(scalar)
                }
            }
        }
        return result
    }
    
    /// convert FloExprs contiguous array to dictionary
    public func components(named: [String]) -> [(String,Any?)] {
        var result = [(String, Any?)] ()
        for name in named {
            let val = exprs?.nameAny[name] ?? nil
            result.append((name,val))
        }
        return result
    }
    
    /// convert FloExprs contiguous array to dictionary
    public func components() ->  OrderedDictionary<String,Any>? {
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
           let scalar = comp as? FloValScalar {
            return scalar.range()
        }
        return getFirstRange()
    }
    public func getFirstRange() -> ClosedRange<Double> {
        if let exprs {
            for value in exprs.nameAny.values {
                if let scalar = value as? FloValScalar {
                    return scalar.range()
                }
            }
        }
        return 0...1
    }
}
