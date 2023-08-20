
# Visiting Flo Breadth is better then Depth

A flo graph of repeating tiles:

```c
model.canvas.tile.repeat (x -1…1~0, y -1…1~0)
>> (midi.cc.skypad.repeatX(val x)
    midi.cc.skypad.repeatY(val y))
^ sky.main.anim⚡️

midi {
    cc.skypad.repeatX (cc==14, val 0_127)
    <> model.canvas.tile.repeat(x val)
    
    cc.skypad.repeatY (cc==14, val 0_127)
    <> model.canvas.tile.repeat(Y val)
    
    input.controller >> cc.skypad˚.
    output.controller << cc.skypad˚.
}
shader {
    compute.tile.repeat  (x -1…1~0, y -1…1~0)
    render.flatmap.repeat(x -1…1~0, y -1…1~0)
}
```



## depth first is bad, unpredictable


Notice how:
    skypad.repeatX changs only x in tile.repeat(x,y)
    skypad.repeatY changs only y in tile.repeat(x,y)

Given that tile.repeat <> syncs with output.controller
it could potentially block repeatX from updating output.controller:


```c
/// with ending at prior visits (🏁) is bad

0 input.controller(val)
1     >> skypad.repeatX(val)
2         <> tile.repeat(x val)
3             >> skypad.repeatY(val y)
4                 << output.contoller(val)
2         << ouput.controller(🏁) // bad
```

Although, sometimes it may work correctly

```c
0 input.controller(val)
1     >> skypad.repeatX(val)
2         << ouput.controller(val) // good, but may fail later
2         <> tile.repeat(x val)
3             >> skypad.repeatY(val y)
4                 << output.contoller(🏁)
```

## breadth first with blocking ⛔️ is good

However, we can fix breadth first visits and blocking failed tests.isEmpty

So, when we twist a knob for repeatX

```c
/// twist knob 1 to 11

0  input.controller(cc=1, val=11)             // twist midi knob 1 outputs 11
1      >> skypad.repeatY(cc==2,⛔️)            // failed cc==2 match, so block ⛔️
1      >> skypad.repeatX(cc==1, val=11)       // passes cc match, so continue
2          <> tile.repeat(x val=11)           // sync with onscreen xy control
3              >> skypad.repeatY(⛔️)          // block failed cc==2 eval
2          << ouput.controller(cc=1, val=11)  // send repeatX to midi output
```

and when we twist a know for repeatY

```c
/// twist knob 2 to 22

0  input.controller(cc=2,val=22)              // twist midi knob 2 outputs 22
1      >> skypad.repeatX(cc==1,⛔️)            // failed cc==1 match, so block ⛔️
1      >> skypad.repeatY(cc==2, val=22)       // passes cc==2 match, so continue
2          << ouput.controller(cc=2, val=22)  // send repeatY to midi output
2          <> tile.repeat(y val=22)           // sync with onscreen xy control
3              >> skypad.repeatX(⛔️)          // block failed cc==1 eval
```

/// start by initial value for `tile.repeat(x=0, y=0)`
/// which has a plugin `^ sky.main.anim`, which has 10 tweens
/// show no tweens as `val=11/11` and with tweens as `x=-0.328⚡️-0.039`

/// twisting a midi.input cc knob will NOT animate tweens to midi.output cc
/// but changing a tile.repeat(x,y) WILL animatate tweens to midi.output cc
```c
/// twist knob 1

0 input.controller(cc=1, val=11)
1     >> skypad.repeatY(cc==2,⛔️)                   // failed knob 2 test so block
1     >> skypad.repeatX(cc==1, val=11)              // passes knob 1 test so continue
2         <> tile.repeat(x=-0.328⚡️-0.039, y=0⚡️0)  // map 0_127 to -1…1, with 1st ⚡️
3             >> skypad.repeatY(⛔️)                 // is in blocked visit, so ignore
2         << ouput.controller(cc=1, val=11/11)      // no ⚡️s yet, so no animation

/// twist knob 2

1 input.controller(cc=2, val=22)
2     >> skypad.repeatX(cc==1,⛔️)                  // failed knob 1 test so block
2     >> skypad.repeatY(cc==2, val=22)             // passes knob 2 test so continue
3         << ouput.controller(cc==2, val=22/22)    // no ⚡️s yet, so no animatin
3         <> tile.repeat⚡️(x=0, y=-1.56⚡️-0.16)    //
4             >> skypad.repeatX(⛔️)                // is in blocked visit, so ignore

/// change xy controller

1 tile.repeat⚡️(x=0.3,  y=0.6)
2     >> skypad.repeatX(cc=1, val=19.2⚡️1.92)       // map -1…1 to 0_127 with 1st ⚡️
3         << ouput.controller(cc==1, val=19⚡️2)     // pass along to output controller
3         <> tile.repeat(🏁)                        // already visited self
2     >> skypad.repeatY(CC=2, val=0.6⚡️0)           // val y
3         << ouput.controller(cc==1, val=38⚡️4)     // map 0_127 to -1…1 with 1st ⚡️
3         <> tile.repeat(🏁) // visited

__________________________________________________________

// call stacks

flo˚.setAny(["name",value])
MuLeaf::syncVal { node.modelFlo.setAny(expanded, .activate, visit) }
TouchDraw::updateRadius { azimuth˚?.setAny(cgPoint, .activate, visit) }

Flo::setAny
    fromExprs,exprs
    ? exprs.setFromAny(fromExprs, visit)🔷
    : let exprs
      ? exprs.setFromAny(any, visit)🔷
      : exprs = FloExprs(self,...)
    🚦activate
        closures(self,visit)
        folowEdges ⬦⃣

⬦⃣ FloEdge::followEdge
    setEdgeVal(destFlo)
    ? activate(destFlo)🚦
    : visit.block(destFlo)

🔷FloExprs:setFromAny
    newTweens
    ? setValues
      ? setPlugins
         ? -> true
         : -> false
    : -> setValues

⬦⃣ Flo::setEdgeVal
    exprs
    ? edgeExprs
      ? edgeExprs.evalExprs(fromExprs)🔸
        -> exprs.setFromAny(edgeExprs)🔷
       : fromExprs
         ? -> exprs.setFromAny(fromExprs)🔷
    : edgeExprs
      ? edgeExprs.evalExprs(fromExprs)🔸
        exprs = edgeExprs
      : fromExprs
        ? exprs = fromExprs
     -> true

FloPlugin:: setTween
    flo.exprs.nameAny.values<scalar> twe += delta
    flo.activate🚦

MuNodeVm::maybeTapLeaf()
    leafVm.modelFlo.activate(visit)🚦
__________________________________________________________

