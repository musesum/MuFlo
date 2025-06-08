// created by musesum on 5/31/25

import Foundation
import NIOCore

public enum BufType {
    case localBuf
    case remoteBuf
}

public enum BufState {
    case doneBuf
    case nextBuf
    case waitBuf
}

public protocol CircleBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState
}

public class CircleBuffer<Item> {
    private var buffer: CircularBuffer<(Item, BufType)>
    private let capacity: Int
    private var lock = NSLock()
    public var delegate: (any CircleBufferDelegate)?
    
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
        
        lock.lock()
        defer { lock.unlock() }
        
        while !buffer.isEmpty {

            let (item, type) = buffer.first!
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
