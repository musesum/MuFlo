// created by musesum on 2/1/24

import Foundation

public class MuLog {
    
    static var logStart = TimeInterval(0)
    static var prevTime = [String: TimeInterval]()
    
    /// return elapsed time from first first Log
    static func timeElapsed() -> TimeInterval {
        
        let timeNow = Date().timeIntervalSince1970
        if logStart == 0 { logStart = timeNow }
        return timeNow - logStart // starts from first log
    }
    
    /// log during runtime
    public static func TimeLog(_ key: String,
                               interval: TimeInterval = 0,
                               _ body: (()->())?) {
        
        let elapsedTime = timeElapsed()
        
        // next time
        if let timePrev = prevTime[key] {
            let timeDelta = elapsedTime - timePrev
            if timeDelta > interval {
                print("\(elapsedTime.digits(2)): ", terminator: "")
                body?()
                prevTime[key] = elapsedTime
            }
        } else {
            print("\(elapsedTime.digits(2)): ", terminator: "")
            body?()
            prevTime[key] = elapsedTime
        }
    }
    
    /// log when debug
    public static func PrintLog(_ title: String) {
        print("\(timeElapsed().digits(2)): \(title)")
    }
}

/// log when debug
public func TimeLog(_ key: String,
                    interval: TimeInterval = 0,
                    _ body: (()->())?) {
    
#if DEBUG
    MuLog.TimeLog(key, interval: interval, body)
#endif
}

/// log when debug
public func PrintLog(_ title: String? = nil, _ body: (()->())? = nil) {
    if let title {
        MuLog.PrintLog(title)
    } else if let body {
        MuLog.TimeLog("PrintLog", interval: 0, body)
    }
}

/// log when debugging
public func DebugLog(_ body: (()->())?) {
#if DEBUG
    MuLog.TimeLog("Debug", interval: 0, body)
#endif
}
/// log when debugging
public func NoDebugLog(_ body: (()->())?) {
    // nothing to see here -- move along
}

/// Stub out TimeLog
public func NoTimeLog(_ key: String,
                      interval: TimeInterval = 0,
                      _ body: (()->())?) {
    
    // nothing to see here -- move along
}

/// shorten print statement, limited to string
public func P(_ msg: String, terminator: String = "\n") {
    print(msg, terminator: terminator)
}
