// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeTrack: @unchecked Sendable, Codable  {

    var playStatus : PlayStatus
    var playItems  : [PlayItem]
    var tapeBegan = TimeInterval(0)
    var playBegan = TimeInterval(0)
    var duration  = TimeInterval(0)

    init(_ deckId: Int) {
        self.playStatus = PlayStatus(deckId)
        self.playItems  = []
    }
    var script: String {
       playStatus.script + " items: \(playItems.count)"
    }
    var Script: String {
        "TapeTrack   " + script
    }

    func reset() {
        for playItem in playItems {
            Peers.shared.resetItem(playItem)
        }
    }
    func addTrack(_ item: PlayItem) {

        let timeNow = Date().timeIntervalSince1970
        if playItems.isEmpty {
            tapeBegan = timeNow
            duration  = 0
        } else {
            duration = timeNow - tapeBegan
        }
        playItems.append(item)
    }
    func stopTrack() {
        PrintLog("✇✇ stopTrack")
        if playStatus.playState.record {
            let timeNow = Date().timeIntervalSince1970
            duration = timeNow - tapeBegan
        }
    }

    func normalizeTime() {
        guard let tapeBegan = playItems.first?.time,
              tapeBegan != 0
        else { return }
        for item in playItems {
            item.normalize(tapeBegan)
        }
    }
    func setState(_ nextState: PlayState) -> Void {
        let oldState = playStatus.playState
        playStatus.playState.setOn(nextState)
        PrintLog("✇ setState \(oldState.description) -> \(playStatus.playState.description)")
    }
}
extension TapeTrack { // task

    func makePlayTask(_ from: DataFrom) -> Task<Void, Never>? {
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [playItems, duration, weak self] in
            do {
                PrintLog("🔄 task \(self?.playStatus.script ?? "")")
                while index < playItems.count {
                    try Task.checkCancellation()
                    let timeNow = Date().timeIntervalSince1970
                    let playItem = playItems[index]
                    let timeDelta = fmod(timeNow - playBegan, duration)
                    try await sleep(playItem.time - timeDelta) // normalized

                    index += 1
                    let isEnding = index == playItems.count
                    if isEnding {
                        self?.updatePlayStatus(.ending, on: true)
                    }
                    // dispatch playItem via Peers head
                    if let playState = self?.playStatus.playState {
                        Peers.shared.playItem(playState, playItem, from)
                    }
                    // duration may extend past last event
                    if isEnding {
                        let finalDelta = duration - timeDelta
                        PrintLog("🔄 task \(self?.playStatus.script ?? "") finalDelta: \(finalDelta.digits(2))")
                        try await sleep(finalDelta)
                        if self?.playStatus.playState.loop ?? false {
                            self?.updatePlayStatus(.play, on: true)
                            PrintLog("🔄 task \(self?.playStatus.script ?? "")")
                            playBegan = Date().timeIntervalSince1970
                            index = 0
                            continue
                        } else {
                            self?.updatePlayStatus(.play, on: false)
                        }
                    }
                    func sleep(_ duration: TimeInterval) async throws {
                        if duration > 0 {
                            let n = UInt64(duration * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                    }
                }
            } catch {
                // Cancellation or sleep error: just exit gracefully
            }
        }
    }
    public func updatePlayStatus(_ state: PlayState, on: Bool) {
        playStatus.updateState(state, on: on)
        PrintLog("✇ updatePlayStatus \(playStatus.Script)")
        Task.detached {
            await Peers.shared.sendItem(.playStatus) { @Sendable in
                try? JSONEncoder().encode(self.playStatus)
            }
        }
    }
}

