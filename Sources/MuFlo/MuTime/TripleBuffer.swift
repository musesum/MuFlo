// created by musesum on 5/31/25

import Foundation

import Foundation

public protocol TripleBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item) -> Bool
}

public class TripleBuffer<Item> {
    private var buffers: [[Item]] = [[], [], []]
    private var currentIndex = 0
    private var lock = NSLock()
    public var delegate: (any TripleBufferDelegate)?

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return buffers[currentIndex].isEmpty
    }

    public init(internalLoop: Bool = false) {
        if internalLoop {
            bufferLoop()
        }
    }

    public func append(_ item: Item) {
        lock.lock()
        buffers[currentIndex].append(item)
        lock.unlock()
    }

    public func flushBuf() -> Bool {
        guard var delegate else { return false }

        lock.lock()
        let flushIndex = currentIndex
        currentIndex = (currentIndex + 1) % 3
        let itemsToFlush = buffers[flushIndex]
        buffers[flushIndex] = []
        lock.unlock()

        var isDone = false
        for item in itemsToFlush {
            isDone = isDone || delegate.flushItem(item)
        }
        return isDone
    }

    private func bufferLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let isDone = self.flushBuf()
            if isDone {
                timer.invalidate()
            }
        }
    }
}
