// created by musesum on 1/18/26

import Foundation
import MuPeers


public enum TapeClipState: String, Codable, Sendable {
    case stopped
    case recording
    case playing
    case removed
}

public struct TapeStatus: Codable, Sendable {
    public let id        : Int
    public var state     : TapeClipState
    public let playBegan : TimeInterval
    public let loop      : Bool

    init(_ tapeClip: TapeClip) {
        self.id        = tapeClip.id
        self.state     = tapeClip.state
        self.playBegan = tapeClip.playBegan
        self.loop      = tapeClip.loop
    }
    mutating func setState(_ state: TapeClipState) {
        self.state = state
    }
}

public struct TapeItem: Codable, Sendable {
    public let id        : Int
    public let typeItems : [TypeItem]
    public let duration  : TimeInterval
    public var status    : TapeStatus

    init( _ tapeClip: TapeClip) {
        self.id        = tapeClip.id
        self.typeItems = tapeClip.typeItems
        self.duration  = tapeClip.duration
        self.status    = TapeStatus(tapeClip)
    }
    mutating func makeTask() -> Task<Void, Never>? {
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [typeItems, status, duration] in

            do {
                while true {
                    while index < typeItems.count {
                        try Task.checkCancellation()
                        let timeNow = Date().timeIntervalSince1970
                        let itemNow = typeItems[index]
                        let timeDelta = fmod(timeNow - playBegan, duration)
                        let playDelta = itemNow.time - timeDelta // normalized
                        if playDelta > 0 {
                            let n = UInt64(playDelta * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                        await Peers.shared.playItem(itemNow.type, itemNow.data)
                        index += 1
                    }
                    if status.loop {
                        playBegan = Date().timeIntervalSince1970
                        index = 0
                        continue
                    } else {
                        break
                    }
                }
            } catch {
                // Cancellation or sleep error: just exit gracefully
            }
        }
    }
}

public class TapeClip: @unchecked Sendable {
    let id = Visitor.nextId()
    var typeItems = [TypeItem]()
    var tapeBegan = TimeInterval(0)
    var playBegan = TimeInterval(0)
    var duration  = TimeInterval(0)
    var loop      = true
    var state     = TapeClipState.stopped

    func add(_ item: TypeItem) {
        let timeNow = Date().timeIntervalSince1970
        if typeItems.isEmpty {
            tapeBegan = timeNow
            duration  = 0
        } else {
            duration = timeNow - tapeBegan
        }
        typeItems.append(item)
    }

    func normalizeTime() {
        guard !typeItems.isEmpty,
              let firstItem = typeItems.first
        else { return }
        let tapeBegan = firstItem.time
        for item in typeItems {
            item.normalize(tapeBegan)
        }
    }
    func setState(_ state: TapeClipState) -> Void {
        self.state = state
        Task.detached {
            await Peers.shared.sendItem(.tapeStateFrame) {
                @Sendable in try? JSONEncoder().encode(state)
            }
        }
    }

}

