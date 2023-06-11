
# MuFlo /micro flow/

Flo is a scripting language for connecting sensors to renderers.
Sensors can be touch, camera, microphone, and body capture.
Renderers can be shaders, speakers, screens, or actuators.
Flo is essentially a toy data flow graph for naive performers.

## Elements 

- **Nodes** with names, values, edges, and closures
- **Edges** with inputs, outputs, and switches
- **Values** which transform, as it flows through a graph
- **Plugins** to animate, record, and playback dataflow

See Flo.par.h for a full lanugage definition. 

## Goals

- Author collaborative media performances
- Co-pilot local and remote devices streaming content
- Human readable and machine learnable script
- Deploy on VisionOS, iPadOS, iOS, TVOS, MIDI

### nice to have
- C compatible syntax highlighting and code folding
- minimalist script with less syntactic cruft
- Synchronize state via circular references
- Live patching without crashing or infinite loops 
- Concise description of hand pose and body pose

## Nodes 

Each node has two kinds of edges: *tree* and *graph*.
The *tree* allows each node to be addressed by a path name. 
The *graph* allows a node to activate others via inputs and outputs. 

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
A tree can copy the contents of another tree with a `@ name`
```c
a {b c}.{d e} // produces `a { b { d e } c { d e } }`
z @ a         // produces `z { b { d e } c { d e } }`
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
root.findPath("draw.brush.size")?.addClosure { flo, _ in 
        self.brushRadius = flo.float } 
```
In the above example, attach a closure to `draw.brush.size`, which then updates its internal value `brushRadius`.

## Values

Each node may have a value of: scalar, expression, or string
```c
a (1)              // scalar with an initial value of 1
b (0…1)            // scalar that ranges between 0 and 1
c (0…127 = 1)      // scalar between 0 and 127, defaulting to 1
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

A common case are sensors, which have a fixed range of values. For example, a 3G (gravity) accelerometer may have a range from `-3.0` to `3.0` 
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
Thus, it is possible to mirror a model in realtime. Use cases include: co-pilot in cockpit, "digital twin" for building information modeling, overriding input contollers, dancing with robots. 

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
g (x == 0, y 0) << z     // z! is ignored as z.x != 0 
h (x == 1, y 0) << z     // z! activates h(x 1, y 2) 
i (x < 10, y < 10) << z  // z! activates i(x 1, y 2) 
j (x in -1…3, y 0) << z  // z! activates j(x 1, y 2) 
k (x 0, y 0, z 0, t 0)   // z! ignored due to missing t
```
#### Overrides

Override nodes with values 
```c
a {b c}.{d(1) e} // produces    `a { b { d(1) e } c { d (1) e } }`
a.b.d (2)        // changes to  `a { b { d(2) e } c { d (1) e } }`
```
#### Plugins

Send/receive values to an effect, akin to an insert on a mixing board

```c
a (x 0…1, y 0…1) << (b,c)
b (x 0…1, y 0…1)
c (x 0…1, y 0…1)
cubic(0.25) // cubic curve for last 0.25 seconds
a ^ cubic // animate inputs from b,c
```
Plugins may be declared inline and sync

```c
a (x 0…1, y 0…1) <> (b,c) ^ cubic
```
In the above example, activating b will animate both a and c. 

#### Wildcards

Include subtrees with wildcards. The new `˚` (option-k) wildcard behaves like a Xpath `/*/` where  it will perform a search on children, grandchildren, and so on. Using `˚.` includes all leaves,  and  `˚˚` will include the whole subtree
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
Because the visit pattern breaks loops, the `˚˚<>..`  maps well to devices that combine sensors and actuators, such as:
- a flying fader on a mix board, 
- a co-pilot's steering wheel 
- the joints on an Human body capture skeleton


## Tests
Basic example of syntax may be found in the test cases here:  
- `Tests/FloTests/FloTests.swift` contain basic syntax tests

The `Deep Muse` app script should provide some insight as to how Flo is used in a production app, which is also in the test suite
- `Sources/Flo/Resources/*.flo.h` contains scripts from `Deep Muse` app
- `Sources/Flo/Resources/test.output.flo.h` contains scripts from `Deep Muse` app

### Packages

MuPar - parser for DSLs and flexible NLP in Swift

- a quasi Backus-Naur script to define a parser
- contains a definition of the Flo Syntax
- vertically integrated with Flo
- Source [here](https://github.com/musesum/MuPar)

MuFloD3 (future)

- simple visualization of the Flo graph, using D3JS
- continuation of prototype of previous version of Flo
- Proof of concept [here]( https://www.youtube.com/watch?v=a703TTbxghc) (using Prefuse toolkit)

## Use cases

### DeepMuse App

Visual music synth for iPad, iPhone, TV, and Vision Pro
- See test script in Sources/Flo/Resources/*.flo.h
- See test output in  Sources/Flo/Resources/test.output.flo.h
- Code folding and syntax highlighting works in Xcode

Encourage users to tweak Flo scripts without recompiling
- pass along Flo scripts, somewhat akin to Midi files for music synthesis
- connect musical instruments to visual synth via OSC, Midi, or proprietary APIs

Inspired by:
- Analog music synthesizers, like Moog Modular, Arp 2600, with patchchords
- Node based Dataflow scripting : Max, QuartzComposer, Plogue Bidule, 

### Virtual Vehicles and Simulators 

In 2004, a conference at NASA called [Virtual Iron Bird](https://www.nasa.gov/vision/earth/technologies/Virtual_Iron_Bird_jb.html) explored how to model of spacecraft as dataflow between sensors and actuators. How does one simulate a vehicle? Or synchonize co-pilot controls? 

### Body Pose Avatars

Use a camera to record body pose  
- Record total state of  `graph << body˚˚`
- Playback total state of  `graph >> body˚˚`
- Create a functional mirror `twin: body <@> body`
- Proof of concept using Kinect/OpenNI, shown [here](https://www.youtube.com/watch?v=aFO6j6tvdk8)

Check out `test.robot.input.flo.h`, which defines a Humanoid robot just a few lines of code:
```c
body {left right}
    .{shoulder.elbow.wrist
        {thumb index middle ring pinky}
        .{meta prox dist }
        hip.knee.ankle.toes}
˚˚ <> .. // nervous system
˚˚ {pos(x 0…1, y 0…1, z 0…1)
    angle(roll %360, pitch %360, yaw %360)
    mm(0…3000)})
```

# Flo Language Design

## History 

*1970*'s Flo got its start with patch cords. Hundreds of patch cords. This was due to patching analog modular Synthesizers like the Moog System III and ARP 2600. It would take hours to wire up two electronic music studios, leaving litle time to perform. So, I started to develop a script for patchbays.

*1980*'s Xerox OPSD contracted us to design a project management system. This was the first combination of tree (work breakdown) and graph (activities). Also wrote a hypertext system base this tree + graph approach. 
 
*1990*'s As a Technical Director (TD) at one of the first interactive ad agencies. Wrote a dataflow based media script, called Flow. Support two person teams, where graphic artist would script interactions, and the TD would add animations in C++.

*2000*'s Was performing as a VJ with a visual Music synthesizer written in C++ and OpenGL. The script was created to patch graphic tablets, MIDI controllers, and a Virtual Puppeteering device, called a Vuppet.

*2010*'s the Visual music synth was ported to iOS and iPadOS and rated 5 stars in the AppStore. Later deprecated by Apple in its switch to 64bit apps. The ObjectiveC/C++ app was ported to pure Swift in 2019. 

*2020*'s Maybe Spatial Computing is the answer? 

## Design Principles

### Syntax

The syntax borrows principles from Xerox Parc, Swift and Python

Xerox studied different text editors and, through detailed analytics, determined the gesture cost of transactions, like cut & paste. Thus, a data driven approach towards more efficient text editing.

Swift eliminated semicolons, resulting in less text to edit, with somewhat more Human readable source.

Python uses indentation instead of `{ }` brackets for the most readable alternative.

A very early version of Flo (around 1990) also used whitespace. That approach was abandoned when mobile devices became popular. Whitespace on tiny screen became untenable.

During each iteration, the Xerox Parc mindset was applied: what is the gesture cost? In particular, what is the gesture cost in real world environments? Today, there are three environments, from oldest to newest: 
 
   1. Desktop style source code editors, 
   2. Mobile texting, and 
   3. Spatial hands free dialogs  

#### Source code editors

The editor I use is Xcode. As with many editors, Xcode offers syntax highlighting and code folding for C syntax compatible source. So, for each iteration of Flo's syntax, I would test a few hundred lines of code from a working app and see how it works. 

A couple syntax approaches that failed:

    using open colons `:` in  `name: value` would ruin code folding
    eliminating `{ }` and use only `( )` brackets would crash Xcode

#### Mobile texting

What is the gesture cost of authoring on an iPhone or iPad? So, how many gestures to construct a viable statement. One of the reasons for attempting to eliminate `{ }` brackets was that it requires three taps on a keypad: `123, #+=, {`, whereas a `(` would requires only two: `123, (`

So, I spent a few weeks playing with replacing the { } with ( ). The syntax seemed so much cleaner, but Xcode would crash. Instead of filing a bug report, I assumed that the problem may extend to other editors. So, reverted back to `{ }`.

There are two special characters, which seems to violate interoperability, but pass: `…` and `˚` 
    `…` is `option ;` on a Mac and `123, long-press .` on an iPhone
    `˚` is `option k` on a Mac and `123, long-press 0` on an iPhone/iPad
    
    BTW, you can still use `...` instead of `…`, but the output will result in the latter. 
 
 #### Spatial Hands free
 
 Mixed mode editing has been studied for decades, where you speak and type at the same time. Other modes have been explored for Accessibility, where the user may have low vision or low mobility. 
 
 Recently there have been two disruptions: large language models or LLMs, and Apple's Vision Pro, which uses hand pose to for a hands free navigation. Both combine in a kind of synergy.
 
 Hands free navigation eliminates the need to shift the hands between creation and navigation. In terms of gesture cost, this a much easier workflow. 
 
 LLMs accelerates recognition and creation. For recognizing speech to text, LLMs have improved precision. For creation, LLMs can autocomplete intent. Source code editors are starting to use LLMs to drop in large chunks of code. At least one well funded startup is using LLMs to write apps. 
 
 The synergy between hand pose, LLMs and speech enables something new: a completely hands free authoring environment. Instead of a keyboard and mouse, you say what you want and orchestrate the code with your hands. Instead of hand coding text, you become a conductor of APIs.
 
 In a totally hands free context, Flo aims to be the manuscript. A Human readable score of APIs and services running in real-time. 
 
## Partnering HI with AI

This is such a long term design goal, that it may seem to be of a non-sequitur. Feel free skip. 

How to bridge Human Intent with AI. Issues include: Understandability, Privacy, Scaling, Security, and Expressiveness. 

### Understandability 

Chat GPT-4 has 170 Trillion parameters for its LLM. Understanding its results is problematic. This is an old problem. In the 1970's, it was hard to understand an artificial theorem provers, which may generate hundreds of lemmas.

So how to understand what is generated from a partner AI? This is still a research question.

One approach is to take baby steps. The first application of Flo is a toy: a visual music synthesizer. It has several thousand parameters. Applying the same transformers as a LLM serves as a safe means of exploring understandability. Maybe call is a small language model or SML. The advantage to a toy SML is that, when it fails, nobody is harmed as a result. Aside from maybe some weird sounds or visuals. That maybe even a plus. 

### Privacy and Value

Value is often an arbitrage of entropy: where you pay for the disclosure of protected content. Music copyright was protected through the control of the transport mechanism. In the 1980's the transport was vinyl LPs. In the 90's the medium shifted to CD's. With the internet, physical arbitrage shifted to a kind of gestural arbitrage, where gesture cost of iTunes became cheaper than ThePirateBay. Convenience justified that price.

For LLMs, the value proposition is in dispute. Scrapping copyrighted content is in dispute. That may drive research towards provenance. If you know that the source material consists of a percent of artist A and percentage of artist B, you could, in theory prorate royalties. This is an old concept, dating back Ted Nelson, who not only coined the term Hypertext, but also theorized about distributing royalties. 

What's intriguing is that determining provenance leads to understandability. Instead of a graph with 170 trillion parameters, you're mixing a percent of artist A with a percent of artist B. What is needed is a middleware graph that sits above the 170 Trillion parameters and provides a means manage what came from whom.

This is where the toy visual music synth may play a part. By segmenting and remixing music and visuals, the toy provides a manageable corpus to determine provenance. In fact, the visual music app could be experimenting with economic models that distributes subscription revenue prorated on the relative mix. 

### Scaling

This is more of a problem for the publishers of LLMs as they begin to license APIs. There are also security issues, mentioned later.

Around 1989, software publishers began to experiment with protecting content. The term of art was called Digital Rights Management or DRM. DRM had two approaches: recompile code for each app, or support a secure enclave at the OS level. The recompile approach was prohibitively expensive. It was deployed and tested ad hoc. It didn't scale. The solution was to create a secure enclave. Deploy the binary in a sandbox, where all changes was contained an reversible. Today, most app are installed into a secure enclave. (BTW, this author invented and patented the process in 1990.)

Why mention DRM? Because LLMs are on the other side of a scaling issue. By one estimate [here](https://devops.com/api-sprawl-a-looming-threat-to-digital-economy/) there may be 45 million developers accessing over a billion APIs, by 2030. How many APIs will embed a LLM? This is akin to the old model of recompiling and app for DRM. Managing the sprawl does not scale. What is needed is a secure enclave for APIs.

Two text examples to embody API dataflow are Swagger and Postman, structuring JSON and/or YAML. Flo could be thought of a somewhat higher level version of these two approachs. Here is an example of getting time in Postman

```c
{
  "info": {
    "_postman_id": "abc123",
    "name": "Sample Collection",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get Time",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "https://api.example.com/time",
          "protocol": "https",
          "host": [
            "api",
            "example",
            "com"
          ],
          "path": [
            "time"
          ]
        }
      },
      "response": []
    }
  ]
}

```
And here is the same example in Flo

```c
url("api.example.com/time") <> time
time(hms) 
```
Obviously, there is a lot of policy here, where the fictitious example.com agrees to sync `<>` with a client. It is possible that the Flo example generates the Postman example.  

There are several Graphical versions of visualizing data flow. An experiment with an earlier version of Flo (called Tr3), can be found [here](https://www.youtube.com/watch?v=a703TTbxghc&t=5s&ab_channel=Ikoino) 

There have been extensive experiments of outputting a D3.JS force directed graph. With the advent of Spatial Computing, it at maybe worth creating a force directed graph directly in Swift/C++. 

### Security

Prompt engineering is already a thing. LLMs are spouting misinformation with complete confidence. Fixes are often ad hoc after a attack was found in the field. What if you were able to explore and proactively defend attack? Let's say you have a 100 Trillion parameter LLM and you want to explore Election Misinformation attacks. So you shadow the LLM with a statement like `˚˚election<(1000)>˚˚attack` to yield a graph election attacks limited to 1000 nodes. 

Does Flo support this now? Nope. 

### Expressiveness

One technique is to cluster words with similar meanings, such as Word2Vec [here](https://cnkndmr.gitlab.io/others/en/neural-network-word2vec.html). Now imagine collapsing clusters into a single node, somewhat akin to taking the above example [here](https://youtu.be/a703TTbxghc?t=287) and collapsing the convex hulls into --say-- a dozen nodes. This has been for decades with Project Management software, where a complex project is broken into sub-projects. The main difference is, while Project management works top-down, the custering works bottom up.

Returning to the `˚˚election<(1000)>˚˚attack` example. The `˚˚election` and `˚˚attack` paths can represent clusters of similar meanings around the keywords `election` and `attack` -- as a kind of theasarus. Meanwhile, the edge `<1000>` could reduce millions of result to a 1000 nodes with the strongest connections. 

That in turn could be reduced to <100> or even <10> most relevan connections as a navigational starting point. Perhaps as a spatial flythrough venn set -- a kind of 3D version of [this](https://github.com/christophe-g/d3-venn)
