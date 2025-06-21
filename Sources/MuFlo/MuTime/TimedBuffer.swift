// created by musesum on 6/10/25

/*
 TimedBuffer - A time-aware circular buffer that preserves timing relationships between items
 
 ## Overview
 TimedBuffer extends CircleBuffer functionality by ensuring that remote items maintain their
 original timing relationships, even when network interruptions cause packets to arrive in bursts.
 
 ## Key Features
 
 1. **Timing Preservation**: Items emitted together (with similar timestamps) are rendered together.
    Items that were far apart in time are spaced out according to their original time delta.
 
 2. **Dynamic Catch-Up**: The system gradually catches up to real-time without jarring jumps:
    - Normal operation: Items render at 90% of original timing (configurable via catchUpRate)
    - High backlog: Automatically speeds up to 50% timing when backlog exceeds maxBacklog
    - Smooth transitions maintain natural rhythm of touch strokes
 
 3. **Auto-Adjusting Lag**: When enabled, the system adapts to changing network conditions:
    - Gradually adjusts timeLag using weighted average (90% old + 10% new)
    - Resets when lag becomes negative or backlog is excessive
    - Prevents unrealistic timing accumulation
 
 4. **Backlog Prevention**: Monitors the difference between current time and item timestamps:
    - maxBacklog (default 0.4s = 2x packet delay) triggers aggressive catch-up
    - Prevents infinite delay accumulation during network interruptions
 
 ## Example Scenario
 - Items A and B are emitted 200ms apart but arrive simultaneously due to network delay
 - TimedBuffer ensures they're rendered ~180ms apart (200ms × 0.9 catchUpRate)
 - If backlog exceeds maxBacklog, spacing reduces more aggressively to catch up
 
 ## Configuration
 - timeLag: Base delay for remote items (default 0.2s)
 - catchUpRate: Normal playback speed ratio (default 0.9 = 90%)
 - maxBacklog: Maximum allowed delay before aggressive catch-up (default 0.4s)
 - autoAdjustLag: Enable/disable automatic lag adjustment
 
 ## Implementation Notes
 - First remote item establishes baseline delay for the session
 - Timing state resets when sequence completes (doneBuf)
 - Logs provide visibility into catch-up behavior and lag adjustments
 - Some initial jitter may occur when multiple devices sync initially
 */

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
    
    // Auto-adjust timing properties
    private var lastItemTime: TimeInterval? // Last item's original timestamp
    private var lastRealTime: TimeInterval? // When we actually processed it
    public var catchUpRate: Double = 0.9 // Render at 90% of original timing to catch up
    public var autoAdjustLag: Bool = false
    private var baselineDelay: TimeInterval? // Initial delay when first item arrives
    public var maxBacklog: TimeInterval = 0.4 // Maximum allowed backlog (2x packet delay)
    private var sessionStartTime: TimeInterval? // Track when current session started
    
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
        let timeNow = Date().timeIntervalSince1970
        
        lock.lock()
        defer { lock.unlock() }
        
        while !buffer.isEmpty {
            let (item, type) = buffer.first!
            
            if type == .remoteBuf {
                if !shouldRender(item: item, type: type, timeNow: timeNow) {
                    return .waitBuf
                }
                updateTimingState(item: item, timeNow: timeNow)
                if autoAdjustLag {
                    let currentDelay = timeNow - item.time
                    adjustTimeLag(currentDelay: currentDelay, currentBacklog: currentDelay)
                }
            }
            
            lock.unlock()
            let state = delegate.flushItem(item, type)
            lock.lock()
            
            if state != .waitBuf {
                _ = buffer.removeFirst()
            }
            if state == .doneBuf {
                resetSession()
                return state
            }
        }
        return .nextBuf
    }
    
    // MARK: - Private Helpers
    
    /// Decide if the item should be rendered now based on timing logic
    private func shouldRender(item: Item, type: BufType, timeNow: TimeInterval) -> Bool {
        if type != .remoteBuf { return true }
        let targetTime = calculateTargetRenderTime(for: item, type: type, timeNow: timeNow)
        return timeNow >= targetTime
    }
    
    /// Update internal timing state after processing an item
    private func updateTimingState(item: Item, timeNow: TimeInterval) {
        lastItemTime = item.time
        lastRealTime = timeNow
    }
    
    /// Adjust the timeLag dynamically to adapt to network conditions
    private func adjustTimeLag(currentDelay: TimeInterval, currentBacklog: TimeInterval) {
        if timeLag < 0 || currentBacklog > maxBacklog {
            timeLag = max(0.05, currentDelay)
            TimeLog(#function, interval: 4) {
                P("🔄 Reset timeLag to \(self.timeLag.digits(3))s (backlog: \(currentBacklog.digits(3))s)")
            }
        } else {
            timeLag = timeLag * 0.9 + currentDelay * 0.1
        }
    }
    
    /// Calculate the target time when the item should be rendered
    private func calculateTargetRenderTime(for item: Item, type: BufType, timeNow: TimeInterval) -> TimeInterval {
        guard type == .remoteBuf else { return timeNow }
        
        // Establish baseline delay if first remote item
        if baselineDelay == nil {
            baselineDelay = timeNow - item.time
            timeLag = baselineDelay ?? 0.2
            sessionStartTime = timeNow
            TimeLog(#function, interval: 4) {
                P("⏱️ timeLag: \(self.timeLag.digits(3))")
            }
        }
        
        let currentBacklog = timeNow - item.time
        
        if let lastItemTime, let lastRealTime {
            let originalDelta = item.time - lastItemTime
            var dynamicCatchUpRate = catchUpRate
            if currentBacklog > maxBacklog {
                dynamicCatchUpRate = min(0.5, catchUpRate * (maxBacklog / currentBacklog))
                TimeLog(#function, interval: 4) {
                    P("⚡ Backlog: \(currentBacklog.digits(3))s, catch-up: \(dynamicCatchUpRate.digits(2))")
                }
            }
            let adjustedDelta = originalDelta * dynamicCatchUpRate
            return lastRealTime + adjustedDelta
        } else {
            return item.time + timeLag
        }
    }
    
    /// Reset timing state for a new session
    private func resetSession() {
        lastItemTime = nil
        lastRealTime = nil
        baselineDelay = nil
        sessionStartTime = nil
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
