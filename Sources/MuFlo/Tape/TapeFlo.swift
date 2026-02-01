// created by musesum on 1/18/26

import Foundation
import MuPeers

public class TapeFlo: @unchecked Sendable, TapeProto {

    private var record˚: Flo?
    private var play˚  : Flo?
    private var loop˚  : Flo?
    private var learn˚ : Flo?
    private var beat˚  : Flo?
    private var panic˚ : Flo?

    private var tapeState: TapeState
    private let tapeDeck: TapeDeck

    public init(_ root˚: Flo) {
        self.tapeState = TapeState()
        self.tapeDeck  = TapeDeck()

        let tape = root˚.bind("tape")
        record˚ = tape.bind("record") { f,_ in update(f,.record) }
        play˚   = tape.bind("play"  ) { f,_ in update(f,.play  ) }
        loop˚   = tape.bind("loop"  ) { f,_ in update(f,.loop  ) }
        learn˚  = tape.bind("learn" ) { f,_ in update(f,.learn ) }
        beat˚   = tape.bind("beat"  ) { f,_ in update(f,.beat  ) }
        panic˚  = tape.bind("panic" ) { f,_ in update(f,.beat  ) }

        func update(_ flo: Flo, _ nextState: TapeState) {

            let on = flo.bool
            switch nextState {
            case .record : record(on)
            case .play   : play(on)
            case .loop   : tapeDeck.loop(on)
            case .learn  : tapeDeck.learn(on)
            case .beat   : tapeDeck.beat(on)
            default      : break
            }
            tapeState.adjust(nextState, on)
            Task {
                await Peers.shared.setTape(on: tapeState.record)
            }

            func record(_ on: Bool) {
                if on {
                    tapeDeck.play (false)
                    tapeDeck.record(true)
                } else {
                    tapeDeck.record(false)
                }
            }
            func play(_ on: Bool)   {
                if on {
                    tapeDeck.record(false)
                    tapeDeck.play (true)
                } else {
                    tapeDeck.play (false)
                }
            }
            func reset() {
                panic˚?.setExpr("x", 1)
            }
        }
    }

    public func typeItem(_ item: TypeItem) {

        if tapeState.record {

            tapeDeck.addTapeItem(item)
            //print("〄 TapeFlo::tapeItem: time: \(item.time) type: \(item.type) count: \(tapeDeck.items.count)")
        }

    }
    
}
