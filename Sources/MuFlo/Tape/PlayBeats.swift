// created by musesum on 2/6/26
import Foundation
public final class PlayBeats: @unchecked Sendable, Codable {

    public var beats: [TimeInterval]

    public var average: TimeInterval {
        guard let first = beats.first else { return 0 }
        let normalizedSum = beats.reduce(0) { partial, value in
            partial + (value - first)
        }
        return normalizedSum / TimeInterval(beats.count)
    }

    func bop() {
        let now = Date().timeIntervalSince1970
        beats.append(now)
    }
}

