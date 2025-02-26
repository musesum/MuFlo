//  created by musesum on 8/21/22.
//

import Foundation

extension EvalAny {

    func evalExpression(_ toVal: Any?,
                        _ frVal: Any?,
                        _ opNow: EvalOp) -> Any? {

        if (opNow == .none ||
            opNow == .assign) {
            return frVal
        }
        if let toNow = ((toVal as? Scalar)?.value ?? (toVal as? Double)),
           let frNow = ((frVal as? Scalar)?.value ?? (frVal as? Double)) {

            switch opNow {
            case .EQ    : return frNow == toNow ? frVal : nil
            case .LE    : return frNow <= toNow ? frVal : nil
            case .GE    : return frNow >= toNow ? frVal : nil
            case .LT    : return frNow <  toNow ? frVal : nil
            case .GT    : return frNow >  toNow ? frVal : nil
            case .In    : return fromInVal()
            case .add   : return frNow + toNow
            case .sub   : return frNow - toNow
            case .muy   : return frNow * toNow
            case .div   : return frNow / (toNow == 0 ? 1 : toNow)
            case .mod   : return fmod(frNow, toNow == 0 ? 1 : toNow)
            case .assign: return frVal //TODO: never here ?
            default: return frVal
            }
            func fromInVal() -> Any? {
                if let scalar = toVal as? Scalar,
                   scalar.inRange(from: frNow) {
                        return frVal
                }
                return nil
            }

        } else if toVal is String, frVal is String {
            //TODO: make String,Scalar, Num as generic for isConditional, above
            return frVal
        }
        return nil
    }
    
}
