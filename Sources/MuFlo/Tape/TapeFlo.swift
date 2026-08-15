// created by musesum on 1/18/26

#if !os(watchOS)
import Foundation
import MuPeers

public class TapeFlo: @unchecked Sendable {

    private var record˚: Flo?
    private var play˚  : Flo?
    private var loop˚  : Flo?
    private var learn˚ : Flo?
    private var beat˚  : Flo?
    private var panic˚ : Flo?
    private var pause˚ : Flo?

    private var playState: PlayState
    private let tapeDeck: TapeDeck

    public init(_ root˚: Flo) {
        self.playState = PlayState()
        self.tapeDeck  = TapeDeck()

        let tape = root˚.bind("tape")
        record˚ = tape.bind("record") { f,_ in update(f,.record) }
        play˚   = tape.bind("play"  ) { f,_ in update(f,.play  ) }
        loop˚   = tape.bind("loop"  ) { f,_ in update(f,.loop  ) }
        learn˚  = tape.bind("learn" ) { f,_ in update(f,.learn ) }
        beat˚   = tape.bind("beat"  ) { f,_ in update(f,.beat  ) }
        // panic is handled by PanicState (Reset.reset) — no deck side effects;
        // the old `.beat` reuse was a harmless copy while beat was a no-op,
        // but beat now sets the loop end, which panic must never do
        panic˚  = tape.bind("panic" )
        // mid-record pause: deck-local gate, outside the PlayState wire
        pause˚  = tape.bind("pause" ) { f,_ in pause(f.boolVal("x")) }

        func pause(_ on: Bool) {
            tapeDeck.setPaused(on)
        }

        func update(_ flo: Flo, _ nextState: PlayState) {

            // boolVal("x"), never `bool`: BoolVal returns the FIRST scalar in
            // dictionary order — a `menu 0` component can shadow x — and reads
            // the animated tween, which lags the write at closure time
            let on = flo.boolVal("x")
            switch nextState {
            case .record : record(on)
            case .play   : play(on)
            case .loop   : tapeDeck.loop(on)
            case .learn  : tapeDeck.learn(on)
            case .beat   : tapeDeck.beat(on)
            default      : break
            }
            playState.adjust(nextState, on)
            Task {
                await Peers.shared.setTape(on: playState.record)
            }

            func record(_ on: Bool) {
                if on {
                    // no playOff: arming while a loop runs = overdub
                    tapeDeck.recordOn()
                } else {
                    tapeDeck.recordOff()
                }
                // record edges always leave the pause leaf cleared (deck
                // setPaused(false) is idempotent on the re-fire)
                pause˚?.setNameNums([("x", 0)], .fire, Visitor(0, .model))
            }
            func play(_ on: Bool)   {
                if on {
                    tapeDeck.recordOff()
                    tapeDeck.playOn()
                } else {
                    tapeDeck.playOff ()
                }
            }
            func reset() {
                panic˚?.setExpr("x", 1)
            }
        }
    }
}
extension TapeFlo { // app seam: seed + enumerate the (private) TapeDeck at launch

    public func loadTrack(_ track: TapeTrack) { tapeDeck.loadTrack(track) }
    public var recordedTracks: [TapeTrack] { tapeDeck.recordedTracks }
    /// creation-ordered tracks: base take first, layers after
    public var orderedTracks: [TapeTrack] { tapeDeck.orderedTracks }

    /// Multi-take opt-in: recordOn keeps prior tracks instead of replacing the tape.
    public var retainTracks: Bool {
        get { tapeDeck.retainTracks }
        set { tapeDeck.retainTracks = newValue }
    }
    /// The track currently being (or just) recorded — nil before any recordOn.
    public var selfTrackId: Int? { tapeDeck.selfTrack?.trackId }
    /// Stamp the take-begin anchor (audio t=0 alignment). Pends on the deck —
    /// the host's begin hook fires BEFORE the record phase arms the deck.
    public func markBegan() { tapeDeck.markBegan() }
    /// Refine the anchor to the audio clock's exact wall zero (call at finish
    /// with `now − audioDuration`, while the recording track is still current).
    public func setBegan(_ wallT: TimeInterval) { tapeDeck.setBegan(wallT) }
    /// Scoped transport for take-associated playback (global tape.play stays play-all).
    public func playTrack(_ trackId: Int, loop: Bool? = nil) {
        tapeDeck.playTrack(trackId, loop: loop)
    }
    public func stopTrack(_ trackId: Int) { tapeDeck.stopTrack(trackId) }
    /// sequencer pinch: scale the loop window across local tracks
    public func setLoopDuration(_ seconds: TimeInterval) {
        tapeDeck.setLoopDuration(seconds)
    }
    /// current loop window in seconds; nil before any recording
    public var loopSeconds: TimeInterval? { tapeDeck.loopSeconds }
    /// live loop phase (task-keyed); nil when the transport is idle
    public var playPhase: TimeInterval? { tapeDeck.playPhase }
    /// recording a layer over a running loop
    public var isOverdubbing: Bool { tapeDeck.isOverdubbing }
    public var canUndoOverdub: Bool { tapeDeck.canUndoOverdub }
    public var canRedoOverdub: Bool { tapeDeck.canRedoOverdub }
    public func undoOverdub() { tapeDeck.undoOverdub() }
    public func redoOverdub() { tapeDeck.redoOverdub() }
    /// restart running local loops at the beginning
    public func skipToStart() { tapeDeck.skipToStart() }
}
extension TapeFlo: TapeProto {

    public func playItem(_ item: PlayItem) {

        if playState.record {

            tapeDeck.addTapeItem(item)
            //print("〄 TapeFlo::tapeItem: time: \(item.time) type: \(item.type) count: \(tapeDeck.items.count)")
        }

    }
}
#endif

