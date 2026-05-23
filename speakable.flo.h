/// speakable.flo.h — Exploration of a spoken-language CLI for MuFlo
///
/// Goal: a 12-year-old says what they want, an LLM translates to Flo ops,
/// the graph changes, and the kid sees/hears what happened.
///
/// This builds on `commandline.flo.h` but replaces `√` expert syntax
/// with natural English that maps to the same runtime operations.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 1. MENTAL MODEL — "Pipes and Knobs"
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// The kid doesn't think in nodes and edges.
// They think in:
//
//   THINGS   — stuff that exists (thumb, brush, color, screen)
//   PIPES    — connections between things (→ edges)
//   KNOBS    — values you can turn up or down (scalars with ranges)
//
// "Connect my thumb to the brush size" = create a pipe
// "Turn the color fade up to 80%"      = turn a knob
// "Disconnect my hand from the brush"  = remove a pipe
// "What can I connect to?"             = list available things
//
// The LLM's job: translate pipe/knob language into Flo paths and ops.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 2. VERB VOCABULARY — 10 speakable verbs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Verb          | Flo Operation             | Example spoken
// ─────────────────────────────────────────────────────────────────
// "connect"     | edge: A -> B              | "connect my thumb to brush size"
// "disconnect"  | remove edge: A -!> B      | "disconnect my hand from the color"
// "sync"        | edge: A <> B              | "sync left hand with right hand"
// "set"         | setVal / setNameNums      | "set brush size to 30"
// "turn up"     | increment toward maxim    | "turn up the fade"
// "turn down"   | decrement toward minim    | "turn down the brush size"
// "show"        | scriptNow / scriptDef     | "show me the brush"
// "show all"    | ˚˚ from context           | "show me everything"
// "what can"    | ˚. leaf introspection     | "what can I connect to?"
// "undo"        | snapshot rollback         | "undo that"
//
// These 10 verbs cover: create edge, remove edge, bidirectional edge,
// set value, relative adjust (x2), introspect (x3), and undo.
//
// Notably absent: mv, cd, rm, cp — graph restructuring is expert-mode.
// A kid wires things and tweaks values. They don't reorganize the tree.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 3. THE GRAPH — what the kid is working with
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// The DeepMuse app already loads these flo graphs:
//
//   hand.left.thumb.tip         (x, y, z, time, phase, joint)
//   hand.right.index.tip        ...
//   skeleton.left.shoulder      ...
//   sky.draw.brush.size         (1…64=10)
//   sky.draw.brush.index        (1…255=127)
//   sky.color.xfade             (0…1=0.5)
//   sky.input.force             (0…0.5)
//   sky.pov                     (x, y, z, time)
//   shader.model.cell.fade      (0…1=0.5)
//   shader.model.cell.ave       (0…1=0.5)
//   shader.model.cell.zha       (0…6=2)
//
// For the kid, we surface ALIASES — friendly names that resolve to paths:
//
//   "my thumb"       → hand.left.thumb.tip  (or hand.right.thumb.tip)
//   "my index"       → hand.left.index.tip
//   "my pinch"       → touch                (thumb+index proximity)
//   "brush size"     → sky.draw.brush.size
//   "brush color"    → sky.draw.brush.index
//   "color fade"     → sky.color.xfade
//   "the drawing"    → sky.draw
//   "cell fade"      → shader.model.cell.fade
//   "screen fill"    → sky.draw.screen.fill
//   "point of view"  → sky.pov
//
// Aliases are defined in a sidecar file (aliases.flo or JSON),
// editable by the kid: "call my right thumb 'righty'"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 4. LLM TRANSLATION LAYER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Speech → LLM → Structured Intent → Flo Runtime
//
// The LLM receives:
//   1. The spoken command (text from speech-to-text)
//   2. A system prompt with:
//      - The 10 verbs and their Flo mappings
//      - Current alias table
//      - Current graph summary (˚. leaf list, ~20 lines)
//      - Recent command history (last 5 commands)
//
// The LLM outputs a JSON intent:
//
//   { "verb": "connect",
//     "source": "hand.left.thumb.tip",
//     "target": "sky.draw.brush.size",
//     "params": {} }
//
//   { "verb": "set",
//     "target": "sky.draw.brush.size",
//     "params": { "x": 30 } }
//
//   { "verb": "show",
//     "target": "sky.draw.brush",
//     "params": { "depth": "children" } }
//
//   { "verb": "turn_up",
//     "target": "sky.color.xfade",
//     "params": { "amount": 0.2 } }
//
// The intent is validated BEFORE execution:
//   - source/target paths resolved via findPath()
//   - value ranges checked against scalar minim/maxim
//   - edge duplicates checked against existing floEdges
//
// If validation fails, the LLM is re-queried with the error context
// to generate a clarification question.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 5. EXAMPLE SESSION — Maya, age 12, first time
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Maya puts on the headset. The app loads the default graph.
/// She sees sparkly particles drifting across a dark screen.
/// A friendly prompt appears: "Say something to get started!"

/// ──────────────────────────────────────────────────
/// DISCOVERY — "what can I do?"
/// ──────────────────────────────────────────────────

🎤 "What can I connect to?"

/// LLM intent: { "verb": "what_can", "params": { "category": "all" } }
/// Flo op: ˚. (leaf introspection on hand + sky + shader roots)
/// Filters to kid-friendly aliases only

🔊 "You have:
     Your hands — thumb, index, middle, ring, pinky (left and right)
     Drawing — brush size, brush color, screen fill
     Colors — color fade, palettes
     Effects — cell fade, cell average, cell melt, cell tunnel
     Camera — point of view"

/// ──────────────────────────────────────────────────
/// CONNECTING — "connect my thumb to the brush size"
/// ──────────────────────────────────────────────────

🎤 "Connect my thumb to the brush size"

/// LLM resolves:
///   "my thumb" → hand.left.thumb.tip  (default: left, .tip)
///   "brush size" → sky.draw.brush.size
///
/// Intent: { "verb": "connect",
///           "source": "hand.left.thumb.tip",
///           "target": "sky.draw.brush.size" }
///
/// Flo op:  hand.left.thumb.tip -> sky.draw.brush.size
///
/// Runtime: EdgeDef("->").connectNewEdge(thumb, brushSize, nil, nil)
///
/// The scalar mapping happens automatically:
///   thumb.z (range -0.5…0.01) maps to brush.size (range 1…64)
///   via Scalar.setFrom() which normalizes across ranges

🔊 "Done! Your left thumb now controls brush size.
     Move your thumb closer to make it bigger."

/// Visual: a brief glow animation on the brush-size indicator,
/// and immediately the brush size responds to thumb z-depth.

/// ──────────────────────────────────────────────────
/// AMBIGUITY — "connect my hand to the color"
/// ──────────────────────────────────────────────────

🎤 "Connect my hand to the color"

/// LLM detects ambiguity on BOTH sides:
///   "my hand" → hand.left? hand.right? which joint?
///   "the color" → sky.color.xfade? sky.draw.brush.index? sky.color.pal0?
///
/// Rather than guess, it asks:

🔊 "Which part of your hand — like your thumb, index finger, or fist?
     And which color thing — the fade between palettes, or the brush color?"

🎤 "My index finger to the palette fade"

/// LLM resolves:
///   "index finger" → hand.left.index.tip
///   "palette fade" → sky.color.xfade
///
/// Intent: { "verb": "connect",
///           "source": "hand.left.index.tip",
///           "target": "sky.color.xfade" }
///
/// Flo op: hand.left.index.tip -> sky.color.xfade

🔊 "Got it! Your left index finger now controls the color fade.
     Move it to blend between the two palettes."

/// ──────────────────────────────────────────────────
/// ADJUSTING — "turn up the fade" / "set brush size to 30"
/// ──────────────────────────────────────────────────

🎤 "Set the brush size to 30"

/// Intent: { "verb": "set",
///           "target": "sky.draw.brush.size",
///           "params": { "x": 30 } }
///
/// Flo op: sky.draw.brush.size.setVal(30)
///         range is 1…64, so 30 is valid → accepted

🔊 "Brush size is now 30."

🎤 "Turn up the cell fade"

/// Intent: { "verb": "turn_up",
///           "target": "shader.model.cell.fade",
///           "params": { "amount": 0.1 } }
///
/// LLM picks a default step of 0.1 (10% of 0…1 range).
/// Flo op: current value 0.5 + 0.1 = 0.6
///         shader.model.cell.fade.setVal(0.6)

🔊 "Cell fade is now 60%. Say 'more' to keep going."

🎤 "More"

/// Context-aware: repeats last command
/// cell.fade → 0.7

🔊 "Cell fade is now 70%."

/// ──────────────────────────────────────────────────
/// DISCONNECTING — "disconnect my thumb from the brush"
/// ──────────────────────────────────────────────────

🎤 "Disconnect my thumb from the brush size"

/// Intent: { "verb": "disconnect",
///           "source": "hand.left.thumb.tip",
///           "target": "sky.draw.brush.size" }
///
/// Flo op: find edge in floEdges where left=thumb, right=brush.size
///         edge.active = false  (soft disconnect, reversible)
///         Or: EdgeDef("!>").connectNewEdge(thumb, brushSize)

🔊 "Disconnected. Your thumb no longer controls brush size."

/// ──────────────────────────────────────────────────
/// SHOWING — "show me the brush" / "show me everything"
/// ──────────────────────────────────────────────────

🎤 "Show me the brush"

/// Intent: { "verb": "show", "target": "sky.draw.brush" }
/// Flo op: sky.draw.brush.scriptNow
///
/// Returns kid-friendly version:

🔊 "Brush:
     size — 30 (range 1 to 64)
     pressure — on (range 0 to 1)
     color — 127 (range 1 to 255)
     Connected from: nothing right now"

🎤 "Show me everything I connected"

/// Intent: { "verb": "show", "params": { "filter": "user_edges" } }
/// Flo op: walk floEdges, filter to edges created this session

🔊 "Your connections:
     1. Left index finger → color fade
     That's it! Your thumb was connected to brush size
     but you disconnected it."

/// ──────────────────────────────────────────────────
/// UNDO — "undo that"
/// ──────────────────────────────────────────────────

🎤 "Undo that"

/// Intent: { "verb": "undo" }
/// Flo op: restore previous snapshot (graph state before last command)
/// This reconnects thumb → brush.size (the disconnect is undone)

🔊 "Undone! Your thumb is connected to brush size again."

/// ──────────────────────────────────────────────────
/// ERROR — "connect the music to the smell"
/// ──────────────────────────────────────────────────

🎤 "Connect the music to the smell"

/// LLM cannot resolve either path.
/// No alias matches. findPath returns nil for both.

🔊 "Hmm, I don't have 'music' or 'smell' as things you can use.
     Try saying 'what can I connect to?' to see what's available."

/// ──────────────────────────────────────────────────
/// POWER USER — Maya, 3 weeks later
/// ──────────────────────────────────────────────────

🎤 "Sync both hands"

/// Intent: { "verb": "sync",
///           "source": "hand.left",
///           "target": "hand.right" }
///
/// Flo op: hand.left˚. <:> hand.right˚.
/// Leaf-to-leaf bidirectional edge binding by name

🔊 "Left and right hands are synced — they mirror each other now."

🎤 "Connect my pinch to screen fill"

/// "pinch" = alias for touch (thumb+index proximity)
/// Intent: { "verb": "connect",
///           "source": "touch",
///           "target": "sky.draw.screen.fill" }
///
/// Flo op: touch -> sky.draw.screen.fill

🔊 "Pinch your fingers to fill the screen!"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 6. DISAMBIGUATION STRATEGY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// When the LLM can't resolve a name:
//
// TIER 1 — Exact alias match → use it
//   "brush size" → sky.draw.brush.size       ✓ done
//
// TIER 2 — Fuzzy alias match (one result) → use it, confirm
//   "the fade" → sky.color.xfade             ✓ "Using color fade — right?"
//
// TIER 3 — Fuzzy alias match (multiple results) → ask
//   "the color" → [xfade, brush.index, pal0]  → "Which one: fade, brush color, or palette?"
//
// TIER 4 — No alias match, try findPathNames → ask for confirmation
//   "cell melt" → shader.model.cell.melt      → "Found 'cell melt' — is that right?"
//
// TIER 5 — Nothing found → suggest alternatives
//   "the music" → nil                         → "I don't have that. Try: [list]"
//
// The LLM also applies CONTEXT from recent commands:
//   If last command was about "brush", then "turn it up" → brush size
//   If last command connected X → Y, then "undo that" → undo that edge

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 7. FEEDBACK — what the kid sees and hears
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Every command produces THREE forms of feedback:
//
// AUDIO  — spoken confirmation (TTS, <2 seconds, conversational tone)
//          "Done! Your thumb controls brush size now."
//
// VISUAL — brief animation on the affected nodes
//          New pipe: glowing line appears between source and target
//          Set value: knob/slider animation to new position
//          Disconnect: line fades out with a gentle snap
//          Error: soft red pulse on the prompt area
//
// TEXT   — optional subtitle for the spoken response
//          Shown briefly, then fades. Not a chat log.
//          Power users can say "show log" to see history.
//
// The feedback is IMMEDIATE — the LLM intent parsing + validation
// should complete in <500ms (local model or cached system prompt).
// The visual effect triggers the moment the Flo operation completes.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 8. ERROR RECOVERY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ERRORS NEVER FEEL LIKE ERRORS. They feel like conversation.
//
// | Situation                      | Response                                      |
// |--------------------------------|-----------------------------------------------|
// | Unknown word                   | "I don't know 'X'. Here's what I have: [...]" |
// | Ambiguous target               | "Which one? [short list of options]"           |
// | Value out of range             | "Brush goes from 1 to 64. Want me to set max?"|
// | Already connected              | "Those are already connected! Want to adjust?" |
// | Nothing to undo                | "Nothing to undo yet!"                         |
// | Speech recognition garbage     | "I didn't catch that. Try again?"              |
// | Circular edge would deadlock   | "That would create a loop. Want one-way?"      |
//
// Key principle: NEVER show Flo paths or errors to the kid.
// "findPath returned nil for 'hand.left.thumb.tip'" → NEVER.
// "I can't find your thumb — are your hands being tracked?" → YES.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 9. INTROSPECTION — how the kid discovers the graph
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// The kid never needs to know the tree structure.
// Discovery is through four natural questions:
//
// "What can I use?"        → categorized list of friendly aliases
//                             Inputs: hands, skeleton
//                             Outputs: drawing, colors, effects, camera
//
// "What is [X] doing?"     → current value + current connections
//                             "Brush size is 30, controlled by your thumb"
//
// "What's connected?"      → list of active user-created edges
//                             "Your thumb → brush size"
//                             "Your index → color fade"
//
// "What can I do with [X]?"→ suggest compatible connections
//                             "Your thumb could control: brush size,
//                              color fade, screen fill, point of view..."
//
// The last one is KEY — it uses scalar compatibility:
// If source has (x,y,z) and target has (x,y,z), they're compatible.
// If source has (x) and target has (x), compatible.
// If source has (x,y,z) and target has (x), map z→x (depth→value).
//
// The LLM can explain WHY a connection makes sense:
// "Your thumb moves in 3D — if you connect it to brush size,
//  moving your thumb forward and back changes how big the brush is."

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 10. WHAT THIS MAPS TO IN MUFLO — implementation sketch
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// The speakable CLI is NOT a new Flo feature. It's a LAYER:
//
//   ┌─────────────────────────────┐
//   │  Speech-to-Text (Apple STT) │
//   └──────────┬──────────────────┘
//              │ text
//   ┌──────────▼──────────────────┐
//   │  LLM (local or API)         │
//   │  System prompt:             │
//   │   - verb table              │
//   │   - alias table             │
//   │   - current ˚. leaf summary │
//   │   - last 5 commands         │
//   │  Output: JSON intent        │
//   └──────────┬──────────────────┘
//              │ intent
//   ┌──────────▼──────────────────┐
//   │  Intent Validator            │
//   │   - findPath() resolution   │
//   │   - range checking          │
//   │   - edge dedup checking     │
//   └──────────┬──────────────────┘
//              │ validated intent
//   ┌──────────▼──────────────────┐
//   │  Flo Runtime                 │
//   │   - EdgeDef.connectNewEdge  │
//   │   - Flo.setVal / setNameNums│
//   │   - edge.active = false     │
//   │   - snapshot for undo       │
//   └──────────┬──────────────────┘
//              │ result
//   ┌──────────▼──────────────────┐
//   │  Feedback Generator          │
//   │   - TTS response            │
//   │   - Visual animation        │
//   │   - Subtitle text           │
//   └─────────────────────────────┘
//
// The entire layer is ~4 components:
//   1. Alias registry (JSON sidecar, user-editable)
//   2. LLM prompt builder (reads graph state, builds system prompt)
//   3. Intent validator (uses existing Flo.findPath + Scalar.inRange)
//   4. Feedback generator (TTS + visual animation triggers)
//
// The Flo graph itself doesn't change. No new DSL syntax needed.
// The LLM IS the parser for human language → Flo operations.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 11. OPEN QUESTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Q: Local LLM or API?
//    Local (e.g., small model on device) gives <200ms latency.
//    API gives better understanding but 500ms+ latency.
//    Could do: local model for known patterns, API fallback for novel.
//
// Q: How does the kid know which hand joint maps to what?
//    Visual: when they say "connect my thumb", highlight thumb in AR.
//    Before connecting, show a preview: "move your thumb and watch
//    what would happen" (dry-run mode).
//
// Q: Multi-parameter connections?
//    "Connect my hand to the camera" → hand.left˚tip -> sky.pov
//    This connects (x,y,z) → (x,y,z) by name matching.
//    The kid doesn't specify individual dimensions.
//
// Q: Presets?
//    "Do the one where my hands control everything" → load a preset
//    Presets are just saved edge configurations (snapshot + alias set).
//    Kids can name and share them: "Save this as 'finger painting'"
//
// Q: Can the kid create new nodes?
//    No. The graph structure is fixed by the app.
//    They can only wire, set values, and disconnect.
//    Creating nodes is expert-mode (commandline.flo.h territory).
//
// Q: Multiple users / collaboration?
//    MuPeers already syncs via Bonjour.
//    "Sync with Jamie's hands" → peer connection + hand.right binding
//    Two kids, one graph, different hand assignments.
