// created by musesum on 7/20/26

#if !os(watchOS)
import XCTest
import Foundation
import MuPeers
@testable import MuFlo

final class TapePersistenceTests: XCTestCase {

    // temp .mu file scaffolding, local to the zip round-trip test
    private var tempURL: URL!
    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mu")
    }
    override func tearDown() {
        if let tempURL { try? FileManager.default.removeItem(at: tempURL) }
        tempURL = nil
        super.tearDown()
    }

    private func makeItem(_ type: FramerType, _ data: Data,
                          path: String, time: Double) -> PlayItem {
        let item = PlayItem(type, data, path: path)
        item.time = time
        return item
    }

    func testEnvelopeV2RoundTrip() {
        let items = [
            makeItem(.menuItem,    Data([0x01, 0x02]), path: "menu.a", time: 0.0),
            makeItem(.gestureItem, Data([0x09]),       path: "ctrl.b", time: 1.5),
            makeItem(.midiItem,    Data(),             path: "",       time: 3.0),
        ]
        let track = TapeTrack(1)
        track.playItems = items
        track.tapeBegan = 0
        track.duration  = 4.0

        guard let (envelope, sidecar) = TapeArchive.encodeTrack(track) else {
            return XCTFail("encodeTrack returned nil")
        }
        guard let out = TapeArchive.decodeTrack(envelope: envelope,
                                                sidecar: sidecar, deckId: 2) else {
            return XCTFail("decodeTrack returned nil")
        }
        XCTAssertEqual(out.playItems.count, 3)
        XCTAssertEqual(out.playItems.map(\.time), [0.0, 1.5, 3.0])
        XCTAssertEqual(out.playItems.map(\.path), ["menu.a", "ctrl.b", ""])
        XCTAssertEqual(out.playItems.map(\.type), [.menuItem, .gestureItem, .midiItem])
        XCTAssertEqual(out.playItems.map(\.data),
                       [Data([0x01, 0x02]), Data([0x09]), Data()])
        XCTAssertEqual(out.duration, 4.0)
    }

    func testV1TolerantLoad() {
        let events = [
            TapeFloEvent(t: 0.0, path: "a",
                         kind: Int(FramerType.menuItem.rawValue), blob: Data([0xAA])),
            TapeFloEvent(t: 5.0, path: "b",
                         kind: Int(FramerType.midiItem.rawValue), blob: Data([0xBB, 0xCC])),
        ]
        // matching sidecar from the shared encoder (blob framing is version-agnostic)
        guard let (_, sidecar) = TapeArchive.encode(events) else {
            return XCTFail("encode returned nil")
        }
        // hand-built v1 envelope: version:1, blobs stripped, NO duration key
        var stripped = events
        for i in stripped.indices { stripped[i].blob = nil }
        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys]
        guard let v1env = try? enc.encode(TapeArchiveEnvelope(version: 1, events: stripped)) else {
            return XCTFail("v1 encode returned nil")
        }
        XCTAssertFalse((String(data: v1env, encoding: .utf8) ?? "").contains("duration"))

        guard let track = TapeArchive.decodeTrack(envelope: v1env,
                                                  sidecar: sidecar, deckId: 7) else {
            return XCTFail("decodeTrack rejected v1")
        }
        XCTAssertEqual(track.playItems.count, 2)
        XCTAssertEqual(track.duration, 5.0)        // reconstructed max(t)
        XCTAssertEqual(track.playItems.map(\.time), [0.0, 5.0])
        XCTAssertEqual(track.playItems.map(\.data), [Data([0xAA]), Data([0xBB, 0xCC])])
    }

    func testGestureEventFidelity() {
        let g = GestureEvent(t: 2.5, controlId: "brush.tilt", phase: .moved,
                             x: 0.25, y: 0.75, velocity: 1.5,
                             extras: ["pressure": 0.5, "az": 0.25])
        guard let item = g.playItem() else { return XCTFail("playItem nil") }
        XCTAssertEqual(item.type, .gestureItem)
        XCTAssertEqual(item.path, "brush.tilt")
        XCTAssertEqual(item.time, 2.5)

        let events = TapeArchive.events(from: [item], tapeBegan: 0)
        XCTAssertEqual(events.first?.kind, Int(FramerType.gestureItem.rawValue))

        let items = TapeArchive.playItems(from: events)
        guard let item2 = items.first else { return XCTFail("no round-trip item") }
        XCTAssertEqual(item2.type, .gestureItem)
        XCTAssertEqual(item2.path, "brush.tilt")

        guard let g2 = GestureEvent(item2) else { return XCTFail("GestureEvent decode nil") }
        XCTAssertEqual(g2.phase, GesturePhase.moved.rawValue)
        XCTAssertEqual(g2.x, 0.25)
        XCTAssertEqual(g2.y, 0.75)
        XCTAssertEqual(g2.velocity, 1.5)
        XCTAssertEqual(g2.extras, ["pressure": 0.5, "az": 0.25])
        XCTAssertEqual(g2, g)
    }

    func testZipWriteReadTempFile() {
        let envData  = Data([0x01, 0x02, 0x03, 0x04])
        let sideData = Data((0..<32).map { UInt8($0) })

        guard let writeZip = ArchiveZip(tempURL, accessMode: .update) else {
            return XCTFail("could not create archive")
        }
        writeZip.addName("tape/track42", ext: "tape.json", data: envData)
        writeZip.addName("tape/track42", ext: "tape.blob", data: sideData)

        guard let readZip = ArchiveZip(tempURL, accessMode: .read) else {
            return XCTFail("could not reopen archive")
        }
        XCTAssertEqual(readZip.readFile("tape/track42.tape.json"), envData)
        XCTAssertEqual(readZip.readFile("tape/track42.tape.blob"), sideData)
    }

    func testUnknownKindMapsInvalid() {
        let events = [TapeFloEvent(t: 0, path: "x", kind: 999, blob: Data())]
        let items = TapeArchive.playItems(from: events)
        XCTAssertEqual(items.first?.type, .invalid)
    }

    func testCorruptedEnvelopeRejected() {
        let events = [TapeFloEvent(t: 0, path: "a", kind: 1, blob: Data([0x01]))]
        guard let (envelope, sidecar) = TapeArchive.encode(events) else {
            return XCTFail("encode returned nil")
        }
        // sidecar frame-count mismatch -> nil
        XCTAssertNil(TapeArchive.decodeTrack(envelope: envelope, sidecar: Data(), deckId: 1))
        // malformed envelope JSON -> nil (no crash)
        let garbage = Data([0x7B, 0x00, 0xFF])
        XCTAssertNil(TapeArchive.decodeTrack(envelope: garbage, sidecar: sidecar, deckId: 1))
    }

    func testDurationReconstructNonzero() {
        let events = [
            TapeFloEvent(t: 0, path: "a", kind: 1, blob: Data()),
            TapeFloEvent(t: 5, path: "b", kind: 1, blob: Data()),
        ]
        // encode() writes no duration key -> decodeTrack reconstructs max(t)
        guard let (envelope, sidecar) = TapeArchive.encode(events) else {
            return XCTFail("encode returned nil")
        }
        XCTAssertFalse((String(data: envelope, encoding: .utf8) ?? "").contains("duration"))
        guard let track = TapeArchive.decodeTrack(envelope: envelope,
                                                  sidecar: sidecar, deckId: 1) else {
            return XCTFail("decodeTrack returned nil")
        }
        XCTAssertEqual(track.duration, 5)          // guards fmod(x, 0) = nan
    }

    func testSeededTrackNotSelf() {
        let deck = TapeDeck()
        XCTAssertNil(deck.selfTrack)

        let track = TapeTrack(123)
        let trackId = track.playStatus.trackId
        deck.loadTrack(track)

        XCTAssertNotNil(deck.tapeTracks[trackId])   // seeded into storage
        XCTAssertNil(deck.selfTrack)                // not the record track
        XCTAssertEqual(deck.recordedTracks.count, 1)
    }
}
#endif
