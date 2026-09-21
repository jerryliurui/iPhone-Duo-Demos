import Foundation
var now = 0.0
let clock = MatchClock(uptime: { now })
assert(clock.remaining == [180,180] && clock.active == nil)
clock.press(1)
assert(clock.active == 1)
clock.press(0)
assert(clock.active == 1 && clock.moves == [0,0])
now = 12.5
clock.update()
assert(clock.remaining[1] == 167.5)
clock.pause()
assert(clock.active == nil)
let paused = clock.remaining
now = 100
clock.update()
assert(clock.remaining == paused)
clock.resume()
assert(clock.active == 1)
now = 110
clock.press(1)
assert(clock.remaining[1] == 157.5)
assert(clock.active == 0 && clock.moves == [0,1])
clock.reset()
assert(clock.remaining == [180,180] && clock.moves == [0,0] && !clock.started)
clock.press(0)
now = 400
clock.update()
clock.press(1)
assert(clock.expired == 0 && clock.active == nil)
print("PASS: initial state, turn ownership, paused time, resume side, handoff, reset, expiration")
