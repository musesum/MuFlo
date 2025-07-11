// created by musesum on 7/19/19.

import Foundation
import QuartzCore
import UIKit
import SwiftUI

public typealias RangeXY = (ClosedRange<CGFloat>, ClosedRange<CGFloat>)
public enum Aspect: UInt {
    case landscape = 0
    case portrait = 1
    case square = 2

    public var description: String {
        switch self {
        case .landscape: return "landscape"
        case .portrait: return "portrait"
        case .square: return "square"
        }
    }
}

public extension CGRect {

    func digits(_ digits: Int = 0) -> String {
        "(\(minX.digits(digits)),\(minY.digits(digits)), \(width.digits(digits)),\(height.digits(digits)))"
    }


    static func / (lhs: CGRect, rhs: CGFloat) -> CGRect {
        
        if rhs > 0 {
            return CGRect(x: lhs.minX / rhs,
                          y: lhs.minY / rhs,
                          width: lhs.width / rhs,
                          height: lhs.height / rhs)
        } else {
            return .zero
        }
    }
    
    static func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
        
        return CGRect(x: lhs.minX * rhs, 
                      y: lhs.minY * rhs,
                      width: lhs.width * rhs,
                      height: lhs.height * rhs)
    }
    static func + (lhs: CGRect, rhs: CGFloat) -> CGRect {

        return CGRect(x: lhs.minX + rhs,
                      y: lhs.minY + rhs,
                      width: lhs.width + rhs,
                      height: lhs.height + rhs)
    }

    func horizontal() -> Bool {
        
        return size.width > size.height
    }
    
    func between(_ p: CGPoint) -> CGPoint {
        
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
        
        let pp = CGPoint(x: max(x, min(p.x, x + w)),
                         y: max(y, min(p.y, y + h)))
        return pp
    }
    
    func between(_ p: CGRect, _ insets: UIEdgeInsets = .zero) -> CGRect {
        
        let x = origin.x + insets.left
        let y = origin.y + insets.right
        let w = size.width - insets.left - insets.right
        let h = size.height - insets.top - insets.bottom
        
        var px = p.origin.x
        var py = p.origin.y
        var pw = p.size.width
        var ph = p.size.height
        
        if pw > w { pw = w }
        if ph > h { ph = h }
        if px < insets.left { px = insets.left }
        if py < insets.top { py = insets.top }
        if px + pw > x + w { px = x + w - pw }
        if py + ph > y + h { py = y + h - ph }
        
        let pp = CGRect(x: px, y: py, width: pw, height: ph)
        
        return pp
    }
    
    var center: CGPoint {
        get {
            let x = origin.x
            let y = origin.y
            let w = size.width
            let h = size.height
            let pp = CGPoint(x: x + w/2,
                             y: y + h/2)
            return pp
        }
    }

    /// scale up for a point p normalized between 0...1
    func scaleUpFrom01(_ p: CGPoint) -> CGPoint {
        
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
        
        let pp = CGPoint(x: x + p.x * w,
                         y: y + p.y * h)
        return pp
    }
    

    /// scale down to a point p normalized between 0...1
    func normalizeTo01(_ p: CGPoint) -> CGPoint {
        
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
        
        let pp = between(p)
        let xx = w == 0 ? 0 : (pp.x - x) / w
        let yy = h == 0 ? 0 : (pp.y - y) / h
        let ppp = CGPoint(x: xx,  y: yy)
        return ppp
    }
    
    func cornerDistance() -> CGFloat {
        
        let w = size.width
        let h = size.height
        
        let d = sqrt((w*w)+(h*h))
        return d
    }
    
    /// before and after are two finger pinch bounding rectangle.
    /// while pinching, rescale the current rect
    /// while shifting center shift rootd on direction of pinch
    func reScale(before: CGRect, after: CGRect) -> CGRect {
        
        let scale = after.cornerDistance() / before.cornerDistance()
        let delta = after.center - before.center
        
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
        
        let r = CGRect(x: x - delta.x,
                       y: y - delta.y,
                       width: w * scale,
                       height: h * scale)
        return r
    }
    
    func pad (_ pad: CGFloat) -> CGRect {
        
        let xx = origin.x - pad
        let yy = origin.y - pad
        let ww = width + pad * 2
        let hh = height + pad * 2
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }
    
    func shift (_ shift: CGPoint) -> CGRect {
        
        let xx = origin.x + shift.x
        let yy = origin.y + shift.y
        let s = CGRect(x: xx, y: yy, width: width, height: height)
        return s
    }
    
    func shift (_ shift: CGSize) -> CGRect {
        
        let xx = origin.x + shift.width
        let yy = origin.y + shift.height
        let s = CGRect(x: xx, y: yy, width: width, height: height)
        return s
    }
    
    static func + (lhs: CGRect, rhs: CGPoint) -> CGRect {
        
        let xx = lhs.origin.x + rhs.x
        let yy = lhs.origin.y + rhs.y
        let ww = lhs.width
        let hh = lhs.height
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }
    
    static func - (lhs: CGRect, rhs: CGPoint) -> CGRect {
        
        let xx = lhs.origin.x + rhs.x
        let yy = lhs.origin.y + rhs.y
        let ww = lhs.width
        let hh = lhs.height
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }
    
    func extend(_ from: CGRect) -> CGRect {
        
        if self == .zero {
            //log("from", [from])
            return from
        }
        if from == .zero {
            // log("self", [self])
            return self
        }
        
        let sx0 = self.origin.x
        let sy0 = self.origin.y
        let sx1 = self.origin.x + self.size.width
        let sy1 = self.origin.y + self.size.height
        
        let fx0 = from.origin.x
        let fy0 = from.origin.y
        let fx1 = from.origin.x + from.size.width
        let fy1 = from.origin.y + from.size.height
        
        let rx0 = min(sx0, fx0)
        let ry0 = min(sy0, fy0)
        let rx1 = max(sx1, fx1)
        let ry1 = max(sy1, fy1)
        
        let result = CGRect(x: rx0, y: ry0, width: rx1-rx0, height: ry1-ry0)
        return result
    }

    /// normalize to 0...1
    func normalize() -> CGRect {
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = CGRect(x: x / w,
                        y: y / h,
                        width: (w - 2*x) / w,
                        height:(h - 2*y) / h)
        return pp
    }

    func floats() -> [Float] {
        return [Float(minX),Float(minY),Float(width),Float(height)]
    }
}
public extension UInt8 {
    func digits(_ digits: Int = 0) -> String {
        let str = String(self, radix: 10)
        let pad = String(repeating: " ", count: digits - str.count) + str
        return pad
    }
}
public extension CGPoint {
    
    func digits(_ digits: Int = 0) -> String {
        "(\(x.digits(0)),\(y.digits(0)))"
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x - rhs.x,
                        y: lhs.y - rhs.y)
        return p
    }
    
    static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        let p = CGPoint(x: lhs.x - rhs.width,
                        y: lhs.y - rhs.height)
        return p
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x + rhs.x,
                        y: lhs.y + rhs.y)
        return p
    }
    
    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        let p = CGPoint(x: lhs.x + rhs.width,
                        y: lhs.y + rhs.height)
        return p
    }
    
    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        
        let xx = lhs.x / rhs
        let yy = lhs.y / rhs
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    static func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        
        let xx = rhs.x > 0 ? lhs.x / rhs.x : 0
        let yy = rhs.y > 0 ? lhs.y / rhs.y : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    static func / (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        
        let xx = rhs.width  > 0 ? lhs.x / rhs.width  : 0
        let yy = rhs.height > 0 ? lhs.y / rhs.height : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        
        let xx = lhs.x * rhs
        let yy = lhs.y * rhs
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    func distance(_ from: CGPoint) -> CGFloat {
        
        let result = sqrt((x-from.x)*(x-from.x) +
                          (y-from.y)*(y-from.y) )
        return result
    }
    
    /// round to nearest grid
    func grid(_ divisions: CGFloat) -> CGPoint {
        
        if divisions > 0 {
            return  CGPoint(x: round(x * divisions) / divisions,
                            y: round(y * divisions) / divisions)
        }
        return self
    }
    
    func string(_ format: String = "%2.0f,%-2.0f") -> String {
        
        return String(format: format, x, y) // touch delta
    }
    
    init(_ size: CGSize) {
        self.init()
        x = size.width
        y = size.height
    }
    func doubles() -> [Double] {
        return [Double(x), Double(y)]
    }
    func floats() -> [Float] {
        return [Float(x),Float(y)]
    }
}

public extension CGSize {

    func digits(_ digits: Int = 0) -> String {
        "(\(width.digits(digits)),\(height.digits(digits)))"
    }

    static var _1080p: CGSize {
        CGSize(width: 1920, height: 1080)
    }
    static var _4K: CGSize {
        CGSize(width: 3840, height: 2160)
    }
    init(_ xy: CGPoint) {
        self.init()
        self.width = xy.x
        self.height = xy.y
    }
    
    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width - rhs.width
        let hh = lhs.height - rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width + rhs.width
        let hh = lhs.height + rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    static func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
        let ww = lhs.width + rhs
        let hh = lhs.height + rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }

    static func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
        let ww = lhs.width - rhs
        let hh = lhs.height - rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }


    static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        
        let ww = lhs.width / rhs
        let hh = lhs.height / rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
       static func - (lhs: CGSize, rhs: CGPoint) -> CGSize {
        let ww = lhs.width - rhs.x
        let hh = lhs.height - rhs.y
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    static func + (lhs: CGSize, rhs: CGPoint) -> CGSize {
        let ww = lhs.width + rhs.x
        let hh = lhs.height + rhs.y
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    func string(_ format: String = "%2.0f,%-2.0f") -> String {
        
        return String(format: format, width, height) // touch delta
    }
    
    func clamp(_ widthvalue: ClosedRange<CGFloat>,
               _ heightvalue: ClosedRange<CGFloat>) -> CGSize {
        
        return CGSize(width:  width.clamped(to: widthvalue),
                      height: height.clamped(to: heightvalue) )
    }
    /// fit smaller self's smaller rect inside to's rect
    /// may overlay lower right edges, but not upper left
    func clamped(to: RangeXY) -> CGSize {
        let (xClamp,yClamp) = to
        
        let ww = self.width.clamped(to: xClamp)
        let hh = self.height.clamped(to: yClamp)
        
        let size = CGSize(width: ww, height: hh)
        return size
    }
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {

        let ww = lhs.width * rhs
        let hh = lhs.height * rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }

    func floats() -> [Float] {
        return [Float(width),Float(height)]
    }
}

extension CGSize: @retroactive Hashable {
    
    public func hash(into hasher: inout Hasher) {
        
        hasher.combine(width*9999)
        hasher.combine(height)
        _ = hasher.finalize()
    }
}
extension EdgeInsets {

    public func digits(_ digits: Int = 0) -> String {
        "(\(top.digits(digits)),\(leading.digits(digits)), \(bottom.digits(digits)),\(trailing.digits(digits)))"
    }

    public static func + (lhs: EdgeInsets, rhs: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: lhs.top + rhs,
                          leading: lhs.leading + rhs,
                          bottom: lhs.bottom + rhs,
                          trailing: lhs.trailing + rhs)
    }

}
public extension CGSize {
    var aspect: Aspect {

        width > height ? .landscape :
        width < height ? .portrait : .square
    }
    func withAspect(_ aspect: Aspect) -> CGSize {
        let w: CGFloat
        let h: CGFloat
        switch aspect {
        case .landscape:
            w = max(height, width)
            h = min(height, width)
        default:
            w = min(height, width)
            h = max(height, width)
        }
        return CGSize(width: w, height: h)
    }
}
