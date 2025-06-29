//  created by musesum on 7/7/17.

import Foundation
import Collections


/// Visit a node only once. Collect and compare with a set of nodes already visited.
/// 
public class Visitor {
    
    nonisolated(unsafe) static var VisitorId = 0  // unique identifier for each node
    private var lock = NSLock()
    public static func nextId() -> Int {
        let lock = NSLock()
        lock.lock()
        VisitorId += 1
        lock.unlock()
        return VisitorId
    }

    public var visited = OrderedSet<Int>()
    public var blocked: Blocked?
    public var from: Flo?
    public var type: VisitType


    public init (_ id: Int = 0,
                 _ type: VisitType = .model,
                 from: Flo? = nil) {
        
        self.type = type
        self.from = from
        let fromId = from?.id ?? id
        nowHere(fromId)
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
    public func isRemote() -> Bool {
        return type.has(.remote)
    }
    public func isLocal() -> Bool {
        return !type.has(.remote)
    }
    public func newVisit(_ id: Int) -> Bool {
        if wasHere(id) {
            return false
        } else {
            nowHere(id)
            return true
        }
    }
    public func via(_ via: VisitType) -> Visitor {
        self.type.insert(via)
        return self
    }
    public var log: String {
        lock.lock()
        let visits = visited.map { String($0)}.joined(separator: ",")
        lock.unlock()
        return "\(type.log):(\(visits))"
    }
}

