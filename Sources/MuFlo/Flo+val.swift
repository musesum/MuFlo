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
            if let f = (exprs.nameAny["tog"] as? FloValScalar)?.val {
                return f > 0
            } else if let f = (exprs.nameAny["tap"] as? FloValScalar)?.val {
                return f > 0
            } else if let scalar = exprs.nameAny.values.last as? FloValScalar  {
                return scalar.val > 0
            }
        }
        return false
    }
    
    func DoubleVal() -> Double? {
       if let exprs {
            if let f = (exprs.nameAny["v"] as? FloValScalar)?.now {
                return f
            } else if let scalar = exprs.nameAny.values.last as? FloValScalar  {
                return scalar.now //??? or .val
            }
        }
        return nil
    }
    
    func Normals() -> [Double] {
        if let exprs {
            if let v = exprs.nameAny["v"] as? FloValScalar {
                return [v.normalized()]
            } else  {
                var ret = [Double()]
                for value in exprs.nameAny.values {
                    if let v = value as? Double {
                        ret.append(v)
                    }
                }
                return ret
            }
        }
        return []
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
            if let x = (exprs.nameAny["x"] as? FloValScalar)?.now,
               let y = (exprs.nameAny["y"] as? FloValScalar)?.now {
                
                return CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
        return nil
    }
    
    func CGSizeVal() -> CGSize? {
        if let exprs {
            if let w = (exprs.nameAny["w"] as? FloValScalar)?.now,
               let h = (exprs.nameAny["h"] as? FloValScalar)?.now {
                
                return CGSize(width: CGFloat(w), height: CGFloat(h))
            }
        }
        return nil
    }
    
    func CGRectVal() -> CGRect? {
        if let exprs {
            let ns = exprs.nameAny
            if ns.count >= 4,
               let x = (ns["x"] as? FloValScalar)?.now,
               let y = (ns["y"] as? FloValScalar)?.now,
               let w = (ns["w"] as? FloValScalar)?.now,
               let h = (ns["h"] as? FloValScalar)?.now {
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
