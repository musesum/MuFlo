// created by musesum on 8/12/25

import Foundation
import MuPeers

public struct TapeState: OptionSet, Sendable {
    
    static let record = TapeState(rawValue: 1 << 0)
    static let play   = TapeState(rawValue: 1 << 1)
    static let loop   = TapeState(rawValue: 1 << 2)
    static let learn  = TapeState(rawValue: 1 << 3)
    static let beat   = TapeState(rawValue: 1 << 4)

    public var rawValue: UInt8
    public init(rawValue: UInt8 = 0) { self.rawValue = rawValue }
    var record : Bool { contains(.record) }
    var play   : Bool { contains(.play  ) }
    var loop   : Bool { contains(.loop  ) }
    var learn  : Bool { contains(.learn ) }
    var beat   : Bool { contains(.beat  ) }

    func hasAny(_ value: TapeState) -> Bool {
        !self.intersection(value).isEmpty
    }
    func has(_ value: TapeState) -> Bool {
        self.contains(value)
    }

    mutating func adjust(_ on: Bool,_ nextState: TapeState) {
        if on {
            self.insert(nextState)
        } else {
            self = self.subtracting(nextState)
        }
    }
}

public struct TapePlay: Sendable {
    public let items: [MirrorItem]
    public let recBegan: TimeInterval
    public let duration: TimeInterval
    public let peers: Peers?

    public init(_ items     : [MirrorItem],
                _ duration  : TimeInterval,
                _ peers     : Peers?) {
        self.items     = items
        self.recBegan  = items.first?.time ?? 0
        self.duration  = duration
        self.peers     = peers
    }

    public func startPlayback(loop: Bool) -> Task<Void, Never> {
        guard !items.isEmpty else { return Task { } }
        var playBegan = Date().timeIntervalSince1970
        var index = 0

        return Task { [items, recBegan, peers] in
            do {
                while true {
                    while index < items.count {
                        try Task.checkCancellation()

                        let item = items[index]
                        let itemDelta = item.time - recBegan
                        let timeNow = Date().timeIntervalSince1970
                        let timeDelta = timeNow - playBegan

                        let remaining = itemDelta - timeDelta
                        if remaining > 0 {
                            let n = UInt64(remaining * 1_000_000_000)
                            try await Task.sleep(nanoseconds: n)
                        }
                        peers?.playback(item.type, item.data)
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

public class TapeDeck {

    var items    : [MirrorItem] = []
    var duration : TimeInterval = 0
    var peers    : Peers?

    // Playback control
    private var playbackTask: Task<Void, Never>?
    private var loop = false
    private var learn = false

    public func snapshot() -> TapePlay {
        return TapePlay( items, duration, peers)
    }

    func add(_ item: MirrorItem) {
        items.append(item)
    }
    func record(_ on: Bool) {
        let timeNow = Date().timeIntervalSince1970
        if on {
            duration = 0
        } else if let timeRec = items.first?.time {
            // user tapped record to stop, so set duration
            duration = timeNow - timeRec
        }
    }
    func play(_ on: Bool) {
        if on {
            startPlayback(loop)
        } else {
            stopPlayback()
        }
    }

    func loop(_ on: Bool) {
        self.loop = on
    }
    func learn(_ on: Bool) {
        self.learn = on
    }
    func beat(_ on: Bool) {
    }

    private func startPlayback(_ loop: Bool) {
        guard !items.isEmpty else { return }
        stopPlayback() // cancel any existing task
        playbackTask = snapshot().startPlayback(loop: loop)
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
    }
}

public class TapeFlo: @unchecked Sendable, MirrorSink {

    private var record˚: Flo?
    private var play˚  : Flo?
    private var loop˚  : Flo?
    private var learn˚ : Flo?
    private var beat˚  : Flo?

    private var state = TapeState()
    private var deck = TapeDeck()
    private var peers: Peers?

    public init() {}

    public func setPeers(_ peers: Peers) {
        self.peers = peers
        deck.peers = peers
    }
    public func update(_ root˚: Flo) {

        let tape = root˚.bind("tape")
        record˚ = tape.bind("record") { f,_ in update(f,.record) }
        play˚   = tape.bind("play"  ) { f,_ in update(f,.play  ) }
        loop˚   = tape.bind("loop"  ) { f,_ in update(f,.loop  ) }
        learn˚  = tape.bind("learn" ) { f,_ in update(f,.learn ) }
        beat˚   = tape.bind("beat"  ) { f,_ in update(f,.beat  ) }

        func update(_ flo: Flo, _ nextState: TapeState) {

            let on = flo.bool
            switch nextState {
            case .record : deck.record(on)
            case .play   : deck.play(on)
            case .loop   : deck.loop(on)
            case .learn  : deck.learn(on)
            case .beat   : deck.beat (on)
            default      : break
            }
            state.adjust(on, nextState)
            Task { await peers?.setMirror(on: state.record) }
        }
    }

    public func reflect(_ item: MirrorItem) {

        if state.record {
            deck.add(item)
        }
        print("TapeFlo::reflect: time: \(item.time) type: \(item.type) count: \(item.data.count)")
    }
    
}

