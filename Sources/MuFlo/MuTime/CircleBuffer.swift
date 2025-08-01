// created by musesum on 5/31/25

import Foundation
import NIOCore

public enum BufType {
    case localBuf
    case remoteBuf
}

public enum BufState {
    case nextBuf
    case waitBuf
    case doneBuf
    
    var description: String {
        switch self {
        case .nextBuf : return "nextBuf"
        case .waitBuf : return "waitBuf"
        case .doneBuf : return "doneBuf"
        }
    }
}
@MainActor
public protocol CircleBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState
}
@MainActor
public class CircleBuffer<Item> {
    let id = Visitor.nextId()
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
        lock.lock()
        defer { lock.unlock() }
        buffer.append((item, bufType))
    }
    
    public func flushBuf() -> BufState {
        guard var delegate else { return .nextBuf }

        lock.lock()
        defer { lock.unlock() }
        
        while !buffer.isEmpty {
            let (item, type) = buffer.first!
            _ = delegate.flushItem(item, type)
            _ = buffer.removeFirst()
        }
        return .doneBuf
    }
    
    internal func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            Task { @MainActor in
                _ = self.flushBuf()
            }
        }
    }
}
extension CircleBuffer: @MainActor PanicReset {
    public func reset() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()
    }
}
