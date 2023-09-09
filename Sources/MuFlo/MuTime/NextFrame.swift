import UIKit
import QuartzCore

public protocol NextFrameDelegate {
    func nextFrame() -> Bool
    func cancel(_ key: Int)
}

public class NextFrame {

    public static let shared = NextFrame()
    public var fps: TimeInterval { TimeInterval(preferredFps) }
    public var pause = false
    
    private var lock = NSLock()
    private var preferredFps = 60
    private var link: CADisplayLink?
    private var delegates = [Int: NextFrameDelegate]()


    public init() {
        link = CADisplayLink(target: self, selector: #selector(nextFrames))
        link?.preferredFramesPerSecond = preferredFps
        link?.add(to: RunLoop.current, forMode: .default)
    }

    public func updateFps(_ newFps: Int?) {
        if let newFps,
           preferredFps != newFps {
            preferredFps = newFps
            link?.preferredFramesPerSecond = preferredFps
        }
    }

    public func addFrameDelegate(_ key: Int,
                                 _ delegate: NextFrameDelegate) {
        lock.lock()
        delegates[key] = delegate
        lock.unlock()
        print("􀿏[\(key)]🔰")
    }
    public func removeDelegate(_ key: Int) {
        lock.lock()
        delegates.removeValue(forKey: key)
        lock.unlock()
        print("􀿏[\(key)]🔺")
    }

    @objc func nextFrames() -> Bool  {
        guard !pause else { return false }
        for (key,delegate) in delegates {
            if delegate.nextFrame() == false {
                removeDelegate(key)
            }
        }
        return true
    }
}
