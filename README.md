
## MuFlo /micro flow/

Flo generates a flow graph that connects sensors to actions.
Sensors can be touch, camera, microphone, and body capture.
Actions can be via shaders, speakers, screens, or actuators.

#### Elements 

- **Nodes** with names, values, edges, and closures
- **Edges** with inputs, outputs, and plugins
- **Values** which transform, as it flows through a graph
- **Closures** executable runtime code, currently Swift

See Flo.par.h for a full language definition. 

#### Node 

A node contains **Values**, **Edges**, and **Closures**.

The **Edges** coming into a node will activate it
The **Values** within the node may change, when activated
The **Closures** sends values to compiled Swift code 

#### Edges 

There are three kinds of edges: **Tree**, **Graph**, and **Plugin**.

The **Tree** allows each node to be addressed by a path name. 
The **Graph** allows a node to activate others via inputs and outputs.
The **Plugin** animates the transition of values within a node 

##### Tree Edges

Each node has any number of branches

```c
a { b c } // the a node has 2 branches: b and c 
          // b and c nodes have 1 parent and no branches
```
Declaring a path will auto create a tree of names
```c
a.b.c // generates the structure `a { b { c } }`
```
A tree can decorate another tree, with `}.{`
```c
a {b c}.{d e} // generates `a { b { d e } c { d e } }`
```
A tree can be the base of another tree, with `:`
```c
z : a         // generates `z { b { d e } c { d e } }`
```

##### Graph Edges

Each node may have any number of input and output edges, which attach to other nodes. A node can activate 

  - other nodes when its value changes as outputs( `->` ) or 
  - itself when another node's value changes as inputs (`<-`), or
  - synchronize both nodes as both input and output (`<>`).

```c
b (-> c) // b flows to c, akin to a function call
d (<- e) // d flows from e, akin to a callback
f (<> g) // f and g flow between each other, akin to sync
```
##### Plugin Edges

Plugins modify values over time. They are like the send/receive ports on a mixing board. For example

```c
a (x, y, ^- cubic) // animate changes to `a` on a cubic curve
```

#### Loops

Flo allows cyclic graphs which auto break activation loops. When a node is activated, it sends an event to its output edges. The event contains a shared set of places that the event has visited. When it encounters a node that it has visited before, it stops. 

```c
a (-> b) // if a activates, it will activate b
b (-> c) // which, in turn, activates c
c (-> a) // and finally, c stops here
```
So, no infinite loops.

#####  Activate anywhere

So, in the above `a`, `b`, `c` example, the activation could start anywhere:
```c
a activates b activates c // starts at a, stops at c
b activates c activates a // starts at b, stops at a
c activates a activates b // starts at c, stops at b
```
This is a simple way to synchronize a model. Akin to how a co-pilot's wheel synchronizes in a cockpit.

##### Loops and Neurons

The idea of breaking loops comes from the observation that neurons have an efficacy period before they are able to fire again, attenuated through the release of GABA. 

One of the first artificial models of bio neurons is from [McCulloch & Pitts] (https://en.wikipedia.org/wiki/Artificial_neuron)
 
#### Closures

Swift source code may attach a closure to a Flo node, which gets executed whenever a that node is activated. 

Given the flo script snippet:
```c
sky { draw { brush { size (<- midi.modulationWheel) } } }
// same as sky.draw.brush.size(<- midi.modulationWheel)
```
write a closure in Swift to capture a changed value
```swift
root.bind("draw.brush.size") { flo, _ in 
        self.brushRadius = flo.float } 
```
In the above example, attach a closure to `draw.brush.size`, which then updates its internal value `brushRadius`.

#### Values

Each node may have a value of: scalar, expression, or string
```c
a (1)            // scalar with an initial value of 1
b (0…1)          // scalar that ranges between 0 and 1
c (0…127=1)      // scalar between 0 and 127, defaulting to 1
d ("yo")         // a string value "yo"
e (x 0…1, y 0…1) // an expression (see below)
```
Flo automatically remaps scalar ranges, given the nodes `b` & `c`
```c 
b (0…1)       // range 0 to 1, with initial value of 0
c (0…127=1)   // range 0 to 127, with a default value 1
b (<> c)      // synchronize b and c and auto-remap values
```
When the value of `b` is changed to `0.5` it activates `c` and remaps its value to `63`;
When the value of `c` is changed to `31`, it activates  `b` and remapts its value to `0.25`

A common use case is sensors, which have a fixed range of values. For example, a 3G (gravity) accelerometer may have a range from `-3.0` to `3.0` 
```c 
accelerometer (x -3.0…3.0, y -3.0…3.0, z -3.0…3.0, -> model)
model (x -1…1, y -1…1, z -1…1) // will auto rescale
```
##### Values may pass through nodes unchanged
Where a node is merely an intersection
```c
a (0…1, -> b)  // may pass along value to b
b (-> c)       // has no value, will forward a to c
c (0…10)       // gets a's value via b, remaps ranges
```
##### Graph's inputs and ouputs may contain values

Activations values can be passed as either inputs, outputs, or syncs

```c
a (-> b(1)) // an activated a (or a!) sends 1 to b
b (<- c(2)) // an activated c (or c!) sends 2 to a
d (<> e(3)) // d! sends a 3, while c! does nothing
f (-> g(0…1 : 0)) // f! sends a ranged 0 to g's min range
h (<- i(0…1 : 1)) // i! sends a ranged 1 to h's max range
```
Sending a ranged value to receiver will remap values, which can become a convenient way to set `min`, `mid`, or `max` values 

```c
j(10…20, <- k(0…1 : 0))   // k! maps j to 10 (min)
m(10…20, <- n(0…1 : 0.5)) // n! maps m to 15 (mid)
p(10…20, <- q(0…1 : 1))   // q! maps p to 20 (max)
```
##### Digital twin by Name
In addition to copying a tree, a new tree can connect edges by name
```c
a {b c}.{d e} 
x:a (<: a) // input from a˚˚
y:a (:> a) // output to a˚˚
z:a (<:> a) // synchronize with a˚˚
```
which expands to
```c
a { b { d e } c { d e } }
x (<- a) { b (<- a.b) { d (<- a.b.d), e (<- a.b.e) } 
           c (<- a.c) { d (<- a.c.e), e (<- a.c.e) } }
y (-> a) { b (-> a.b) { d (-> a.b.d), e (-> a.b.e) } 
           c (-> a.c) { d (-> a.c.e), e (-> a.c.e) } }
z (<> a) { b (<> a.b) { d (<> a.b.d), e (<> a.b.e) } 
           c (<> a.c) { d (<> a.c.e), e (<> a.c.e) } }
```
Thus, it is possible to mirror a model in realtime. Such as: 

- synchronizing input contollers 
- co-pilot controls in a cockpit 
- architect's digital twin 
- dancing with robots

###### a note on edge syntax 

Previous version of Flo had edges outside of the parenthesis, like this
```c
a (0…1) -> b 
```
but now included inside the parens, like so:
```c
a (0…1, -> b) 
```
This seems at with C style functions whilc have 
```c
func (a: Type) -> Type { ... }
```
The difference is that, unlike C, each Flo node may have multiple inputs and outputs of different types. Here's a snippet from menu.flo.h
```c
repeat (xy, x -1…1=0, y -1…1=0,
        <> pipe˚.repeat,
        -> (midi.cc.skypad.repeatX(val: x),
            midi.cc.skypad.repeatY(val: y)),
        ^- sky.main.anim)
mirror (xy, x 0…1=0, y 0…1=0,
        <> pipe˚.mirror,
        ^- sky.main.anim)
```
Having the edges outside of the parens turn out to be less readable and hard format inside a C-based editor, like XCode. 

##### Expressions

An expression is a series of named values and conditionals; they are expessed together as a group
```c
a (x 1, y 2)          // x and y are sent together as a tuple
b (x 0…1, y 0…1)      // can contain ranges
c (x 0…1=1, y 0…1=1)  // and default values
```
A receiver may capture a subset of a send event
```c
z (x 1, y 2)    // when z! (is activated)  
d (x 0, <- z)   // d evals to d(x 1) -- y ignored
e (y 0, <- z)   // e evals to e(y 2) -- x ignored
``` 
But, the sending event must have all of the values evaluated by the receiver, or it will be ignored
```c
f (x == 0, y 0,    <- z)  // z! is ignored as z.x != 0 
g (x == 1, y 0,    <- z)  // z! activates h(x 1, y 2) 
h (x < 10, y < 10, <- z)  // z! activates i(x 1, y 2) 
i (x in -1…3, y 0, <- z)  // z! activates j(x 1, y 2) 
```

Here is mapping of MIDI musical notes, where `row` maps notes on a 12-tone scale, and `col` maps each octave:

```c
grid (row: note % 12, col: note / 12, <- midi(note 0_127))
```
Note the  `0_127`  range in  `midi(note 0_127)`. MIDI notes numbers are integers. Using 0…127 would not evenly rescale ranges.

##### Overrides

Override nodes with values 
```c
a {b c}.{d(1) e} // generates   `a { b { d(1) e } c { d (1) e } }`
a.b.d (2)        // changes to  `a { b { d(2) e } c { d (1) e } }`
```

##### Wildcards

Include subtrees with wildcards. The new `˚` (option-k) wildcard behaves like a Xpath `/*/` where  it will perform a search on branches, subbranches, and so on. Using `˚.` includes all leaves,  and  `˚˚` will include the whole subtree
```c
a {b c}.{d e} // generates `a { b { d e } c { d e } }`
p (<- a.*.d)  // generates `p <- (a.b.d, a.c.d)`
q (<- a˚d  )  // generates `q <- (a.b.d, a.c.d)`
r (<- a˚.  )  // generates `r <- (a.b.d, a.b.e, a.c.d, a.c.e)`
s (<- a˚˚  )  // generates `s <- (a a.b, a.b.d, a.b.e, a.c, a.c.d, a.c.e)`
```
Wildcard searches can occur on both left and right sides to support fully connected trees and graphs
```c
˚˚(<-..)  // flow from each node to its parent, bottom up
˚˚(->.*)  // flow from each node to its branches, top down
˚˚(<>..)  // flow in both directions, middle out?
```
Because the visitor pattern breaks loops, the `˚˚<>..`  maps well to devices that combine sensors and actuators, such as:

- a flying fader on a mix board, 
- a co-pilot's steering wheel 
- hand pose or body pose skeleton
- teleprescense 

#### Advanced 

The next sections are of interest to anyone connecting Flo to Swift code. 

##### A Name can Refer to Anything 

At the foundation of an expression is a [Name: Any] dictionary. Most of the Any's are scalars values. But, Any could be anything.

 For example, pipe.flo.h uses `tex` to refer to a MTLTexture and `buf` to refer to a MTLBuffer. 
```c
draw (on 1) {
    in (tex, <- cell.out)
    out (tex, archive)  // save snapshot of drawing surface
    shift (buf, x 0…1=0.5,  y 0…1=0.5)
cell (on 1) {
    fake (tex, <- draw.out)
    real (tex, <- (draw.out, camera.out))
    out (tex)
    ...
```
Here the draw shader gets its 
`in texture`  from `<- cell.out` texture and
the cell shader gets its
`fake texture` from `<- draw.out` texture

##### Radio Button - Soloing 

Because Flo breaks loops, you can implement a radio button (akin to an audio mixer's solo mode) by broadcasting an off signal to all of a node's siblings

```c
radio {
    a(on 0)
    b(on 0)
    * (-> *(on 0)) // for all siblings, broadcast `(on 0)`
}
```
which gets expanded to 

```c
 radio {
     a(on 0, -> (radio.a(on 0), radio.b(on 0)))
     b(on 0, -> (radio.a(on 0), radio.b(on 0)))
     * (-> *(on 0))
 }
```
##### Auto Activate a Solo Control

to auto switch to a new control, whenever you modify its sub controls

```c
radio {
    a(on 0) { a1(1) a2(2) }
    b(on 0) { b1(1) b2(2) }
    * (-> *(on 0))
    ˚. (-> ..(on 1)) // for each leaf, set its parent `on 1`
}
```
so, during runtime, setting `b2(22)!`, would result in the expanded graph

```c
radio {
    a(on 0, -> (radio.a(on 0), radio.b(on 0))) {
        a1(1) -> radio.a(on 1)
        a2(2) -> radio.a(on 1)
    }
    b(on 1) -> (radio.a(on 0), radio.b(on 0)) {
        b1(1) -> radio.b(on 1)
        b2(22) -> radio.b(on 1)
    }
    * -> *(on 0)
    ˚. -> ..(on 1)
}
```

you could also define outside the `radio {…}` brackets

```c
radio {
    a(on 0) { a1(1) a2(2) }
    b(on 1) { b1(1) b2(2) }
}
radio.*(-> *(on 0))
radio˚.(-> ..(on 1))
```
real world example in the DeepMuse project
```c
cell(on 1) {
    slide (on 1) { version(x 0…7=3) }
    zha   (on 0) { version(x 0…6=2) }
    ave   (on 0) { version(x 0…1=0.5) }
    fade  (on 0) { version(x 1.2…3) }
    melt  (on 0) { version(x 0…1=0.5) }
    tunl  (on 0) { version(x 0…5=1) }
    fred  (on 0) { version(x 0…4=4) }
    * -> *(on 0) // solo only one cell branch
    ˚version -> ..(on 1) // changing `version` auto switches cell
}
```
Let's say, for example 

  - A knob, somewhere connects to the `zha.version` node
  - where turning that knob will change version's value 
  - which then turn sends a `..(on 1)` to its  parent: `zha`
  - whereupon, Zha broadcasts a `*(on 0)` to all of its siblings
  - including itself, but since Zha sent the message, 
  - it ignores its own message, and breaks the loop
  - thus, keeping its `(on: 1)`  
  
So, twisting one of Zha's version control will auto-solo Zha. 

#### Tests
More examples of syntax may be found in the test cases here:
  
- `Tests/FloTests/FloTests.swift` contain basic syntax tests

The `Deep Muse` app script should provide some insight as to how Flo is used in a production app, which is also in the test suite

- `Sources/Flo/Resources/*.flo.h` contains scripts from the Deep Muse app

#### Packages

MuVisit - visit each node only once
 
 - break infinit loops in circular graphs
 - block nodes which failed an expression
 - copy blocked list for animating tweens 
 
#### Goals

- Author collaborative media performances
- Co-pilot local and remote devices streaming content
- Human readable and machine learnable script
- Deploy on VisionOS, iPadOS, iOS, TVOS, MIDI

##### Guildlines

- C compatible syntax highlighting and code folding
- minimalist script with less syntactic cruft
- Synchronize state via circular references
- Live patching without crashing or infinite loops 
- Concise description of hand pose and body pose

#### Use cases

##### DeepMuse App

Visual music synth for iPad, iPhone, TV, and Vision Pro

- See test script in Sources/Flo/Resources/*.flo.h
- See test output in  Sources/Flo/Resources/test.output.flo.h
- Code folding and syntax highlighting works in Xcode

Encourage users to tweak Flo scripts without recompiling

- pass along Flo scripts, somewhat akin to Midi files for music synthesis
- connect musical instruments to visual synth via OSC, Midi, or proprietary APIs

Inspired by:

- Analog music synthesizers, like Moog Modular, Arp 2600, with patchchords
- Node based Dataflow scripting : Max, QuartzComposer, PD

##### Virtual Space Craft

In 2004, NASA's [Virtual Iron Bird](https://www.nasa.gov/vision/earth/technologies/Virtual_Iron_Bird_jb.html) conference explored how to model spacecraft. Currently, the ISS is estimated to have around 350,000 sensors. 

In 2024, Apple released the Vision Pro with fast eye gaze and hand pose. Imagine a flow graph of 350,000 sensors and actuators, which overlays a control surface on whatever you see.

In music production, there is a process called "lean mode", where twisting a knob on once device while moving a slider an another device connects them together. The brain does something similar with Hebbian leaning, where "cells that fire together learn together."

Now imagine recording different datasets. One is from the Vision Pro, which is recording UTC, video, eye gaze and hand pose. The other(s) is from the ISS, which is recording UTC, sensor and actuator states. The result is a multi-model corpora in which to train a model. A model that can recognize familiar things and overlay an interface.

##### Body Pose

Use a camera to record body pose 
 
- Record total state of  `graph <- body˚˚`
- Playback total state of  `graph -> body˚˚`
- Create a functional mirror `graph <:> body`
- Proof of concept using Kinect/OpenNI, shown [here](https://www.youtube.com/watch?v=aFO6j6tvdk8)

Check out `hand.future.flo.h`, which generates a hand pose skeleton, that maps to a hand Skeleton in visionOS
```c
// future fixes for  MuFlo
hand.{ left right }.{
    thumb  {      knuc base inter tip }
    index  { meta knuc base inter tip }
    middle { meta knuc base inter tip }
    ring   { meta knuc base inter tip }
    little { meta knuc base inter tip }
    wrist
    forearm
    canvas <- middle.tip // last item ignores edge?
}
// decorate leaves with expressions, while keeping edges intact
hand˚.(x -0.3…0.3, y 0.8…1.2, z -0.5…0.01, time, phase, joint)

```

#### Flo Language Design

##### History 

*1970*'s Before Flo, there were patch cords. Hundreds of patch cords. This was due to patching analog modular synthesizers, like the Moog System III and ARP 2600. It would take hours to wire up two electronic music studios. From that came a script notation for patching devices.

*1980*'s Xerox OPSD (the commercial side of PARC) contracted a design for a project management system, based on their graphical UI based OS. This was the first combination of tree (work breakdown) and graph (activities). Later, wrote a hypertext system also based on this tree + graph approach. 
 
*1990*'s A Technical Director (TD) at an interactive ad agency wrote a dataflow based media script, called Flow. Flow supported a team, which paired an artist with a coder. The artist would script interactive media and the coder would extend the script with new features in C++. Deployed millions of runtimes on CD's and Floppies. 

*2000*'s As VJ wrote a visual Music synthesizer, written in C++ and OpenGL. The script was created to patch a graphics tablet, MIDI controllers, and a Virtual Puppeteering device, called a [Vuppet](https://www.youtube.com/watch?v=iXLP1B5fzpo).

*2010*'s the Visual music synth was ported to the AppStore. Later deprecated by Apple in its switch to 64bit apps. The ObjectiveC/C++ app was ported to pure Swift in 2019. 

*2020*'s Scripting for multi performers

##### Design Principles

The syntax borrows principles from Xerox Parc, Swift and Python

Jef Raksin recommended this book to me [The Psychology of Human Computer Interaction](https://books.google.com/books?id=iUtaDwAAQBAJ&printsec=frontcover#v=onepage&q&f=true)

Swift eliminated semicolons; few keystrokes and easier on the eyes

Python uses indentation instead of `{ }` brackets for the most readable alternative.

Before Flo, was Flow (around 1990), which also used whitespace. That approach was abandoned when mobile devices became popular. Whitespace needed more --well-- space.

Each iteration focused on gesture cost. In particular, which shifted for each era 
 
   1. mouse and keys > 1980s
   2. touch screen and voice > 2000's
   3. eye gaze and hand pose > 2020's

##### Source code editors

I use Xcode. Like many editors, it does syntax highlighting and code folding for C. So, for each iteration of Flo's syntax, I would test a few hundred lines of code from a working app and see how it works. 

The most recent change is including edge definitions from this: 

    `a(x,y) >> b`
    
to this

    `a(x,y,-> b)`

The reason is that multiple edges don't play nice with auto-indentation. Consider this snippet form menu.flo.h:
```
 repeat (xy, x -1…1=0, y -1…1=0,
         <> pipe˚.repeat,
         -> (midi.cc.skypad.repeatX(val x),
             midi.cc.skypad.repeatY(val y)),
         ^- sky.main.anim)
```
It has three kinds of edges, but folds nicely in XCode.

##### Mobile texting

What is the gesture cost of authoring on an iPhone or iPad? In other words, how many taps to construct a viable statement? One of the reasons for attempting to eliminate `{ }` brackets was that it requires three taps on a keypad: `123, #+=, {`, whereas a `(` would requires only two: `123, (`

So, I spent a few weeks playing with replacing the { } with ( ). The syntax seemed so much cleaner, but Xcode would crash. So, reverted back to `{ }`.

There are two special characters, ok: `…` and `˚`, but are available:

    `option-;` for `…` on a Mac and `long-press-.` on an iPhone or iPad
    `option-k` for `˚` on a Mac and `long-press-0` on an iPhone or iPad
    
BTW, you can still use `...` instead of `…`, but the output will be `…`

##### Spatial Eye Gaze and Hand Pose
 
 Mixed mode editing has been studied for decades, where you speak and touch at the same time. Mixed mode is commonly used for Accessibility, for low vision or low mobility. Now, LLMs enable dialog to anticipate what you are going to say next.
 
 The same goes for Human gestures. The Apple Vision Pro has very fast hand pose. Eventually, the multiple contexts of voice, hand, eyes, and intent will anticipate where you want to go next, and thus make it easier to get there. 
 
 It could be as simple as making a menu choice intuitive. Or, it could be as complex as navigating through trillions of tokens. A crude look at what that may look like is [here](https://www.youtube.com/watch?v=a703TTbxghc&t=5s&ab_channel=Ikoino) 

For now: baby steps. The first application of Flo is a toy: a visual music synthesizer. It's predecessor had 2800 parameters.

##### Enjoy
