//  created by musesum on 12/16/22.

import Foundation

public protocol DoubleBufferDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item) -> Bool
}

public class DoubleBuffer<Item> {

    private var buf0 = [Item]()
    private var buf1 = [Item]()
    private var bufs: [[Item]]
    private var indexNow = 0
    private var timer: Timer?
    private var lock = NSLock()

    public var delegate: (any DoubleBufferDelegate)?

    public var isEmpty: Bool {
        bufs[indexNow].isEmpty
    }

    /// canvas manages loop from metal frame callback
    public init(internalLoop: Bool) {
        self.bufs = [buf0,buf1]
        if internalLoop {
            self.bufferLoop()
        }
    }
    deinit {
        timer?.invalidate()
    }

    public func flushBuf() -> Bool {
        guard var delegate else { return false }

        lock.lock()
        
        guard bufs[indexNow].count > 0 else {
            lock.unlock()
            return false
        }

        let indexFlush = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1   // flip double buffer
        var isDone = false
        for item in bufs[indexFlush] {
            isDone = isDone || delegate.flushItem(item) // isDone
        }
        bufs[indexFlush].removeAll()
        
        lock.unlock()

        return isDone
    }

    public func append(_ item: Item) {
        lock.lock()
        bufs[indexNow].append(item)
        lock.unlock()
    }

    func bufferLoop() {

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let isDone = self.flushBuf()
            if isDone {
                timer.invalidate()
            }
        }
    }
}
