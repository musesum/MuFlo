// Flo+val.swift
//
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import MuPar

extension Flo {
    
    func StringVal() -> String? {
        if let exprs = val as? FloValExprs,
           let str = exprs.opVals.first?.val as? String {
            // anonymous String inside expression
            // example `color ("compute.color.metal")`
            return str
        }
        return nil
    }
    
    func BoolVal() -> Bool {
        if let v = val as? FloValScalar {
            return v.now > 0
        }  else if let exprs = val as? FloValExprs {
            if let f = (exprs.nameAny["tog"] as? FloValScalar)?.now {
                return f > 0
            } else if let f = (exprs.nameAny["tap"] as? FloValScalar)?.now {
                return f > 0
            } else if let scalar = exprs.nameAny.values.last as? FloValScalar  {
                return scalar.now > 0
            }
        }
        return false
    }
    
    func DoubleVal() -> Double? {
        if let v = val as? FloValScalar {
            return v.now
        } else if let exprs = val as? FloValExprs {
            
            if let f = (exprs.nameAny["v"] as? FloValScalar)?.now {
                return f
            } else if let scalar = exprs.nameAny.values.last as? FloValScalar  {
                return scalar.now
            }
        }
        return nil
    }
    
    func Normals() -> [Double] {
        if let v = val as? FloValScalar {
            return [v.normalized()]
        } else if let exprs = val as? FloValExprs {
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
        
        if let exprs = val as? FloValExprs {
            if let x = (exprs.nameAny["x"] as? FloValScalar)?.now,
               let y = (exprs.nameAny["y"] as? FloValScalar)?.now {
                
                return CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
        return nil
    }
    
    func CGSizeVal() -> CGSize? {
        if let v = val as? FloValExprs {
            if let w = (v.nameAny["w"] as? FloValScalar)?.now,
               let h = (v.nameAny["h"] as? FloValScalar)?.now {
                
                return CGSize(width: CGFloat(w), height: CGFloat(h))
            }
        }
        return nil
    }
    
    func CGRectVal() -> CGRect? {
        if let v = val as? FloValExprs {
            let ns = v.nameAny
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
        if let v = val as? FloValExprs,
           v.nameAny.count > 0 {
            return Array<String>(v.nameAny.keys)
        }
        return nil
    }
    /// get first occurence name in Set of types (there should only be one)
    public func getName(in types: Set<String>) -> String? {
        if let exprs = val as? FloValExprs {
            for opVal in exprs.opVals {
                if opVal.op.pathName,
                   let name = opVal.val as? String,
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
        if let exprs = val as? FloValExprs {
            var matchCount = 0
            for opVal in exprs.opVals {
                if opVal.op.pathName,
                   let name = opVal.val as? String,
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
        if let exprs = val as? FloValExprs {
            if let val = exprs.nameAny[named] {
                
                return val
            }
        }
        return nil
    }
    
    /// convert FloValExprs contiguous array to dictionary
    public func components(named: [String]) -> [(String,Any?)] {
        var result = [(String, Any?)] ()
        for name in named {
            let val = (val as? FloValExprs)?.nameAny[name] ?? nil
            result.append((name,val))
        }
        return result
    }
    
    /// convert FloValExprs contiguous array to dictionary
    public func components() ->  OrderedDictionary<String,Any>? {
        return (val as? FloValExprs)?.nameAny ?? nil
    }
}
