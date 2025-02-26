//  created by musesum on 8/21/22.

import Foundation

extension Exprs { // + get

    func getCGPoint() -> CGPoint? {
        if nameAny.count == 2,
           let x = nameAny["x"] as? Scalar,
           let y = nameAny["y"] as? Scalar {
            let xNum = Double(x.tween)
            let yNum = Double(y.tween)
            return CGPoint(x: xNum, y: yNum)
        }
        return nil
    }
    func getCGRect() -> CGRect? {
        if nameAny.count == 4,
           let x = nameAny["x"] as? Scalar,
           let y = nameAny["y"] as? Scalar {
            let xNum = Double(x.tween)
            let yNum = Double(y.tween)

            if let w = nameAny["w"] as? Scalar,
               let h = nameAny["h"] as? Scalar {
                let wNum = Double(w.tween)
                let hNum = Double(h.tween)
                return CGRect(x: xNum, y: yNum, width: wNum, height: hNum)

            } else if let w = nameAny["width"] as? Scalar,
                      let h = nameAny["height"] as? Scalar {

                let wNum = Double(w.tween)
                let hNum = Double(h.tween)
                return CGRect(x: xNum, y: yNum, width: wNum, height: hNum)
            }
        }
        return nil
    }
    public func getNums() -> [Double]? {
        var nums = [Double]()
        for value in nameAny.values {
            switch value {
                case let v as Scalar  : nums.append(Double(v.tween))
                case let v as CGFloat       : nums.append(Double(v))
                case let v as Float         : nums.append(Double(v))
                case let v as Double        : nums.append(v)
                default: continue 
            }
        }
        return nums.isEmpty ? nil : nums
    }
    public func getFloatNums() -> [Float]? {
        var nums = [Float]()
        for value in nameAny.values {
            switch value {
            case let v as Scalar  : nums.append(Float(v.tween))
            case let v as CGFloat       : nums.append(Float(v))
            case let v as Float         : nums.append(Float(v))
            case let v as Double        : nums.append(Float(v))
            default: continue
            }
        }
        return nums.isEmpty ? nil : nums
    }
}
