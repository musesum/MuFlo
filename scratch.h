Fix TimedBuffer using CubicPoly smoothing. Discard previous implementation, which kept adding 2sec of backlog for every 4sec of elapsed time. Is was smooth but at half speed.

Goals:

1) remove jitter from stochastic delay.
2) preserve original spacing of events, but allow for some cubic time stretching to accelerate and decelerate inter-item timeline.
3) Ideally the maximum delay nearly match anticipated future item delay time.
4) Allow for surprise extra delay with graceful recovery.
5) Do not drop items.
6) reduce cyclomatic complexity of code allowing each function to fit with a single page view and variables to track within Human short term memory of 7 +-2.

Often:

The first packet of a sequence has the longest delay before QoS prioritizes followers.

Approach:

Start with the initial packet delay based on difference of clock time stamp of sender item and current clock time of reciver . Notice how CubicPoly.addVal stuff all 4 control points for the first index -- that is find.

For example, TouchCubic uses CubicPoly to smooth three points, whereas we only one to smooth out futureTime.

Do not repeat the past mistake of allowing smoothing to spread out delay; so allow a smooth acceleration of inter-item time to catch up, allowing a total delay to rarely go beyond maximum delay between sender and receiver delta clock time.


if type == .remoteBuf {
    if !shouldRender() {
        return .waitBuf
    }
    ...
}

func shouldRender() -> Bool {
    if type != .remoteBuf {
        return true
    }
    ...
}


Advanced Vibe Coding is an Oxymoron.

Here is a snippet of pseudocode that Claude generated:

if type == .remote
    if !shouldRender()
         return .wait
...
func shouldRender() -> Bool
    if type != .remote
          return true
...

Do you see the problem?

This reminds me of a rather infamous coder who's app was bundled with the first IBM PC. His coding style was described as thus: if there was a bug where `2+2 = 5`, his fix would be `if 2+2=5 then answer = 4` -- that is the vibe I get with Claude Code and ChatGPT.

At first I was impressed. I asked Claude to smooth out musical events over a network. Within a a couple minutes it generated some code that would have taken a day for me to hand code. And it worked! So smooth! I felt like Caude (and ChatGPT) was a new superpower. And then:

I discovered it was accumalating 2 seconds of delay for every 4 seconds of stream. It's taken be a couple days to revert and fix.

And that's what I've been experiencing after applying Claude and ChatGPT on an existing code base: accumalated technical debt. It may work for now. But, cyclomatic complexity accumalates. Your clearly written code become a black box.

If 2+2=5 then answer = 4. // welcome to the vibe!



