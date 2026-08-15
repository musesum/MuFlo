// created by musesum on 8/10/26

#if !os(watchOS)
import XCTest
import Foundation
import MuPeers
@testable import MuFlo

final class TapeTrackLoopTests: XCTestCase {

    /// pre-loopDuration payloads (old peers, old archives) must decode with nil
    func testDecodesLegacyTrackWithoutLoopDuration() throws {
        let track = TapeTrack(1)
        let legacy = try JSONEncoder().encode(track) // nil optional → key absent
        XCTAssertFalse(String(data: legacy, encoding: .utf8)!.contains("loopDuration"))
        let decoded = try JSONDecoder().decode(TapeTrack.self, from: legacy)
        XCTAssertNil(decoded.loopDuration)
    }

    func testLoopDurationRoundTrips() throws {
        let track = TapeTrack(1)
        track.loopDuration = 2.5
        let data = try JSONEncoder().encode(track)
        let decoded = try JSONDecoder().decode(TapeTrack.self, from: data)
        XCTAssertEqual(decoded.loopDuration, 2.5)
    }

    func testPlayDurationPrefersLoopOverride() {
        let track = TapeTrack(1)
        track.duration = 10
        XCTAssertEqual(track.playDuration, 10)
        track.loopDuration = 4
        XCTAssertEqual(track.playDuration, 4)
        track.loopDuration = 0 // degenerate override ignored
        XCTAssertEqual(track.playDuration, 10)
    }
}
#endif
