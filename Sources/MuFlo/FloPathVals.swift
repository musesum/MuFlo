//  Created by warren on 3/10/21.
//

import Foundation
import Collections

class FloPathVals {

    var pathVal: OrderedDictionary<String,FloVal?> = [:] // eliminate duplicates

    func add(path: String = "", val: FloVal?) {
        if path.isEmpty {
            if let lastKey = pathVal.keys.last {
                pathVal[lastKey] = val
            } else {
                pathVal[path] = val
            }
        } else {
            if pathVal.keys.isEmpty {

                pathVal[path] = val

            } else if let exprs = pathVal[path] as? FloValExprs,
                    let scalar = val as? FloValScalar {

                exprs.addDeepScalar(scalar)

            } else {
                pathVal[path] = val
            }
        }
    }
    static func == (lhs: FloPathVals, rhs: FloPathVals) -> Bool {

        for (key,val) in lhs.pathVal {
            if val == rhs.pathVal[key]  { continue }
            return false
        }
        return true
    }
}
