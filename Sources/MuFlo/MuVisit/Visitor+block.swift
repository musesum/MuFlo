// created by musesum on 8/22/24

/// Set of blocked nodes that failed a test condition
///
/// Sometimes, a node will contain multiple values, which may be set
/// individually by other nodes and then sync with those same nodes.
/// For instance, two MIDI knobs, setting `x` and `y` position, which
/// synchronizes with a 2D `X,Y` touchpad.
///
/// For example, here is the wrong way to do it:
///
///     in.control(val)                 // twist knob X
///     >> knob.repeatX(val)            // update knob.repeatX
///        <> pad.repeat(x val)         // update repeat(x,y)
///           >> knob.repeatY(val y)    // update knob.repeatY
///              << out.contoller(val)  // update out.control
///        << out.control(🏁)           // bad, blocks repeatX
///
/// The correct way is to visit breadth-first and then add failed nodes to `blocked`
///
///     in.control(cc=1, val=11)       // twist midi knob 1 outputs 11
///     >> knob.repeatY(cc==2,⛔️)      // failed cc==2 match, so block
///     >> knob.repeatX(cc==1,val=11)  // passes cc match, so continue
///        <> pad.repeat(x val=11)     // sync with onscreen xy control
///           >> knob.repeatY(⛔️)      // block failed cc==2 eval
///        << out.control(cc=1,val=11) // send repeatX to midi out
///
/// The blocked set in wrapped in a class, so that its reference is copied.
/// This is useful for animating tweens. For MuValScalar, may set its `val` once
/// and then animated tween `twe` dozens of times. Retaining the blocked set,
/// memoizes the conditionals that failed the first time.
///

public typealias Blocked = OrderedSetClass<Int>
