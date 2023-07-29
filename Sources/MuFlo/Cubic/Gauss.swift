//  Created by warren on 7/26/23.

import Foundation

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
