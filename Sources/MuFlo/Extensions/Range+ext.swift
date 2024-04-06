//  created by musesum on 1/13/22.

import Foundation

extension ClosedRange {
    public func string(_ format: String = "(%.0f…%.0f %.0f…%.0f)") -> String {
        String(format: format,
               lowerBound as! CVarArg,
               upperBound as? CVarArg ?? 9999)
    }

}
//???
public func scale(_ value: Double,
                  from: ClosedRange<Double>,
                  to: ClosedRange<Double>,
                  invert: Bool = false) -> Double {
    
    let val = Double(value)
    
    let toSpan = to.upperBound - to.lowerBound // to
    let frSpan = from.upperBound - from.lowerBound // from
    let from01 = (val.clamped(to: from) - from.lowerBound) / frSpan
    let scaled = (from01 * toSpan) + to.lowerBound
    
    return invert ? 1-scaled : scaled
}
