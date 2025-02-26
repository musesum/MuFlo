import QuartzCore


public typealias Val4<T> = (T,T,T,T)

public class CubicPoly<T: FloatingPoint> where T: Comparable {

    var vals = Val4<T>(T.zero,T.zero,T.zero,T.zero) // series values to interpolate
    var coef = Val4<T>(T.zero,T.zero,T.zero,T.zero) // coeficients for cubic
    var index = 0 // current position within series
    public var distance: T { abs(vals.2 - vals.3) }

    public init() {}

    /// interpolate cubic position on vals series with `inter` ranging from 0 to 1
    public func getInter(_ i: T) -> T {
        let i² = i * i
        let i³ = i² * i
        let val = coef.0 + (coef.1 * i) + (coef.2 * i²) + (coef.3 * i³)
        return val
    }

    /// Compute coefficients for a cubic polynomial --  Catmull-Rom spline: interpolation
    ///
    ///     p(s) = coef.0 + coef.1 * s + coef.2 * s^2 + coef.3 * s^3 //such that
    ///     p(0) = x0, p(1) = x1 // and
    ///     p'(0) = t0, p'(1) = t1.
    ///
    func makeCoeficients() {

        let v2_0 = (vals.2 - vals.0) // delta [2]-[0]
        let v3_1 = (vals.3 - vals.1) // delta [3]-[1]
        let v2_1 = (vals.2 - vals.1)
        let v1_2 = (vals.1 - vals.2)

        coef.0 = vals.1
        coef.1 = v2_0/2
        coef.2 = v2_1*3 - v2_0   - v3_1/2
        coef.3 = v1_2*2 + v2_0/2 + v3_1/2
    }

    /// Add values in a series
    ///
    /// When drawing,the touchBegin is both the start and end point are the same.
    /// For drawing, all of the intermediate points are rendereded between frames.
    /// So, a simple shift of terms will suffice
    ///
    public func addVal(_ val: T,
                       _ isDone: Bool) {
        switch index {
        case 0:  setVals((val,    val,    val,    val)) // a a a a  a-a
        case 1:  setVals((vals.0, vals.1, val,    val)) // a a b b  a-b
        case 2:  setVals((vals.0, vals.2, vals.3, val)) // a b b c  b-b
        default: setVals((vals.1, vals.2, vals.3, val)) // a b c d  b-c
        }
        index = isDone ? 0 : index + 1
    }
    public func setVals(_ vals: Val4<T>) {
        self.vals = vals
        makeCoeficients()
    }
}

