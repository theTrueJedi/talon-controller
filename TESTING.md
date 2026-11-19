# Controller: hands-on checks

Firmware `firmware/knob/controller` is flashed and the add-on is live.
Mark each row ✅ / ❌ and note what you saw. **Quit and reopen Talon once
first**: it clears leftovers from the build's add-on reloads.

**Already verified by Claude (serial + Talon REPL, 2026-11-18):** PING/HELLO,
garbage lines ignored, knob events reach the Mac; in Talon: tap flips
command⇄dictation, hold mutes (mic → None) and restores your mic, tap while
muted is refused, double-tap sleeps and wakes.

| ID | Do this | Expect |
|---|---|---|
| T1 | Look at the ring with Talon running | Solid green (command) |
| T2 | Say "dictation mode", then "command mode" | Blue→purple spin, then green, within ~0.5 s |
| T3 | Tap the knob | Green double-beat, then mode flips ~¼ s after release |
| T4 | Double-tap | Amber slow breathe (asleep); double-tap again → back to the prior mode |
| T5 | Press and hold | Red fill sweeps clockwise; at 0.7 s solid red, mic is None |
| T6 | While muted, tap | Two red blinks, nothing changes |
| T7 | While muted, hold | Fill in green, then mic restored and ring back to the mode look |
| T8 | Turn the knob over a long page | Scrolls the window under the pointer; purple half-ring flash in the turn direction. Direction feel right? (`scroll_invert` if not) Amount OK? (`scroll_amount`) |
| T9 | Hold + turn | White gauge from 12 o'clock follows the knob; release → mode look at the new brightness |
| T10 | Unplug and replug the USB | Brightness kept; ring back on the mode look within ~3 s; `controller status` says connected |
| T11 | Quit Talon | After ~8 s: dim red slow breathe |
| T12 | Restart Talon while muted, then hold | Your previous mic comes back |
| T13 | Press 7 times quickly | White double-flash, rainbow spin; Talon untouched |
| T14 | Wait 10 s each | spin → wash → comet → breathing rainbow, repeating |
| T15 | In demo: tap | Next pattern, and it stays |
| T16 | In demo: double-tap | Back to cycling |
| T17 | In demo: turn, hold | Nothing (no scroll, no mute); hold + turn still sets brightness |
| T18 | Press 7 times again | White double-flash, back to the mode look |
| T19 | Press 3 times | Red blink, nothing happens |

**Judgment calls to report back:**

| ID | Question |
|---|---|
| J1 | Solid red (muted) vs dim red breathe (Talon down): can you tell them apart across the room? |
| J2 | Tap latency (~¼ s): acceptable? |
| J3 | Dim looks (sleep, disconnected) at the default 60 % brightness: visible enough, or too dim? |
| J4 | 43 % power cap (`HW_CAP`): bright enough at 100 %? |
| J5 | Does LED 0 sit at 12 o'clock? (else `RING_TOP` in `controller.ino`) |
