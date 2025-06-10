// created by musesum on 6/10/25

import Foundation
import NIOCore

public protocol TimedBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState
}

public protocol TimedItem {
    var time: TimeInterval { get }
}

public class TimedBuffer<Item: TimedItem> {
    private var buffer: CircularBuffer<(Item, BufType)>
    private let capacity: Int
    private var lock = NSLock()
    public var delegate: (any TimedBufferDelegate)?
    public var timeLag: TimeInterval = 0.2
    
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
    
    public init(capacity: Int, internalLoop: Bool) {
        self.capacity = capacity
        self.buffer = CircularBuffer(initialCapacity: capacity)
        if internalLoop {
            bufferLoop()
        }
    }
    
    public func addItem(_ item: Item, bufType: BufType) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append((item, bufType))
    }
    
    public func flushBuf() -> BufState {
        guard var delegate else { return .nextBuf }
        
        var state: BufState = .nextBuf
        let timeNow = Date().timeIntervalSince1970
        
        lock.lock()
        defer { lock.unlock() }
        
        while !buffer.isEmpty {
            let (item, type) = buffer.first!
            
            // Apply time lag check here in flushBuf instead of flushItem
            if type == .remoteBuf {
                let itemTime = item.time + timeLag
                if timeNow < itemTime {
                    // Not ready yet, keep the item and wait
                    return .waitBuf
                }
            }
            
            lock.unlock()
            state = delegate.flushItem(item, type)
            lock.lock()
            
            switch state {
            case .doneBuf, .nextBuf:
                _ = buffer.removeFirst()
            case .waitBuf:
                return state // Stop processing remaining items
            }
        }
        return state
    }
    
    internal func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let state = self.flushBuf()
            if state == .doneBuf {
                timer.invalidate()
            }
        }
    }
}