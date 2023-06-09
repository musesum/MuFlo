//  Created by warren on 3/10/21.
//

import Foundation
import Collections

class FloPathVals {

    var edgeVals: OrderedDictionary<String,FloExprs?> = [:] // eliminate duplicates

    func addPathVal(_ path: String = "",_ val: FloExprs?) {
        if path.isEmpty,
           let lastKey = edgeVals.keys.last {
                edgeVals[lastKey] = val
        } else {
            edgeVals[path] = val
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
