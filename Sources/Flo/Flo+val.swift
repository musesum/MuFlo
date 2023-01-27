// Flo+val.swift
//
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import QuartzCore
import Collections
import Par

extension Flo {

    public func StringVal() -> String? {
        if let exprs = val as? FloExprs,
                  let str = exprs.exprs.first?.val as? String {
            // anonymous String inside expression
            // example `color ("pipe.color.metal")`
            return str
        }
        return nil
    }

    public func BoolVal() -> Bool {
        if let v = val as? FloValScalar {
            return v.now > 0
        }
        return false
    }

    public func DoubleVal() -> Double? {
        if let v = val as? FloValScalar {
            return v.now
        }
        else if let exprs = val as? FloExprs {
            if let f = (exprs.nameAny["v"] as? FloValScalar)?.now {
                return f
            } else if let scalar = exprs.nameAny.values.last as? FloValScalar  {
                return scalar.now
            }
        }
        return nil
    }

    public func Normals() -> [Double] {
        if let v = val as? FloValScalar {
            return [v.normalized()]
        }
        else if let exprs = val as? FloExprs {
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

    public func IntVal() -> Int? {
        if let num = DoubleVal() { return Int(num) }
        return nil
    }

    public func CGFloatVal() -> CGFloat? {
        if let f = DoubleVal() { return CGFloat(f) }
        return nil
    }
    
    public func FloatVal() -> Float? {
        if let f = DoubleVal() { return Float(f) }
        return nil
    }

    public func CGPointVal() -> CGPoint? {

        if let exprs = val as? FloExprs {
            if let x = (exprs.nameAny["x"] as? FloValScalar)?.now,
               let y = (exprs.nameAny["y"] as? FloValScalar)?.now {

                return CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
        return nil
    }
    
    public func CGSizeVal() -> CGSize? {
        if let v = val as? FloExprs {
            if let w = (v.nameAny["w"] as? FloValScalar)?.now,
               let h = (v.nameAny["h"] as? FloValScalar)?.now {

                return CGSize(width: CGFloat(w), height: CGFloat(h))
            }
        }
        return nil
    }

    public func CGRectVal() -> CGRect? {
        if let v = val as? FloExprs {
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

    public func NamesVal() -> [String]? {
        if let v = val as? FloExprs,
           v.nameAny.count > 0 {
            return Array<String>(v.nameAny.keys)
        }
        return nil
    }
    /// get first occurence name in Set of types (there should only be one)
    public func getName(in types: Set<String>) -> String? {
        if let exprs = val as? FloExprs {
            for expr in exprs.exprs {
                if (expr.op == .name || expr.op == .path),
                   let name = expr.val as? String,
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
        if let exprs = val as? FloExprs {
            var matchCount = 0
            for expr in exprs.exprs {
                if (expr.op == .name || expr.op == .path),
                   let name = expr.val as? String,
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
        if let exprs = val as? FloExprs {
            if let val = exprs.nameAny[named] {

                return val
            }
        }
        return nil
    }

    /// convert FloExprs contiguous array to dictionary
    public func components(named: [String]) -> [(String,Any?)] {
        var result = [(String, Any?)] ()
        for name in named {
            let val = (val as? FloExprs)?.nameAny[name] ?? nil
            result.append((name,val))
        }
        return result
    }

    /// convert FloExprs contiguous array to dictionary
    public func components() ->  OrderedDictionary<String,Any>? {
        return (val as? FloExprs)?.nameAny ?? nil
    }
}
