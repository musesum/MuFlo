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

public class TapeDeck {

    var items     : [MirrorItem] = []
    var recBegan  : TimeInterval = 0
    var duration  : TimeInterval = 0
    var playBegan : TimeInterval = 0
    var timer     : Timer?
    var peers     : Peers?

    func add(_ item: MirrorItem) {
        if items.isEmpty {
            recBegan = item.time
        }
        items.append(item)
    }
    func record(_ on: Bool) {
        let timeNow = Date().timeIntervalSinceReferenceDate
        if on {
            recBegan = timeNow
            duration = 0
        } else {
            // user tapped record to stop, so set duration
            duration = timeNow - recBegan
        }
    }
    func play(_ on: Bool) {
        let timeNow = Date().timeIntervalSinceReferenceDate
        if on, !items.isEmpty {
            if duration.isZero {
                duration = timeNow - recBegan
            }
            playBegan = timeNow

            timer.flush


        } else {
            timer?.invalidate()
        }
    }
    func loop(_ on: Bool) {
    }
    func learn(_ on: Bool) {
    }
    func beat(_ on: Bool) {
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
            case .loop   : deck.loop (on)
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
