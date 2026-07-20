// created by musesum on 7/12/26

#if !os(watchOS)
import Foundation
import MuPeers

/// Local seam mirroring `MuAuthorTimeline.FloEvent`. MuFlo resolves its dependencies from
/// remote git and MuAuthor has no remote, so importing `MuAuthorTimeline` here would add a
/// new remote/registry dependency — forbidden. The codec maps `PlayItem` through this local
/// protocol instead; an app that imports both packages bridges the two conforming types.
public protocol FloEventProto {
    var t: Double { get }
    var path: String { get }
    var kind: Int { get }
    var blob: Data? { get }
    var value: Double? { get }
    var str: String? { get }
}

/// Concrete local `FloEvent` used for on-disk serialization.
public struct TapeFloEvent: FloEventProto, Codable, Equatable, Sendable {
    public var t: Double
    public var path: String
    public var kind: Int
    public var blob: Data?
    public var value: Double?
    public var str: String?

    public init(t: Double,
                path: String,
                kind: Int,
                blob: Data? = nil,
                value: Double? = nil,
                str: String? = nil) {
        self.t = t
        self.path = path
        self.kind = kind
        self.blob = blob
        self.value = value
        self.str = str
    }
}

/// Versioned JSON envelope of blob-free events; blobs live in the length-prefixed sidecar.
public struct TapeArchiveEnvelope: Codable, Sendable {
    public static let currentVersion = 1
    public var version: Int
    public var events: [TapeFloEvent]
    public init(version: Int = TapeArchiveEnvelope.currentVersion,
                events: [TapeFloEvent]) {
        self.version = version
        self.events = events
    }
}

public enum TapeArchive {

    // MARK: - PlayItem <-> FloEvent

    /// `[PlayItem] -> [TapeFloEvent]`: `path` from `PlayItem.path`, `kind` from
    /// `FramerType.rawValue`, `blob` from `PlayItem.data`, `t` relative to `tapeBegan`.
    public static func events(from items: [PlayItem],
                              tapeBegan: TimeInterval) -> [TapeFloEvent] {
        items.map { item in
            TapeFloEvent(t: item.time - tapeBegan,
                         path: item.path,
                         kind: Int(item.type.rawValue),
                         blob: item.data)
        }
    }

    /// `[TapeFloEvent] -> [PlayItem]`: inverse mapping. `t` is written back to `PlayItem.time`
    /// as-is (already relative). An unknown `kind` maps to `FramerType.invalid`.
    public static func playItems(from events: [TapeFloEvent]) -> [PlayItem] {
        events.map { e in
            let type = UInt32(exactly: e.kind).flatMap { FramerType(rawValue: $0) } ?? .invalid
            let item = PlayItem(type, e.blob ?? Data(), path: e.path)
            item.time = e.t
            return item
        }
    }

    // MARK: - JSON envelope + length-prefixed blob sidecar

    /// Split events into a blob-free JSON envelope and a length-prefixed binary sidecar.
    /// Every event contributes exactly one sidecar frame (empty when it has no blob), so the
    /// two files stay index-aligned. MIDI 2.0 UMP payloads pass through the sidecar untouched.
    public static func encode(_ events: [TapeFloEvent]) -> (envelope: Data, sidecar: Data)? {
        var stripped = events
        var blobs: [Data] = []
        for i in stripped.indices {
            blobs.append(stripped[i].blob ?? Data())
            stripped[i].blob = nil
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        guard let envelope = try? enc.encode(TapeArchiveEnvelope(events: stripped)) else {
            return nil
        }
        return (envelope, blobSidecarEncode(blobs))
    }

    /// Rejoin a JSON envelope with its blob sidecar, reattaching each frame to its event by
    /// index. Returns nil on envelope/sidecar mismatch (frame count != event count).
    public static func decode(envelope: Data, sidecar: Data) -> [TapeFloEvent]? {
        guard let env = try? JSONDecoder().decode(TapeArchiveEnvelope.self, from: envelope),
              let blobs = blobSidecarDecode(sidecar),
              blobs.count == env.events.count
        else { return nil }
        var events = env.events
        for i in events.indices {
            events[i].blob = blobs[i].isEmpty ? nil : blobs[i]
        }
        return events
    }

    // MARK: - Length-prefixed blob framing (local; MuAuthorTimeline.BlobSidecar not importable)

    static func blobSidecarEncode(_ blobs: [Data]) -> Data {
        var out = Data()
        for blob in blobs {
            var len = UInt32(blob.count).bigEndian
            withUnsafeBytes(of: &len) { out.append(contentsOf: $0) }
            out.append(blob)
        }
        return out
    }

    static func blobSidecarDecode(_ data: Data) -> [Data]? {
        var blobs: [Data] = []
        var i = data.startIndex
        while i < data.endIndex {
            guard data.distance(from: i, to: data.endIndex) >= 4 else { return nil }
            var len: UInt32 = 0
            for _ in 0..<4 {
                len = (len << 8) | UInt32(data[i])
                i = data.index(after: i)
            }
            let n = Int(len)
            guard data.distance(from: i, to: data.endIndex) >= n else { return nil }
            let end = data.index(i, offsetBy: n)
            blobs.append(Data(data[i..<end]))
            i = end
        }
        return blobs
    }

    // MARK: - Find-only Flo resolution (recall path)

    /// Resolve event paths against a live Flo graph using `findPath_` ONLY. `bind`/`makePath`
    /// are forbidden on recall (they fabricate orphan nodes / mutate the graph). Unresolved or
    /// empty paths are omitted so the caller can surface an explicit "not on screen" state.
    public static func resolve(_ events: [TapeFloEvent], root: Flo) -> [(TapeFloEvent, Flo)] {
        events.compactMap { e in
            guard !e.path.isEmpty, let flo = root.findPath_(e.path) else { return nil }
            return (e, flo)
        }
    }
}
#endif
