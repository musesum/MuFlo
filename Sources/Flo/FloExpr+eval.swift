//  Created by warren on 8/21/22.
//

import Foundation
extension Double {
    
}
extension FloExpr {

    func evaluate(_ toVal: Any?,
                  _ frVal: Any?,
                  _ opNow: FloExprOp) -> Any? {

        if (opNow == .none ||
            opNow == .assign) {
            return frVal
        }

        if let toNow = ((toVal as? FloValScalar)?.now ?? (toVal as? Double)),
           let frNow = ((frVal as? FloValScalar)?.now ?? (frVal as? Double)) {

            if opNow.isConditional() {
                switch opNow {
                    case .EQ: return frNow == toNow ? frVal : nil
                    case .LE: return frNow <= toNow ? frVal : nil
                    case .GE: return frNow >= toNow ? frVal : nil
                    case .LT: return frNow <  toNow ? frVal : nil
                    case .GT: return frNow >  toNow ? frVal : nil

                    case .In:
                        var isIn = false
                        if let val = toVal as? FloValScalar {
                            isIn = val.inRange(from: frNow)
                        }
                        return isIn ? frVal : nil
                    default : break
                }
            } else if opNow.isOperation() {

                switch opNow {
                    case .add   : return frNow + toNow
                    case .sub   : return frNow - toNow
                    case .muy   : return frNow * toNow
                    case .divi  : return floor(frNow / (toNow == 0 ? 1 : toNow))
                    case .div   : return frNow / (toNow == 0 ? 1 : toNow)
                    case .mod   : return fmod(frNow, toNow == 0 ? 1 : toNow)
                    case .assign: return frVal //TODO: never here
                    default     : break
                }
            } else {
                return frVal
            }
        } else if toVal is String , frVal is String {
            //TODO: make String,FloValScalar, Num as generic for isConditional, above
            return frVal
        }
        return nil
    }

}
