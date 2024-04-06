// created by musesum on 2/1/24

import Foundation

open class MuLog {
    
    static var timeStart = TimeInterval(0)
    static var prevTime = [String: TimeInterval]()
    

    /// stub out logging
    public static func debug(_ body: @escaping()->()) {
#if DEBUG
        body()
#endif
    }


    /// stub out logging
    public static func NoLog(_ label: String,
                             interval: TimeInterval,
                             terminator: String = "\n",
                             _ body: @escaping()->()) {
    }
    
    /// log during runtime
    public static func RunLog(_ label: String,
                              interval: TimeInterval = -1,
                              terminator: String = "\n",
                              _ body: (()->())? = nil) {

        let timeNow = Date().timeIntervalSince1970
        if MuLog.timeStart == 0 {
            MuLog.timeStart = timeNow
        }
        let timeDelta = timeNow - timeStart
        let timePrev = prevTime[label] ?? .zero
        if timeNow - timePrev > interval {
            prevTime[label] = timeNow
            print("\(timeDelta.digits(2)): \(label)", terminator: terminator)
            body?()
        }
    }
    /// log when debug
    public static func Log(_ label: String,
                           interval: TimeInterval,
                           terminator: String = "\n",
                           _ body: @escaping()->()) {
        
#if DEBUG
        RunLog(label, interval: interval, terminator: terminator, body)
#endif
    }
}
