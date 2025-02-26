//  created by musesum on 3/10/21.

import Foundation
import Collections

typealias Path = String
typealias PathExprs = OrderedDictionaryClass<Path,Exprs?>

extension OrderedDictionaryClass<Path,Exprs?> {
    func addPathExprs(_ path: Path,_ exprs: Exprs?) {
        if path.isEmpty,
           let lastKey = keys.last {
            self[lastKey] = exprs
        } else {
            self[path] = exprs
        }
    }
    func addExprs(_ exprs: Exprs) {
        if let lastKey = keys.last {
            self[lastKey] = exprs
        }
    }
    func addFlo(_ flo: Flo, name: Path) {
        if let lastKey = keys.last {
            self[lastKey] = Exprs(flo,name)
        }
    }
    func copy() -> PathExprs {
        let result = OrderedDictionaryClass<Path,Exprs?>()
        for (path,exprs) in self {
            result[path] = exprs
        }
        return result
    }

    static func == (lhs: OrderedDictionaryClass<Path,Exprs?>,
                    rhs: OrderedDictionaryClass<Path,Exprs?>) -> Bool {

        for (path,express) in lhs {
            if express == rhs[path]  { continue }
            return false
        }
        return true
    }

}
