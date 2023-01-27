
# MuFlo /micro flow/

Flo is a data flow graph with the following features:

- **Node** with names, values, edges, and closures
- **Edges** with inputs, outputs, and switches
- **Values** which transform, as it flows through a graph

## Goals

- Realtime coordination between devices 
- Human readable declarative data flow 
- Play nice with syntax highlighting and code folding
- Minimal use of parsing cruft, like semicommas, and commas
- Synchronize state while managing circular references
- Explore live patching without crashing or infinite loops 
- Concise expression of hand pose for menu navigation 
- Concise expression of body pose for avatars and robots
- Synchronize amorphous devices 

## Nodes

Each node has two kinds of edges: tree and graph. The tree allows each node to be addressed by name and its relationship within a group. The graph allows each node to activate each other based on inputs and outputs. 

### Tree

Each node has a single parent with any number of children. 

```c
a { b c } // a has 2 children: b & c 
          // b & c have 1 parent and no children
```
Declaring a path will auto create a tree of names
```c
a.b.c // produces the structure `a { b { c } }`
```
A tree can be decorated with sub trees
```c
a {b c}.{d e} // produces `a { b { d e } c { d e } }`
```
A tree can copy the contents of another tree with a `: name`
```c
a {b c}.{d e} // produces `a { b { d e } c { d e } }`
z: a          // produces `z { b { d e } c { d e } }`
```
### Graph

Each node may have any number of input and output edges, which attach to other nodes. A node can activate 
- other nodes when its value changes as outputs( `>>` ) or 
- itself when another node's value changs as inputs (`<<`), or
- synchronize both nodes as both input and ouput `<>`).

```c
b >> c // b flows to c, akin to a function call
d << e // d flows from e, akin to a callback
f <> g // f & g flow between each other, akin to sync
```

#### Loops

Flo allows cyclic graphs which auto break activation loops. When a node is activated, it sends an event to its output edges. The event contains a shared set of places that the event has visited. When it encounters a node that it has visited before, it stops. 

```c
a >> b // if a activates, it will activate b
b >> c // which, in turn, activates c
c >> a // and finally, c stops here
```
So, no infinite loops.

####  Activate anywhere

So, in the above `a`, `b`, `c` example, the activation could start anywhere:
```c
a! activates b! activates c! // starts at a, stops at c
b! activates c! activates a! // starts at b, stops at a
c! activates a! activates b! // starts at c, stops at b
```
This is a simple way to synchronize a model. Akin to how a co-pilot's wheel synchronizes in a cockpit.

### Closures

Swift source code may attach a closure to a Flo node, which gets executed whenever a that node is activated. 

Given the flo script snippet:
```c
sky { draw { brush { size << midi.modulationWheel } } }
```
write a closure in Swift to capture a changed value
```swift
brush.findPath("sky.draw.brush.size")?.addClosure { flo, _ in 
        self.brushRadius = flo.CGFloatVal() ?? 1 } 
```
In the above example, attach a closure to `sky.draw.brush.size`, which then updates its internal value `brushRadius`.

## Values

Each node may have a value of: scalar, expression, string, or embedded script
```c
a (1)              // scalar with an initial value of 1
b (0…1)            // scalar that ranges between 0 and 1
c (0…127 = 1)      // scalar betwwn 0 and 127, defaulting to 1
d "yo"             // a string value "yo"
e (x 0…1, y 0…1)   // an expression (see below)
```
Flo automatically remaps scalar ranges, given the nodes `b` & `c`
```c 
b (0…1)        // range 0 to 1, defaults to 0
c (0…127 = 1)  // range 0 to 127, with initial value of 1
b <> c         // synchronize b and c and auto-remap values
```
When the value of `b` is changed to `0.5` it activates `c` and remaps its value to `63`;
When the value of `c` is changed to `31`, it activates  `b` and remapts its value to `0.25`

A common case are sensors, which have a fixed range of values. For example,  a 3G (gravity) accelerometer  may have a range from `-3.0` to `3.0` 
```c 
accelerometer (x -3.0…3.0, y -3.0…3.0, z -3.0…3.0) >> model
model (x -1…1, y -1…1, z -1…1) // auto rescale
```
### Nodes may pass through values
```c
a (0…1) >> b  // may pass along value to b
b >> c        // has no value, will forward a to c
c (0…10)      // gets a's value via b, remaps ranges
```
### Graph's inputs and ouputs may contain values

Activations values can be passed as either inputs, outputs, or syncs

```c
a >> b(1) // an activated a (or a!) sends 1 to b
b << c(2) // an activated c (or c!) sends 2 to a
d <> e(3) // d! sends a 3, while c! does nothing
f >> g(0…1 = 0) // f! sends a ranged 0 to g
h << i(0…1 = 1) // i! sends a ranged 1 to h
```
Sending a ranged value to receiver will remap values, which can become a convenient way to set `min`, `mid`, or `max` values 

```c
j(10…20) << k(0…1 = 0)   // k! maps j to 10 (min)
m(10…20) << n(0…1 = 0.5) // n! maps m to 15 (mid)
p(10…20) << q(0…1 = 1)   // q! maps p to 20 (max)
```
### Connect by Name
In addition to copying a tree, a new tree can connect edges by name
```c
a {b c}.{d e}
x@a <@ a // input from a˚˚
y@a @> a // output to a˚˚
z@a <@> a // synchronize with a˚˚
```
which expands to
```c
a { b { d e } c { d e } }
x << a { b << a.b { d << a.b.d, e << a.b.e } 
         c << a.c { d << a.c.e, e << a.c.e } }
y >> a { b >> a.b { d >> a.b.d, e >> a.b.e } 
         c >> a.c { d >> a.c.e, e >> a.c.e } }
z <> a { b <> a.b { d <> a.b.d, e <> a.b.e } 
         c <> a.c { d <> a.c.e, e <> a.c.e } }
```
Thus, it is possible to mirror a model in realtime. Use cases include: co-pilot in cockpit, "digital twin" for building information modeling, overriding input contollers, dancing with robots 

## Expressions

An epression is a series of named values and conditionals; they are expessed together as a group
```c
a (x 1, y 2)  // x and y are sent together as a tuple
b (x 0…1, y 0…1)  // can contain ranges
c (x 0…1 = 1, y 0…1 = 1)  // and default values
```
A receiver may capture a subset of a send event
```c
z (x 1, y 2)            // when z! (is activated)  
d (x 0) << z            // z! => d(x 1) -- ignore y
e (y 0) << z            // z! => e(y 2) -- ignore x
f (x 0, y 0, t 0) << z  // z! is ignored, no z.t
```
But, the sending event must have all of the values captured by the receiver, or it will be ignored
```c
g (x==0, y 0) << z       // z! is ignored as z.x != 0 
h (x==1, y 0) << z       // z! activates h(x 1, y 2) 
i (x<10, y<10) << z      // z! activates i(x 1, y 2) 
j (x in -1…3, y 0) << z // z! activates j(x 1, y 2) 
k (x 0, y 0, z 0, t 0)   // z! ignored due to missing t
```
#### Overrides

Override nodes with values 
```c
a {b c}.{d(1) e} // produces    `a { b { d(1) e } c { d (1) e } }`
a.b.d (2)        // changes to  `a { b { d(2) e } c { d (1) e } }`
```
#### Wildcards

Include subtrees with wildcards. The new `˚` (option-k) wildcard behaves like an Xpath `/*/` where  it will perform a search on children, grandchildren, and so on. Using `˚.` includes all leaves,  and  `˚˚` will include the whole subtree
```c
a {b c}.{d e} // produces `a { b { d e } c { d e } }`
p << a.*.d    // produces `p << (a.b.d, a.c.d)`
q << a˚d      // produces `q << (a.b.d, a.c.d)`
r << a˚.      // produces `r << (a.b.d, a.b.e, a.c.d, a.c.e)`
s << a˚˚      // produces `s << (a a.b, a.b.d, a.b.e, a.c, a.c.d, a.c.e)`
```
Wildcard searches can occur on both left and rights sides to support fully connected trees and graphs
```c
˚˚<<..  // flow from each node to its parent, bottom up
˚˚>>.*  // flow from each node to its children, top down
˚˚<>..  // flow in both directions, middle out?
```
Because the visitor pattern breaks loops, the `˚˚<>..`  maps well to devices that combine sensors and actuators, such as:
-  a flying fader on a mix board, 
- a co-pilot's steering wheel 
- the joints on an Human body capture skeleton
- future hash trees (like Merkle trees) and graphs

### Ternaries

Edges may contain ternaries that switches dataflow. Somewhat akin to railroad switch, traffic may flow in either direction and do need to reevealate the switch as passes through. 

conditionals may switch the flow of data 
```c
a >> (b ? c : d)  // a flows to either c or d, when b activates
e << (f ? g : h)  // f directs flow from either g or h, when f acts
i <> (j ? k : l) // i synchronizes with either k or l, when j acts
m <> (n ? n1 | p ? p1 | q ? q1) // radio button style, akin to solo switch
```
conditionals may also compare its state
```c
a >> (b > 0 ? c : d) // a flows to either c or d, when b acts (default behavior)
e << (f == 1 ? g : h) // g or h flows to e, based on last f activation
i <> (j1 < j2 ? k : l) // i syncs with either k or l, based on last j1 or j2 acts
m <> (n > p ? n1 | p > q ? p1 | q > 0 ? q1) // radio button style
```
when a comparison changes is state, it reevaluates its chain of conditions

- when `b` activates, it reevaluates `b > 0`
- when `f` activates, it reevaluates `f == 1`
- when either `j1` or `j2` activates, it reevals `j1 < j2`
- when `n`, `p`, or `q` acts, it reevals `n>p`, `p>q`, and `q>0`

Ternaries act like railroad switches, where the condition merely switches the gate. So, each event passing through a gate does *not* need to re-invoke the condition

- when `b` acts, it connects `c` and disconnects `d`
- when `n`, `p`, or `q` acts, it is switching between `n1`, `p1`, `q1`

#### Bidirectional flow
Ternaries may aggregate multiple ihputs or broadcast to multiple outputs
```c
a {b c}.{d e}.{f g} // produces `a{b {d {f g} e {f g}} c {d {f g} e {f g}}}`
p >> (a.b ? b˚. | a.c ? c˚.) // broadcast p to all leaf nodes of either b or c
q << (a.b ? b˚. | a.c ? c˚.) // aggregate to q from all leaves of either b or c
```
### Embedded  Script

Flo may include external script inside of double curly brackets `{{ whatever }}`. Whatever is inside the double bracks is ignored by the script, but is available calling swift code. This is intended for the app  `DeepMuse`  to embed shader code, which can be safely recompiled at runtime. 

```c
example {
   
   metal {{
        // Metal code goes here
        …
    }}
    gl {{
        // OpenGL code goes here
        …
    }}
    js {{
        // javascript
        …
    }}
    whatever {{
        // you want
        …
    }}
}
```
When activating `example.*!`  the Flo nodes named `metal`, `gl`, `js`, and `whatever` are activated. 
Any closure, attached to those nodes, can get the contents between the brakets `{{ … }}`
The contents are whatever you want, they are interpreted by the closure at run time.

## Tests
Basic example of syntax may be found in the test cases here:  
- `Tests/FloTests/FloTests.swift` contain basic syntax tests

The `Deep Muse` app script should provide some insight as to how Flo is used in a production app, which is also in the test suite
- `Sources/Flo/Resources/*.flo.h` contains scripts from `Deep Muse` app
- `Sources/Flo/Resources/test.output.flo.h` contains scripts from `Deep Muse` app

### Packages

MuPar - parser for DSLs and flexible NLP in Swift

- tree + graph base parser
- contains a definition of the Flo Syntax
- vertically integrated with Flo
- Source [here](https://github.com/musesum/Par)

MuFloD3 (pending)

- simple visualization of the Flo graph, using D3JS
- continuation of prototype of previous version of Flo
- Proof of concept [here]( https://www.youtube.com/watch?v=a703TTbxghc) (using Prefuse toolkit)

## Use cases

### DeepMuse iOS App

Toy Visual Synth for iPad and iPhone called "DeepMuse"
- See test script in Sources/Flo/Resources/*.flo.h
- See test output in  Sources/Flo/Resources/test.output.flo.h
- Code folding and syntax highlighting works in Xcode
- Demo [here](https://www.youtube.com/watch?v=peZFo8JnhuU)

Encourage users to tweak Flo scripts without recompiling
- pass along Flo scripts, somewhat akin to Midi files for music synthesis
- connect musical instruments to visual synth via OSC, Midi, or proprietary APIs

Inspired by:
- Analog music synthesizers, like Moog Modular, Arp 2600, with patchchords
- Media Dataflow scripting : Max, QuartzComposer, Plogue Bidule


### Hand Pose Controlers

You hand has 21 joints when can be used as a gestural controller 

### Body Pose Avatars

Imagine using a camera to record body pose  
- Record total state of  `graph << body˚˚`
- Playback total state of  `graph >> body˚˚`
- Create a functional mirror `twin: body ←@→ body`
- Inspired by a Kinect/OpenNI experiment, shown [here](https://www.youtube.com/watch?v=aFO6j6tvdk8)

Check out `test.robot.input.flo.h`, which defines a Humanoid robot in three lines of code:
```c
body {left right}.{shoulder.elbow.wrist {thumb index middle ring pinky}.{meta prox dist} hip.knee.ankle.toes}
˚˚ <> ..
˚˚ { pos(x 0…1, y 0…1, z 0…1) angle(roll %360, pitch %360, yaw %360) mm(0…3000)})
```

### Vehicles and Simulators 

In 2004, NASA put on a conference called [Virtual Iron Bird](https://www.nasa.gov/vision/earth/technologies/Virtual_Iron_Bird_jb.html) to encourage modeling of Spacecraft. One question was how to manage the dataflow between sensors and actuators. How does one simulate a vehicle? Or synchonize co-pilot controls? 
