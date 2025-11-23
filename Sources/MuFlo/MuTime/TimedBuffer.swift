
import Foundation
import NIOCore
import MuPeers // DataFrom

public protocol TimedBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ from: DataFrom) -> BufState
}

public protocol TimedItem: Sendable {
    var time: TimeInterval { get }
}
public typealias TimeLag = TimeInterval

public class TimedBuffer<Item: TimedItem>: @unchecked Sendable {

    private let id = Visitor.nextId()
    private var buffer: CircularBuffer<(Item, TimeLag, DataFrom)>
    private let capacity: Int
    private var lock = NSLock()

    public var delegate: (any TimedBufferDelegate)?
    private var minLag: TimeInterval = 0.20 // static minimum timelag
    private var maxLag: TimeInterval = 2.00 // stay within 2 second delay
    private var nextLag: TimeInterval = 1.00 // filtered next timelag
    private var filterLag: Double = 0.95

    private var prevItem: Item?
    private var prevItemTime: TimeInterval?
    private var prevFlushTime: TimeInterval?
    private var prevFuture: TimeInterval?

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return buffer.isEmpty
    }
    
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffer.count
    }
    deinit {
        Reset.removeReset(id)
    }
    public init(capacity: Int) {
        self.capacity = capacity
        self.buffer = CircularBuffer(initialCapacity: capacity)
        Reset.addReset(id,self)
    }
    
    public func addItem(_ item: Item, from: DataFrom) {

        let timeNow = Date().timeIntervalSince1970

        switch from {
        case .loop: fallthrough
        case .local:
            lock.lock()
            buffer.append((item, timeNow, from))
            lock.unlock()

        case .remote:
            let itemLag = timeNow - item.time
            nextLag = nextLag * filterLag + max(minLag, itemLag) * (1-filterLag)
            var futureTime = item.time + nextLag

            if let prevItem,
               let prevFuture {

                // preserve the duration between item events
                // but catchup on any delays
                let duration = item.time - prevItem.time
                let catchup = min(1, maxLag/itemLag)
                futureTime = max(futureTime, prevFuture + duration * catchup)
            }
            lock.lock()
            buffer.append((item, futureTime, from))
            lock.unlock()

            prevItem = item
            prevFuture = futureTime


        }

    }

    public func flushBuf() -> BufState {

        guard var delegate else { return .nextBuf }

        var state: BufState = .nextBuf
        while !buffer.isEmpty, state != .doneBuf {

            let timeNow = Date().timeIntervalSince1970

            lock.lock()
            let (item, futureTime, type) = buffer.first!
            lock.unlock()

            if futureTime > timeNow {
                return .waitBuf
            }

            state = delegate.flushItem(item, type)

            NoTimeLog("\(self.id)", interval: 0.5 ) { P("⏱️ id.state: \(self.id).\(state.description)") }

            if state == .nextBuf {
                lock.lock()
                _ = buffer.removeFirst()
                lock.unlock()
            }
        }
        return state
    }
}
extension TimedBuffer: ResetDelegate {
    public func resetAll() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()
    }
}
