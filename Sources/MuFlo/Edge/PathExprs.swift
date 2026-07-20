//  created by musesum on 3/10/21.

import Foundation
import Collections

typealias Path = String

/// ordered path→exprs map for one edge scope (`<> (a(...), b(...), ...)`).
///
/// `curKey` tracks the path most recently added, so a REPEATED target path
/// merges its exprs into the existing entry instead of clobbering it, and a
/// trailing exprs attaches to that repeated path — not to whatever key
/// happens to be last:
///
///     mix <> (t(x: w), u(y: y), t(y: z))
///
/// yields `t(x: w, y: z)` with `u(y: y)` intact. Before the cursor, the
/// second `t` re-inserted the key as nil (destroying `x: w`) and its exprs
/// attached to `keys.last` = `u`, clobbering `u`'s map.
final class PathExprs: OrderedDictionaryClass<Path, Exprs?> {

    private var curKey: Path?

    func addPathExprs(_ path: Path,_ exprs: Exprs?) {
        if path.isEmpty {
            if let lastKey = keys.last {
                curKey = lastKey
                self[lastKey] = exprs
            }
        } else if let existing = self[path] ?? nil {
            curKey = path
            if let exprs {
                exprs.prependExprs(existing)
                self[path] = exprs
            } // bare repeated path keeps the existing map
        } else {
            curKey = path
            self[path] = exprs
        }
    }
    func addExprs(_ exprs: Exprs) {
        guard let key = curKey ?? keys.last else { return }
        if let existing = self[key] ?? nil {
            // repeated target path: fold the prior map into the new exprs —
            // the new object stays live (the parser fills its tokens AFTER
            // attaching it here), so the merge must land in the newer one
            exprs.prependExprs(existing)
        }
        self[key] = exprs
    }
    func addFlo(_ flo: Flo, name: Path) {
        guard let key = curKey ?? keys.last else { return }
        self[key] = Exprs(flo, name)
    }
    func copy() -> PathExprs {
        let result = PathExprs()
        for (path,exprs) in self {
            result[path] = exprs
        }
        return result
    }

    static func == (lhs: PathExprs,
                    rhs: PathExprs) -> Bool {

        for (path,express) in lhs {
            if let express {
                if let rhsExpress = rhs[path] {
                    if express != rhsExpress { return false }
                } else {
                    continue
                }
            } else if rhs[path] != nil {
                return false
            }
        }
        return true
    }

}
