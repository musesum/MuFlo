//  created by musesum on 7/7/17.

import Foundation
import Collections

/// Set of blocked nodes that failed a test condition
///
/// Sometimes, a node will contain multiple values, which may be set
/// individually by other nodes and then sync with those same nodes.
/// For instance, two MIDI knobs, setting `x` and `y` position, which
/// synchronizes with a 2D `X,Y` touchpad.
///
/// For example, here is the wrong way to do it:
///
///     in.control(val)                 // twist knob X
///     >> knob.repeatX(val)            // update knob.repeatX
///        <> pad.repeat(x val)         // update repeat(x,y)
///           >> knob.repeatY(val y)    // update knob.repeatY
///              << out.contoller(val)  // update out.control
///        << out.control(🏁)           // bad, blocks repeatX
///
/// The correct way is to visit breadth-first and then add failed nodes to `blocked`
///
///     in.control(cc=1, val=11)       // twist midi knob 1 outputs 11
///     >> knob.repeatY(cc==2,⛔️)      // failed cc==2 match, so block
///     >> knob.repeatX(cc==1,val=11)  // passes cc match, so continue
///        <> pad.repeat(x val=11)     // sync with onscreen xy control
///           >> knob.repeatY(⛔️)      // block failed cc==2 eval
///        << out.control(cc=1,val=11) // send repeatX to midi out
///
/// The blocked set in wrapped in a class, so that its reference is copied.
/// This is useful for animating tweens. For MuValScalar, may set its `val` once
/// and then animated tween `twe` dozens of times. Retaining the blocked set,
/// memoizes the conditionals that failed the first time.
///
public typealias Blocked = OrderedSetClass<Int>

/// Visit a node only once. Collect and compare with a set of nodes already visited.
public class Visitor {

    static var Id = 0  // unique identifier for each node
    public static func nextId() -> Int { Id += 1; return Id }

    private var lock = NSLock()
    public var visited = OrderedSet<Int>()
    public var blocked: Blocked?

    public var from: VisitFrom

    public init (_ ids: [Int?], from: VisitFrom = .model) {
        self.from = from
        nowHeres(ids)
    }
    public init (_ id: Int,
                 from: VisitFrom = .model,
                 blocked: Blocked? = nil ) {

        self.from = from
        nowHere(id)
    }
    public init (_ from: VisitFrom) {
        self.from = from
    }

    public func remove(_ id: Int) {
        lock.lock()
        visited.remove(id)
        lock.unlock()
    }
    public func nowHere(_ id: Int) {
        lock.lock()
        visited.append(id)
        lock.unlock()
    }
    public func block(_ id: Int) {
        lock.lock()
        if blocked == nil {
            blocked = Blocked([id])
        } else {
            blocked?.append(id)
        }
        lock.unlock()
    }
    public func nowHeres(_ ids: [Int?]) {
        lock.lock()
        for id in ids {
            if let id {
                visited.append(id)
            }
        }
        lock.unlock()
    }
    public func isBlocked(_ id: Int) ->  Bool {
        lock.lock()
        let blocking = blocked?.contains(id) ?? false
        lock.unlock()
        return blocking
    }
    public func wasHere(_ id: Int) -> Bool {
        lock.lock()
        let visited = visited.contains(id)
        let blocking = blocked?.contains(id) ?? false
        lock.unlock()
        return visited || blocking
    }
    public func isLocal() -> Bool {
        return !from.remote
    }
    public func newVisit(_ id: Int) -> Bool {
        if wasHere(id) {
            return false
        } else {
            nowHere(id)
            return true
        }
    }
    public func via(_ via: VisitFrom) -> Visitor {
        self.from.insert(via)
        return self
    }
    public var log: String {
        lock.lock()
        let visits = visited.map { String($0)}.joined(separator: ",")
        lock.unlock()
        return "\(from.log):(\(visits))"
    }
}

