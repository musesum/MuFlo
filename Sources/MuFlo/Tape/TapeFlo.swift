// created by musesum on 8/12/25

import Foundation
import MuPeers
public struct TapeOpt: OptionSet, Sendable {
    
    static let rec   = TapeOpt(rawValue: 1 << 0)
    static let play  = TapeOpt(rawValue: 1 << 1)
    static let stop  = TapeOpt(rawValue: 1 << 2)
    static let forw  = TapeOpt(rawValue: 1 << 3)
    static let loop  = TapeOpt(rawValue: 1 << 4)
    static let learn = TapeOpt(rawValue: 1 << 5)
    
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    
    var rec   : Bool { contains(.rec  ) }
    var play  : Bool { contains(.play ) }
    var stop  : Bool { contains(.stop ) }
    var forw  : Bool { contains(.forw ) }
    var loop  : Bool { contains(.loop ) }
    var learn : Bool { contains(.learn) }
    
    func hasAny(_ value: TapeOpt) -> Bool {
        !self.intersection(value).isEmpty
    }
    func has(_ value: TapeOpt) -> Bool {
        self.contains(value)
    }
    
}

public class TapeFlo: @unchecked Sendable, MirrorSink {
    private var rec˚   : Flo?
    private var play˚  : Flo?
    private var stop˚  : Flo?
    private var forw˚  : Flo?
    private var loop˚  : Flo?
    private var learn˚ : Flo?
    
    private var tapeOpt: TapeOpt = []
    
    public var source  : MirrorSource?
    
    public init() {}
    
    public func update(_ root˚: Flo) {
        let tape = root˚.bind("tape")
        rec˚   = tape.bind("rec"  ) { f,v in update(f,.rec  ) }
        play˚  = tape.bind("play" ) { f,v in update(f,.play ) }
        stop˚  = tape.bind("stop" ) { f,v in update(f,.stop ) }
        forw˚  = tape.bind("forw" ) { f,v in update(f,.forw ) }
        loop˚  = tape.bind("loop" ) { f,v in update(f,.loop ) }
        learn˚ = tape.bind("learn") { f,v in update(f,.learn) }
        
        func update(_ flo:Flo,_ opt: TapeOpt) {
            let on = flo.bool
            switch opt {
            case .rec   : tapeOpt = on ? .rec : .stop
            case .play  : tapeOpt = on ? .play : .stop
            case .stop  : tapeOpt = on ? .stop : tapeOpt
            case .forw  : tapeOpt = on ? .play : tapeOpt
            case .loop  : tapeOpt = on ? .loop : tapeOpt
            case .learn : tapeOpt = on ? .learn : tapeOpt
            default: break
            }
            Task { await source?.setMirror(on: tapeOpt.rec) } }
    }
    
    public func reflect(_ framerType: FramerType,_ data: Data) {
        print("TapeFlo.reflect: \(framerType.description) \(data.count)")
    }
    
}
