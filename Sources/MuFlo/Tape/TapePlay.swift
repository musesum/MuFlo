// created by musesum on 1/18/26

import Foundation
import MuPeers

public struct TapePlay: Sendable {

    let tapeItems : [TapeItem]
    let tapeBegan : TimeInterval
    let duration  : TimeInterval

    public init(_ mirrorItems : [TapeItem],
                _ duration    : TimeInterval) {
        
        self.tapeItems = mirrorItems
        self.tapeBegan = mirrorItems.first?.time ?? 0
        self.duration  = duration
    }

    public func startPlayback(loop: Bool) -> Task<Void, Never> {
        guard !tapeItems.isEmpty else { return Task { } }
        return makeTask(loop: loop)
    }

    private func makeTask(loop: Bool) -> Task<Void, Never> {
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [tapeItems, tapeBegan] in
            do {
                while true {
                    while index < tapeItems.count {
                        try Task.checkCancellation()
                        let timeNow = Date().timeIntervalSince1970
                        let itemNow = tapeItems[index]
                        let itemDelta = itemNow.time - tapeBegan
                        let playDelta = timeNow - playBegan

                        let remainDelta = itemDelta - playDelta
                        if remainDelta > 0 {
                            let n = UInt64(remainDelta * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                        await Peers.shared.playback(itemNow.type, itemNow.data)
                        index += 1
                    }
                    if loop {
                        index = 0
                        playBegan = Date().timeIntervalSince1970
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
