// created by musesum on 5/31/25

import Foundation
import NIOCore

public enum BufferType {
    case local
    case remote
}

public enum FlushState {
    case done
    case `continue`
    case wait
}

public protocol CircleBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ type: BufferType) -> FlushState
}

public class CircleBuffer<Item> {
    private var buffer: CircularBuffer<(Item, BufferType)>
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
    
    public func addItem(_ item: Item, bufferType: BufferType) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append((item, bufferType))
    }
    
    public func flushBuf() -> FlushState {
        guard var delegate else { return .continue }
        
        var state: FlushState = .continue
        
        lock.lock()
        defer { lock.unlock() }
        
        while !buffer.isEmpty {

            let (item, type) = buffer.first!
            lock.unlock()
            state = delegate.flushItem(item, type)
            lock.lock()
            
            switch state {
            case .done, .continue:
                _ = buffer.removeFirst()
            case .wait:
                return state // Stop processing remaining items
            }
        }
        return state
    }
    
    internal func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let state = self.flushBuf()
            if state == .done {
                timer.invalidate()
            }
        }
    }
}
