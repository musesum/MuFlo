//  Created by musesum on 7/26/23.

import Foundation


/// will find area for interval
func gaussianEasing(t: Double) -> Double {
    return 0.5 * (1 + erf(t / sqrt(2.0)))
}
/// inverse of gaussianEasing
func findIntervalForArea(area: Double) -> Double {
    if area < 0.5 {
        let n = sqrt(2.0) * erfinv(2 * area)
        return abs(n)
    } else {
        let n = sqrt(2.0) * erfinv(2 * (1 - area) - 1)
        return abs(n)
    }
}

func test() {
    // Test with eased progress values between 0 and 0.5
    let easedProgress1: Double = 0.2
    let originalProgress1 = findIntervalForArea(area: easedProgress1)
    print("Original Progress for area \(easedProgress1): 0 to \(originalProgress1)")

    // Test with eased progress values between 0.5 and 1
    let easedProgress2: Double = 0.8
    let originalProgress2 = findIntervalForArea(area: easedProgress2)
    print("Original Progress for area \(easedProgress2): \(1 - originalProgress2) to 1")
}
/// inverse error function
func erfinv(_ y: Double) -> Double {
    let center = 0.7
    let a = [ 0.886226899, -1.645349621,  0.914624893, -0.140543331]
    let b = [-2.118377725,  1.442710462, -0.329097515,  0.012229801]
    let c = [-1.970840454, -1.624906493,  3.429567803,  1.641345311]
    let d = [ 3.543889200,  1.637067800]
    if abs(y) <= center {
        let z = pow(y,2)
        let num = (((a[3]*z + a[2])*z + a[1])*z) + a[0]
        let den = ((((b[3]*z + b[2])*z + b[1])*z + b[0])*z + 1.0)
        var x = y*num/den
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        return x
    }
    else if abs(y) > center && abs(y) < 1.0 {
        let z = pow(-log((1.0-abs(y))/2),0.5)
        let num = ((c[3]*z + c[2])*z + c[1])*z + c[0]
        let den = (d[1]*z + d[0])*z + 1
        // should use the sign function instead of pow(pow(y,2),0.5)
        var x = y/pow(pow(y,2),0.5)*num/den
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        return x
    }
    else {
        // this should throw an error instead
        return Double(-Int.max)
    }
}

// Gaussian (Normal) Distribution
func gaussianCurve(_ x: Double,_ mean: Double = 0.5, _ standardDeviation: Double = 0.1) -> Double {
    let exponent = -pow(x - mean, 2) / (2 * pow(standardDeviation, 2))
    return exp(exponent)
}

// cumalative volume  = 1
func gaussianCDF(_ x: Double,_ mean: Double = 0.5, _ standardDeviation: Double = 0.1) -> Double {
    let z = (x - mean) / (standardDeviation * sqrt(2))
    return 0.5 * erfc(-z)
}
