import UIKit
import QuartzCore

public protocol NextFrameDelegate {
    func goFrame() -> Bool
    func cancel(_ key: Int)
}

public class NextFrame {
    private var lock = NSLock()
    private var preferredFps = 60
    private var displayLink: CADisplayLink!
    private var delegates = [Int: NextFrameDelegate]()

    public var betweenFrames = [(() -> Void)?]()
    public var fps: TimeInterval { TimeInterval(preferredFps) }
    public var pause = false
    public var interval: CFTimeInterval = 0

    public init() {
        displayLink = CADisplayLink(target: self, selector: #selector(nextFrame))
        displayLink.preferredFramesPerSecond = preferredFps
        displayLink.add(to: RunLoop.current, forMode: .common)
    }

    public func updateFps(_ newFps: Int?) {
        if let newFps,
           preferredFps != newFps {
            preferredFps = newFps
            displayLink.preferredFramesPerSecond = preferredFps
        }
    }

    public func addFrameDelegate(_ key: Int,
                                 _ delegate: NextFrameDelegate) {
        lock.lock()
        delegates[key] = delegate
        lock.unlock()
    }
    public func removeDelegate(_ key: Int) {
        lock.lock()
        delegates.removeValue(forKey: key)
        lock.unlock()
    }
    public func addBetweenFrame(_ closure: @escaping () -> Void) {
        lock.lock()
        betweenFrames.append(closure)
        lock.unlock()
    }

    private func goBetweenFrames() {
        if betweenFrames.count > 0 {
            //DebugLog { P("🧭 before") }
            for betweenFrame in betweenFrames {
                betweenFrame?()
            }
            //DebugLog { P("🧭 after") }
            betweenFrames.removeAll()
        }
    }
    @objc public func nextFrame(force: Bool = false) -> Bool  {
        if !force && pause { return false }

        self.interval = displayLink.targetTimestamp - displayLink.timestamp

        goBetweenFrames()
        for (key,delegate) in delegates {
            if delegate.goFrame() == false {
                removeDelegate(key)
            }
        }
        return true
    }
}
