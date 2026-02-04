// created by musesum on 1/18/26

import Foundation
import MuPeers

public struct TapeStatus: Codable, Sendable {
    let deckId  : Int
    let trackId : Int
    let state   : TapeState

    init(_ track: TapeTrack) {
        self.deckId  = track.deckId
        self.trackId = track.trackId
        self.state   = track.state
    }
}

public class TapeTrack: @unchecked Sendable, Codable {
    let deckId    : Int
    let trackId   : Int
    var typeItems : [TypeItem]
    var state     : TapeState

    var tapeBegan = TimeInterval(0)
    var playBegan = TimeInterval(0)
    var duration  = TimeInterval(0)

    init(_ deckId: Int) {
        self.deckId  = deckId
        self.typeItems = []
        self.trackId = UUID().uuidString.hashValue
        self.state  = TapeState([.loop,.stop])
        Peers.shared.addDelegate(self, for: .trackFrame)
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
        if state.record {
            let timeNow = Date().timeIntervalSince1970
            duration = timeNow - tapeBegan
        }
    }

    func normalizeTime() {
        guard let tapeBegan = typeItems.first?.time,
              tapeBegan != 0
        else { return }
        for item in typeItems {
            item.normalize(tapeBegan)
        }
    }
    func setState(_ nextState: TapeState) -> Void {
        let oldState = state
        state.setOn(nextState)
        print("✇ setState \(oldState.description) -> \(state.description)")
        shareItem(self)
    }
}
extension TapeTrack { // task

    func makeTask() -> Task<Void, Never>? {
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [typeItems, state, duration] in

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
                        Peers.shared.playItem(itemNow)
                        index += 1
                        // duration may extend past last event
                        if index == typeItems.count {
                            let finalDelta = duration - timeDelta - playDelta
                            if finalDelta > 0 {
                                let n = UInt64(finalDelta * 1_000_000_000)
                                try await Task.sleep(nanoseconds: n)
                            }
                        }
                    }
                    if state.loop {
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

extension TapeTrack: PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        let decoder = JSONDecoder()
        if let status = try? decoder.decode(TapeStatus.self, from: data) {
            self.state = status.state
            print("✇ shareItem TapeStatus deckId:\(status.deckId) trackId: \(status.trackId)")
            if from != .remote {
                shareItem(status)
            }
        }
    }
    public func shareItem(_ any: Any) {
        if let status = any as? TapeStatus {
            Task.detached {
                print("✇ share TapeStatus deckId:\(status.deckId) trackId: \(status.trackId)")
                await Peers.shared.sendItem(.trackFrame) { @Sendable in
                    try? JSONEncoder().encode(status)

                }
            }
        }

    }
}
