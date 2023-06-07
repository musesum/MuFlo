//  Created by warren on 3/10/21.
//

import Foundation
import Collections

class FloPathVals {

    var edgeVals: OrderedDictionary<String,FloValExprs?> = [:] // eliminate duplicates

    func addPathVal(_ path: String = "",_ val: FloValExprs?) {
        if path.isEmpty {
            if let lastKey = edgeVals.keys.last {
                edgeVals[lastKey] = val
            } else {
                edgeVals[path] = val
            }
        } else {
            if edgeVals.keys.isEmpty {

                edgeVals[path] = val

            } else if let exprs = edgeVals[path] as? FloValExprs,
                      let scalar = val as? FloValScalar {

                exprs.addDeepScalar(scalar)

            } else {
                edgeVals[path] = val
            }
        }
    }
    static func == (lhs: FloPathVals, rhs: FloPathVals) -> Bool {

        for (key,val) in lhs.edgeVals {
            if val == rhs.edgeVals[key]  { continue }
            return false
        }
        return true
    }
}
