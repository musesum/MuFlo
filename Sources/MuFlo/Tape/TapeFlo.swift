// created by musesum on 8/12/25

import Foundation
import MuPeers

public class TapeFlo: @unchecked Sendable, MirrorDelegate {
    private let rec˚   : Flo? ; private var rec   = false
    private let play˚  : Flo? ; private var play  = false
    private let stop˚  : Flo? ; private var stop  = false
    private let forw˚  : Flo? ; private var forw  = false
    private let loop˚  : Flo? ; private var loop  = false
    private let learn˚ : Flo? ; private var learn = false

    public init(_ root˚: Flo) {
        let tape = root˚.bind("tape")
        rec˚   = tape.bind("rec")
        play˚  = tape.bind("play")
        stop˚  = tape.bind("stop")
        forw˚  = tape.bind("forw")
        loop˚  = tape.bind("loop")
        learn˚ = tape.bind("learn")

        rec˚?.addClosure { f,v in self.rec   (f,v) }
        play˚?.addClosure { f,v in self.play  (f,v) }
        stop˚?.addClosure { f,v in self.stop  (f,v) }
        forw˚?.addClosure { f,v in self.forw  (f,v) }
        loop˚?.addClosure { f,v in self.loop  (f,v) }
        learn˚?.addClosure { f,v in self.learn (f,v) }

    }

    func rec   (_ flo: Flo, _ visit: Visitor) { rec   = flo.bool }
    func play  (_ flo: Flo, _ visit: Visitor) { play  = flo.bool }
    func stop  (_ flo: Flo, _ visit: Visitor) { stop  = flo.bool }
    func forw  (_ flo: Flo, _ visit: Visitor) { forw  = flo.bool }
    func loop  (_ flo: Flo, _ visit: Visitor) { loop  = flo.bool }
    func learn (_ flo: Flo, _ visit: Visitor) { learn = flo.bool }

    public func mirror(_ framerType: FramerType,_ data: Data) {

    }

}
