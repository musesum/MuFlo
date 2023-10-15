//  created by musesum on 3/10/21.
//

import Foundation
import Collections

class FloPathVals {

    var edgeExprs: OrderedDictionary<String,FloExprs?> = [:] // eliminate duplicates

    var exprs: FloExprs?  {
        for exprs in edgeExprs.values.reversed() {
            if let exprs {
                return exprs
            }
        }
        return nil
    }
    func addPathVal(_ path: String = "",_ val: FloExprs?) {
        if path.isEmpty,
           let lastKey = edgeExprs.keys.last {
                edgeExprs[lastKey] = val
        } else {
            edgeExprs[path] = val
        }
    }

    static func == (lhs: FloPathVals, rhs: FloPathVals) -> Bool {

        for (key,val) in lhs.edgeExprs {
            if val == rhs.edgeExprs[key]  { continue }
            return false
        }
        return true
    }
}
