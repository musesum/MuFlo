// created by musesum on 5/31/25

#if !os(watchOS)
import Foundation
import NIOCore
import MuPeers // DataFrom

public enum BufState {
    case nextBuf
    case waitBuf
    case doneBuf
    
    public var description: String {
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
    mutating func flushItem<Item>(_ item: Item, _ from: DataFrom) -> BufState
}
@MainActor
public class CircleBuffer<Item> {
    let id = Visitor.nextId()
    private var buffer: CircularBuffer<(Item, DataFrom)>
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

    public init() {
        self.buffer = CircularBuffer(initialCapacity: 3)
        Reset.addReset(id,self)
        bufferLoop()
    }

    public func addItem(_ item: Item, from: DataFrom) {
        lock.lock(); defer { lock.unlock() }
        buffer.append((item, from))
    }
    
    public func flushBuf() -> BufState {
        guard var delegate else { return .nextBuf }

        // take the item under the lock, hand it over outside: the callback
        // reaches menus, trees, flo and peers, and any path from there back to
        // `addItem` or `resetAll` re-entered this non-recursive lock and stuck
        while true {
            lock.lock()
            guard let (item, type) = buffer.first else {
                lock.unlock()
                return .doneBuf
            }
            _ = buffer.removeFirst()
            lock.unlock()

            _ = delegate.flushItem(item, type)
        }
    }
    
    internal func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            Task { @MainActor in
                _ = self.flushBuf()
            }
        }
    }
}
extension CircleBuffer: @MainActor ResetDelegate {
    public func resetAll() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()
    }
}
#endif
