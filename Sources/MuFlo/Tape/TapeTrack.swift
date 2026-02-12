// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeTrack: @unchecked Sendable, Codable {

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

    func normalizeTime() {
        guard let tapeBegan = playItems.first?.time,
              tapeBegan != 0
        else { return }
        for item in playItems {
            item.normalize(tapeBegan)
        }
    }
    func setState_(_ nextState: PlayState) -> Void {
        let oldState = playStatus.playState
        playStatus.playState.setOn(nextState)
        if oldState.record, !playStatus.playState.record {
            duration = Date().timeIntervalSince1970 - tapeBegan
            PrintLog("🔄 setState duration: \(duration)")
        }
        PrintLog("🔄 setState \(oldState.description) -> \(playStatus.playState.description)")
    }
}
extension TapeTrack { // task

    func makePlayTask(_ from: DataFrom) -> Task<Void, Never>? {
        var playBegan = Date().timeIntervalSince1970
        var index = 0
        PrintLog("🔄 makePlayTask \(playStatus.deckId.script5) .\(from.icon) 🟢")
        return Task { [playItems, duration, weak self] in
            guard let self else { return }
            do {
                while index < playItems.count {

                    // wait to play nextItem
                    try Task.checkCancellation()
                    let timeNow = Date().timeIntervalSince1970
                    let timeDelta = fmod(timeNow - playBegan, duration)
                    let playItem = playItems[index]
                    try await sleep(playItem.time - timeDelta) // normalized

                    Peers.shared.playItem(playStatus.playState, playItem, from)

                    index += 1
                    // last item may wait to complete duration
                    if index == playItems.count {
                        updateStatus(.ending, on: true, from: from)

                        let finalDelta = duration - timeDelta
                        PrintLog("🔄 playTask status \(playStatus.script) .\(from.icon) pause: \(finalDelta.digits(2))")
                        try await sleep(finalDelta)

                        if playStatus.playState.loop {
                            updateStatus(.play, on: true, from: from)

                            playBegan = Date().timeIntervalSince1970
                            index = 0
                            continue
                        } else {
                            updateStatus(.stop, on: true, from: from)
                        }
                    }
                    func sleep(_ duration: TimeInterval) async throws {
                        if duration > 0 {
                            let n = UInt64(duration * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                    }
                }
            } catch is CancellationError {
                // Explicit cancellation handling: log and update status
                PrintLog("🔴 playTask cancelled .\(from.icon)")
                Task.detached { [weak self] in
                    guard let self else { return }
                    self.updateStatus(.stop, on: true, from: from)
                }
            } catch {
                // Handle other errors if needed
                PrintLog("⚠️ playTask error: \(error)")
            }
        }
    }
    public func updateStatus(_ state: PlayState, on: Bool, from: DataFrom) {

        let oldRecord = playStatus.playState.record
        playStatus.updateState(state, on: on)
        let newRecord = playStatus.playState.record

        // complete recording duration?
        if oldRecord, !newRecord {
            let timeNow = Date().timeIntervalSince1970
            duration = timeNow - tapeBegan
        }
        PrintLog("🔄 update status   \(playStatus.script) .\(from.icon)")
        if from == .local {
            Task.detached {
                await Peers.shared.sendItem(.playStatus) { @Sendable in
                    try? JSONEncoder().encode(self.playStatus)
                }
            }
        }
    }
}

