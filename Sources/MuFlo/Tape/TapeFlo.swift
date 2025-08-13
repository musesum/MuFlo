// created by musesum on 8/12/25

class TapeFlo {
    private var rec˚   : Flo? ; var rec   = false
    private var play˚  : Flo? ; var play  = false
    private var stop˚  : Flo? ; var stop  = false
    private var forw˚  : Flo? ; var forw  = false
    private var loop˚  : Flo? ; var loop  = false
    private var learn˚ : Flo? ; var learn = false

    init(_ root˚: Flo) {
        let tape = root˚.bind("tape")
        rec˚   = tape.bind("rec")   { f,_ in self.rec   = f.bool }
        play˚  = tape.bind("play")  { f,_ in self.play  = f.bool }
        stop˚  = tape.bind("stop")  { f,_ in self.stop  = f.bool }
        forw˚  = tape.bind("forw")  { f,_ in self.forw  = f.bool }
        loop˚  = tape.bind("loop")  { f,_ in self.loop  = f.bool }
        learn˚ = tape.bind("learn") { f,_ in self.learn = f.bool }
    }
}
