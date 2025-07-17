
import Foundation
import NIOCore

public protocol TimedBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState
}

public protocol TimedItem: Sendable {
    var time: TimeInterval { get }
}
public typealias TimeLag = TimeInterval

public class TimedBuffer<Item: TimedItem>: @unchecked Sendable {
    private let id = Visitor.nextId()
    private var buffer: CircularBuffer<(Item, TimeLag, BufType)>
    private let capacity: Int
    private var lock = NSLock()

    public var delegate: (any TimedBufferDelegate)?
    private var futureLag: TimeInterval = 1.00 // dynamic timelag for future
    private var minimumLag: TimeInterval = 0.20 // static minimum timelag
    private var maximumLag: TimeInterval = 2.00 // stay within 2 second delay
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
        Panic.remove(id)
    }
    public init(capacity: Int, internalLoop: Bool) {
        self.capacity = capacity
        self.buffer = CircularBuffer(initialCapacity: capacity)
        Panic.add(id,self)
        if internalLoop {
            bufferLoop()
        }
    }
    
    public func addItem(_ item: Item, bufType: BufType) {
        let timeNow = Date().timeIntervalSince1970

        if bufType == .remoteBuf {
            let itemLag = timeNow - item.time
            futureLag = futureLag * filterLag + max(minimumLag, itemLag) * (1-filterLag)
            var futureTime = item.time + futureLag

            if let prevItem,
               let prevFuture {

                // preserve the duration between item events
                // but catchup on any delays
                let duration = item.time - prevItem.time
                let catchup = min(1, maximumLag/itemLag)
                futureTime = max(futureTime, prevFuture + duration * catchup)
            }
            lock.lock()
            buffer.append((item, futureTime, bufType))
            lock.unlock()

            prevItem = item
            prevFuture = futureTime

            //TimeLog(#function, interval: 2) { P("⚡ itemLag:\(itemLag.digits(3)) futureLag:\(self.futureLag.digits(3))  ")  }
        } else {
            lock.lock()
            buffer.append((item, timeNow, bufType))
            lock.unlock()
        }


    }

    public func flushBuf() -> BufState {

        guard var delegate else { return .nextBuf }

        while !buffer.isEmpty {

            let timeNow = Date().timeIntervalSince1970

            lock.lock()
            let (item, futureTime, type) = buffer.first!
            lock.unlock()

            if futureTime > timeNow {
                return .waitBuf
            }
            let state = delegate.flushItem(item, type)

            switch state {
            case .waitBuf:         return state
            case .doneBuf: pop() ; return state
            case .nextBuf: pop()
            }
            func pop() {
                lock.lock()
                _ = buffer.removeFirst()
                lock.unlock()
            }
        }
        return .nextBuf

    }

    internal func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.0005, repeats: true) { timer in
            let state = self.flushBuf()
            if state == .doneBuf {
                timer.invalidate()
            }
        }
    }
}
extension TimedBuffer: PanicReset {
    public func reset() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()
    }
}
