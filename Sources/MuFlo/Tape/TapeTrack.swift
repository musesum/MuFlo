// created by musesum on 1/18/26

import Foundation
import MuPeers

extension Int {
    var script5: String {
        "…"+String(String(self).suffix(5))
    }
}

public struct TrackStatus: Codable, Sendable {
    let deckId     : Int
    let trackId    : Int
    var trackState : TrackState

    init(_ deckId: Int) {
        self.deckId     = deckId
        self.trackId    = UUID().uuidString.hashValue
        self.trackState = TrackState([.loop,.stop])
    }
    var script: String {
        "deckId: \(deckId.script5) trackId: \(trackId.script5) state: \(trackState.description))"
    }
    var Script: String {
        "TrackStatus " + script
    }
    mutating func setState(_ newState: TrackState) {
        trackState = newState
    }

}

public class TapeTrack: @unchecked Sendable, Codable  {

    var trackStatus : TrackStatus
    var typeItems  : [TypeItem]
    var tapeBegan = TimeInterval(0)
    var playBegan = TimeInterval(0)
    var duration  = TimeInterval(0)

    init(_ deckId: Int) {
        self.trackStatus = TrackStatus(deckId)
        self.typeItems  = []
    }
    var script: String {
       trackStatus.script + " items: \(typeItems.count)"
    }
    var Script: String {
        "TapeTrack   " + script
    }

    func addTrack(_ item: TypeItem) {

        let timeNow = Date().timeIntervalSince1970
        if typeItems.isEmpty {
            tapeBegan = timeNow
            duration  = 0
        } else {
            duration = timeNow - tapeBegan
        }
        typeItems.append(item)
    }
    func stopTrack() {
        PrintLog("✇✇ stopTrack")
        if trackStatus.trackState.record {
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
    func setState(_ nextState: TrackState) -> Void {
        let oldState = trackStatus.trackState
        trackStatus.trackState.setOn(nextState)
        PrintLog("✇ setState \(oldState.description) -> \(trackStatus.trackState.description)")
    }
}
extension TapeTrack { // task

    func makePlayTask(_ from: DataFrom) -> Task<Void, Never>? {
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [typeItems, trackStatus, duration] in
            do {
                PrintLog("✇ task \(trackStatus.script) raw: \(trackStatus.trackState.rawValue)")
                while index < typeItems.count {
                    try Task.checkCancellation()
                    let timeNow = Date().timeIntervalSince1970
                    let typeItem = typeItems[index]
                    let timeDelta = fmod(timeNow - playBegan, duration)
                    let playDelta = typeItem.time - timeDelta // normalized
                    if playDelta > 0 {
                        let n = UInt64(playDelta * 1_000_000_000)
                        try await Task.sleep(nanoseconds: n)
                    }
                    Peers.shared.playItem(trackStatus.trackState.rawValue, typeItem, from)
                    index += 1
                    // duration may extend past last event
                    if index == typeItems.count {
                        let finalDelta = duration - timeDelta - playDelta
                        if finalDelta > 0 {
                            let n = UInt64(finalDelta * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                        if trackStatus.trackState.loop {
                            playBegan = Date().timeIntervalSince1970
                            index = 0
                            continue
                        } else {
                            break
                        }
                    }
                }
            } catch {
                // Cancellation or sleep error: just exit gracefully
            }
        }
    }
}

