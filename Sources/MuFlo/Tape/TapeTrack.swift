// created by musesum on 1/18/26

import Foundation
import MuPeers

public struct TapeStatus: Codable, Sendable {
    public let trackId    : Int
    public var state     : TapeState
    public let playBegan : TimeInterval
    public let loop      : Bool

    init(_ tapeTrack: TapeTrack) {
        self.trackId    = tapeTrack.trackId
        self.state     = tapeTrack.state
        self.playBegan = tapeTrack.playBegan
        self.loop      = tapeTrack.loop
    }
    mutating func setState(_ state: TapeState) {
        self.state = state
    }
}

public struct TapeItem: Codable, Sendable {
    public let deckId    : Int
    public let trackId    : Int
    public let typeItems : [TypeItem]
    public let duration  : TimeInterval
    public var status    : TapeStatus

    init( _ tapeTrack: TapeTrack) {
        self.deckId    = tapeTrack.deckId
        self.trackId    = tapeTrack.trackId
        self.typeItems = tapeTrack.typeItems
        self.duration  = tapeTrack.duration
        self.status    = TapeStatus(tapeTrack)
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
                        Peers.shared.playItem(itemNow.type, itemNow.data)
                        index += 1
                        // duration may extend past last event 
                        if index == typeItems.count {
                            let finalDelta = duration - timeDelta
                            if finalDelta > 0 {
                                let n = UInt64(finalDelta * 1_000_000_000)
                                try await Task.sleep(nanoseconds: n)
                            }
                        }
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

public class TapeTrack: @unchecked Sendable {
    let deckId    : Int
    let trackId    : Int
    var typeItems = [TypeItem]()
    var tapeBegan = TimeInterval(0)
    var playBegan = TimeInterval(0)
    var duration  = TimeInterval(0)
    var loop      = true
    var state     = TapeState.stop

    init(_ deckId: Int) {
        self.deckId = deckId
        self.trackId = UUID().uuidString.hashValue
    }
    init (_ item: TapeItem) {
        self.deckId    = item.deckId
        self.trackId    = item.trackId
        self.typeItems = item.typeItems
        self.tapeBegan = item.duration
        self.playBegan = item.duration
        self.duration  = item.duration
        self.loop      = true
        self.state     = .stop
    }

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
    func stop() {
        if state == .record {
            let timeNow = Date().timeIntervalSince1970
            duration = timeNow - tapeBegan
        }
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
    func setState(_ nextState: TapeState) -> Void {
        state.setOn(nextState)
        shareItem(TapeItem(self))
    }
    func receiveItem(_ item: TapeItem, from: DataFrom) {
        self.typeItems = item.typeItems
        self.tapeBegan = item.duration
        self.playBegan = item.duration
        self.duration  = item.duration
        self.loop      = true
        self.state     = .stop
    }
}

extension TapeTrack: PeersDelegate {

    public func received(data: Data, from: DataFrom) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(TapeItem.self, from: data) {
            receiveItem(item, from: from)

        }
    }
    public func shareItem(_ item: Any) {
        guard let item = item as? TapeItem else { return }
        Task.detached {
            await Peers.shared.sendItem(.tapeFrame) { @Sendable in
                try? JSONEncoder().encode(item)
            }
        }
    }
}
