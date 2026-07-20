// created by musesum on 7/12/26

#if !os(watchOS)
import XCTest
import Foundation
import MuPeers
@testable import MuFlo

final class TapeArchiveTests: XCTestCase {

    func testPlayItemFloEventRoundTrip() {
        // MIDI 2.0 UMP-shaped bytes must survive verbatim through the codec + sidecar.
        let ump = Data([0x40, 0x91, 0x3C, 0x00, 0xFF, 0xFF, 0x00, 0x00])
        let original = [
            TapeFloEvent(t: 0.0, path: "menu.brush.size",
                         kind: Int(FramerType.menuItem.rawValue), blob: ump),
            TapeFloEvent(t: 3.2, path: "",
                         kind: Int(FramerType.midiItem.rawValue), blob: Data([0x01, 0x02]))
        ]

        // PlayItem <-> FloEvent
        let items = TapeArchive.playItems(from: original)
        XCTAssertEqual(items.map(\.path), ["menu.brush.size", ""])
        XCTAssertEqual(items.map(\.data), [ump, Data([0x01, 0x02])])
        XCTAssertEqual(items.map { Int($0.type.rawValue) },
                       [Int(FramerType.menuItem.rawValue), Int(FramerType.midiItem.rawValue)])
        let back = TapeArchive.events(from: items, tapeBegan: 0)
        XCTAssertEqual(back, original)

        // JSON envelope + length-prefixed blob sidecar
        guard let (envelope, sidecar) = TapeArchive.encode(original) else {
            return XCTFail("encode returned nil")
        }
        guard let decoded = TapeArchive.decode(envelope: envelope, sidecar: sidecar) else {
            return XCTFail("decode returned nil")
        }
        XCTAssertEqual(decoded, original)
    }

    func testDecodeRejectsSidecarMismatch() {
        let events = [TapeFloEvent(t: 0, path: "a", kind: 1, blob: Data([0x01]))]
        guard let (envelope, _) = TapeArchive.encode(events) else {
            return XCTFail("encode returned nil")
        }
        XCTAssertNil(TapeArchive.decode(envelope: envelope, sidecar: Data()))
    }

    func testTapeBeganMakesTimeRelative() {
        let items = TapeArchive.playItems(from: [
            TapeFloEvent(t: 100.0, path: "a", kind: 1, blob: Data())
        ])
        let rel = TapeArchive.events(from: items, tapeBegan: 100.0)
        XCTAssertEqual(rel.first?.t, 0.0)
    }
}
#endif
