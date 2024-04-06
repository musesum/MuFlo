// created by musesum on 12/22/23


import simd
import Metal

public extension Float {
    func scale(_ s: Float) -> matrix_float4x4 {

        return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, s),
                                             vector_float4(0, 1, 0, s),
                                             vector_float4(0, 0, 1, s),
                                             vector_float4(0, 0, 0, 1)))
    }
}

public extension SIMD2<Float> {

    func script(_ range: Int) -> String {
        "(\(x.digits(range)),\(y.digits(range)))"
    }
    var script: String {
        "(\(x.digits(-1)),\(y.digits(-1)))"
    }
}
public extension SIMD3<Float> {

    func hash(_ max: Float) -> Scalar {
        let h = ((x+max) * max * max) + ((y+max) * max) + (z + max)
        return h
    }
    func script(_ range: Int) -> String {
        "(\(x.digits(range)),\(y.digits(range)),\(z.digits(range)))"
    }
    var script: String {
        "(\(x.digits(-1)),\(y.digits(-1)),\(z.digits(-1)))"
    }
    func rotate(radians: Float) ->  matrix_float4x4 {
        let rotate = normalize(self)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = rotate.x, y = rotate.y, z = rotate.z
        let col0 = vector_float4(x*x*ci + ct  , y*x*ci + z*st, z*x*ci - y*st, 0)
        let col1 = vector_float4(x*y*ci - z*st, y*y*ci +   ct, z*y*ci + x*st, 0)
        let col2 = vector_float4(x*z*ci + y*st, y*z*ci - x*st, z*z*ci + ct  , 0)
        let col3 = vector_float4(            0,             0,             0, 1)
        return matrix_float4x4.init(columns:(col0,col1,col2,col3))

    }

}
public extension SIMD4<Float> {

    func hash(_ max: Float) -> Scalar {
        let h = ((x+max) * max * max) + ((y+max) * max) + (z + max)
        return h
    }
    func script(_ range: Int) -> String {
        "(\(x.digits(range)),\(y.digits(range)),\(z.digits(range)),\(w.digits(range)))"
    }
    var script: String {
        "(\(x.digits(-1)),\(y.digits(-1)),\(z.digits(-1)),\(w.digits(-1)))"
    }
    var xyz: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
    var translate: matrix_float4x4 {

        return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                             vector_float4(0, 1, 0, 0),
                                             vector_float4(0, 0, 1, 0),
                                             vector_float4(self.x, self.y, self.z, 1)))
    }
}
public extension SIMD4<Double> {

    func script(_ range: Int) -> String {
        "(\(x.digits(range)),\(y.digits(range)),\(z.digits(range)),\(w.digits(range)))"
    }
    var script: String {
        "(\(x.digits(-1)),\(y.digits(-1)),\(z.digits(-1)),\(w.digits(-1)))"
    }
    var xyz: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
}
public extension simd_float4x4 {

    func script(_ range: Int) -> String {
        return "(\(columns.0.script(range)), \(columns.1.script(range)), \(columns.2.script(range)), \(columns.3.script(range)))"
    }
    var script: String {
        return "(\(columns.0.script), \(columns.1.script), \(columns.2.script), \(columns.3.script))"
    }
}
public extension simd_double4x4 {

    func script(_ range: Int) -> String {
        return "(\(columns.0.script(range)), \(columns.1.script(range)), \(columns.2.script(range)), \(columns.3.script(range)))"
    }
    var script: String {
        return "(\(columns.0.script), \(columns.1.script), \(columns.2.script), \(columns.3.script))"
    }
}

public func projection(_ size: CGSize) -> simd_float4x4 {

    let aspect = Float(size.width / size.height)
    let fovy = Float(aspect > 1 ? 60.0 : 90.0) / 180.0 * .pi
    let nearZ = Float(0.1)
    let farZ = Float(100)

    return perspective4x4(aspect, fovy, nearZ, farZ)
}

public func perspective4x4(_ aspect: Float,
                           _ fovy  : Float,
                           _ nearZ : Float,
                           _ farZ  : Float) -> matrix_float4x4 {

    let yScale  = 1 / tan(fovy * 0.5)
    let xScale  = yScale / aspect
    let zRange  = farZ - nearZ
    let zScale  = -(farZ + nearZ) / zRange
    let wzScale = -farZ * nearZ / zRange
    let P = vector_float4([ xScale, 0, 0, 0  ])
    let Q = vector_float4([ 0, yScale, 0, 0  ])
    let R = vector_float4([ 0, 0, zScale, -1 ])
    let S = vector_float4([ 0, 0, wzScale, 0 ])

    let mat = matrix_float4x4([P, Q, R, S])
    return mat
}

public func translation(_ t: vector_float4) -> matrix_float4x4 {
    let X = vector_float4([  1,  0,  0,  0 ])
    let Y = vector_float4([  0,  1,  0,  0 ])
    let Z = vector_float4([  0,  0,  1,  0 ])
    let W = vector_float4([t.x,t.y,t.z,t.w ])

    let mat = matrix_float4x4([X,Y,Z,W])
    return mat
}
public extension SIMD2<Double> {
    
    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }
    func quantize(_ div: Double) -> SIMD2<Double> {

        let xx = (x * div).rounded() / div
        let yy = (y * div).rounded() / div
        return SIMD2<Double>(x: xx, y: yy)
    }
    func clamped(to limits: ClosedRange<Double>) -> SIMD2<Double> {
        return SIMD2<Double>( x: x.clamped(to: limits),
                              y: y.clamped(to: limits))
    }
    func distance(_ from: SIMD2<Double>) -> Double {

        let result = sqrt((x-from.x)*(x-from.x) +
                          (y-from.y)*(y-from.y) )
        return result
    }
}
public extension SIMD3<Double> {

    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y), z:  Double(0))
    }

    func quantize(_ div: Double) -> SIMD3<Double> {
        let xx = (x * div).rounded() / div
        let yy = (y * div).rounded() / div
        let zz = (z * div).rounded() / div
        return SIMD3<Double>(x: xx, y: yy, z: zz)
    }

    func clamped(to limits: ClosedRange<Double>) -> SIMD3<Double> {
        return SIMD3<Double>( x: x.clamped(to: limits),
                              y: y.clamped(to: limits),
                              z: z.clamped(to: limits))
    }
}
public extension Double {

    func quantize(_ div: Double) -> Double {

        return (self * div).rounded() / div
    }
}
