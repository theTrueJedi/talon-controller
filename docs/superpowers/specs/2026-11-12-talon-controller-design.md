# Talon Controller — Design (MVP)

Date: 2026-11-12 · Status: APPROVED by Evan 2026-11-13 (5% brightness floor confirmed)
· Amended 2026-11-16: work-laptop constraint, no pyserial, separate macro pad
(see "Amendment 2026-11-16" at the end); knob gestures remapped (option A,
see "Knob gestures")

## Intent

A small USB desk controller for Talon Voice. A 12-LED ring glows in Talon's
current mode color, and a knob sits in the center of the ring. Tapping the
knob flips between command and dictation, double-tapping it sleeps or wakes
Talon, holding it hard-mutes the microphone, and turning it scrolls.

**Why:**
- **(a) Instant off when someone walks in.** One press, with no reliance on
  Talon hearing `talon sleep` correctly. Recognition is currently unreliable.
- **(b) A constant "is it listening?" reminder** that can be read from across
  the room. Evan often walks around with an earpiece, listening and sometimes
  issuing commands or dictating from afar. It works like an "on air" sign.
- **Scroll from the knob.** Evan explicitly wants this.

## Goals

- **Holding** the knob (~0.7 s) toggles a **hard mute**. Talon's microphone is
  set to `None` and restored to the previous microphone on the next hold.
  This is not a proxy for sleep.
- **Tapping** flips command ⇄ dictation. Evan does this constantly (added
  2026-11-16).
- **Double-tapping** toggles sleep/wake (added 2026-11-16).
- The ring shows Talon's state at a glance, with a distinct color for each
  state: mic muted, sleep, command, dictation, mixed.
- Turning the knob scrolls the window under the mouse pointer.
- Everything goes over one USB cable. No Wi-Fi, no cloud, no app beyond Talon.
- Room to grow: spare GPIO for future macro keys.

## Non-goals (MVP)

- The room-scale "fancy light" (WLED, 3D-printed sign). That is a later project
  using Evan's existing WLED gear.
- Fixing headset or microphone recognition (HFP Bluetooth suspicion). That is a
  separate project and is a prerequisite for comfortable use.
- Macro keys on this board. They come from a separate off-the-shelf pad
  (see Amendment 2026-11-16).
- Wireless operation away from the desk.

## Anti-goals

- **The ring must never show a stale "listening" state.** If Talon quits,
  crashes, or the add-on stops talking to the device, the ring must visibly
  change to a "not connected" state. A reminder that lies is worse than none.
- **Pressing the button must never fail silently.** If mute fails, the ring
  must not show muted.
- No soldering beyond the 3 ring joints plus wires soldered straight into
  the C3-Zero's holes and onto the KY-040's clipped pin stubs (amended
  2026-11-17: direct solder, no headers or jumpers). No parts that must be
  bought before the MVP works.

## Constraints

**Hardware Evan owns:**
- Waveshare ESP32-C3-Zero ×5, no headers (amended 2026-11-16; was the one
  Seeed XIAO ESP32C3, now saved for the WLED sign)
- EC Buying 12-LED WS2812B ring
- KY-040 rotary encoder with push switch
- Spare JST SM leads, 330 Ω resistors, capacitors, 74AHCT125

**Soldering:** three joints (5V, GND, DIN) on the ring's pads, plus wires
soldered straight into the C3-Zero's needed holes (7; no header pins) and
onto the KY-040's pins clipped to stubs. Evan has agreed to all three
(amended 2026-11-17: direct solder).

**Board limits:** the ESP32-C3 has **no native USB HID**, so it can't act as a
keyboard or mouse. Its built-in USB Serial/JTAG gives a CDC serial port, so all
host interaction goes through Talon over serial.

**Software:**
- Talon 1.0 on macOS, with talonhub/community installed at
  `~/.talon/user/community`. Do not edit those files.
- Evan's own code lives in a separate folder.

**Power:** USB 5V from the board's 5V pin. Cap brightness in firmware so the
ring stays well under USB current limits.

## Approaches considered

| Approach | Trade-off | Outcome |
|---|---|---|
| A. Macro pad + WLED light over Wi-Fi | Off-the-shelf firmware for the light, but a WLED device can't easily send a button press back to Talon. Two devices. | Deferred. Its light becomes the later fancy light. |
| B. **One USB device, custom firmware (ESP32-C3 + ring + knob)** | Small custom firmware and protocol to write. Uses parts Evan owns, one cable, two-way by design. | **Chosen** |
| C. Stream Deck + smart bulb | Polished, but costs money. Local control and pricing unverified. Not an "on air" look. | Rejected |

## Design

### Hardware wiring (my calls on pins; the builder may move them)

| From | To |
|---|---|
| Ring 5V / GND | C3-Zero 5V / GND |
| Ring DIN | C3-Zero GPIO0 via the 330 Ω series resistor, soldered inline in the DIN wire (optional; short wire makes it skippable) |
| KY-040 CLK / DT / SW | C3-Zero GPIO3 / GPIO4 / GPIO5 |
| KY-040 + | C3-Zero 3V3 |
| KY-040 GND | C3-Zero GND, shared with the ring GND (one GND hole: twist both wires together and solder them in as one) |

**Pins to avoid on the C3-Zero:** GPIO2, GPIO8, GPIO9 (boot strapping; GPIO9
is the BOOT button), GPIO10 (onboard WS2812 status LED; free to use as a
debug light), GPIO18/19 (USB). Confirm the pad layout against Waveshare's
pinout image before soldering. (Pin map updated 2026-11-17 with the housing.)

Solder every wire straight into its hole (no header pins, no jumpers); the
ring wires go through the housing's face slot before they are soldered to
the C3-Zero. Optionally put a 1000 µF
capacitor across the ring's power.

### Firmware (ESP32-C3-Zero)

Written in Arduino or CircuitPython; the builder chooses. Arduino (with
Adafruit NeoPixel) is the safer bet on the ESP32-C3, whose CircuitPython USB
support is limited.

**Knob gestures (remapped 2026-11-16, Evan chose option A; timings and edge
cases are my calls):**

| Gesture | Detection | Sends | Action |
|---|---|---|---|
| Tap | press + release under 0.7 s, no rotation, no second press within 250 ms | `TAP` | command ⇄ dictation |
| Double-tap | two taps, second press within 250 ms of the first release | `DOUBLE` | sleep ⇄ wake |
| Hold | held 0.7 s with no rotation; fires **at the threshold, while still held** | `HOLD` | toggle hard mute |
| Hold + turn | a detent turned while held, **before** the threshold | (nothing) | on-device brightness (below) |
| Turn | not pressed | `ROT ±1` | scroll |

- **Why this mapping:** the most frequent action gets the easiest gesture. The
  panic action ("someone walked in") becomes a deliberate press-and-hold that
  is hard to fumble.
- **Cost (accepted):** a tap waits about 250 ms for a possible second tap, and
  mute takes about 0.7 s instead of about 0.3 s.
- **Hold progress (my call):** while held with no rotation, the ring fills
  clockwise as a 0.7 s progress bar. It fills red when the hold will mute and
  in the mode color when it will unmute. This is rendered on the device, so
  it has no host latency. Releasing early, or turning, cancels it.
- **After `HOLD` fires (my call):** ignore rotation until release, so a hold
  never drifts into a brightness change. Release sends nothing more.
- **While the ring shows `mute` (my call):** `TAP` and `DOUBLE` are refused.
  The device does a quick red double-blink, so the press is never silently
  ignored. Only a hold unmutes, which keeps unmuting deliberate. The device
  still sends the event; the host also refuses it.
- **Timings (my call):** 250 ms double-tap window and 0.7 s hold threshold, as
  firmware constants. Tune them on the real knob.
- **Hold + turn** → on-device master brightness. Handled entirely in firmware,
  so it works without Talon. On release the ring returns to the mode look.
  - **Gauge (Evan's spec):** while held, the ring is solid WHITE and fills
    clockwise from 12 o'clock. Fill fraction = brightness %, and those LEDs
    shine at exactly that brightness, live. Example: 33% → white at 33%,
    filling noon to 4 o'clock (4 of 12 LEDs).
  - **Smooth fill (my call):** the leading LED is lit fractionally between
    steps.
  - **Step (my call):** 5% per detent, so one full turn of 20 detents covers
    0–100%.
  - **Floor (my call):** minimum 5%, so the ring is never fully dark. Dark
    would read as "unplugged".
  - **Perceived brightness (my call):** gamma-correct so the % matches what
    the eye sees.
  - **Orientation (my call):** firmware settings for which LED index is
    12 o'clock and for direction, so the housing need not align the ring
    exactly.
  - Any detent while held, before the hold threshold, cancels the tap and the
    hold, so neither the mode flip nor the mute fires.
  - Persist the level in flash.
  - Master brightness multiplies the per-mode brightness.
- **Turn** (not pressed) → `ROT ±1` to the host for scrolling.

**Device → host**, one newline-terminated line per event:
- `TAP` / `DOUBLE` / `HOLD` (debounced; see gestures; replaces the earlier `BTN`)
- `ROT +1` / `ROT -1` per detent
- `HELLO talon-controller v1` on boot, and in reply to `PING`

**Host → device:**
- `MODE <name>`, where name is `mute|sleep|command|dictation|mixed|other`
- `PING`

**Connection loss:** if no `MODE` or `PING` arrives for 8 s, the ring shows
"disconnected": a slow dim white breathe. The host sends `PING` every 2 s.

**Ring rendering:** solid color per mode at a capped brightness.
- `mute`: solid red. This is unmistakable and matches the "on air" reading:
  red means the mic is hard off.
- Other mode colors are host-side settings, so the firmware just renders
  `MODE` as RGB.

  > Simplification: the host may send `RGB r g b` instead of `MODE` names. The
  > builder picks one. Prefer `RGB` so all colors are configured in Talon.

### Talon add-on (`~/.talon/user/talon-controller/`)

- **Serial port:** find the device by USB VID/PID or the `HELLO` handshake.
  Reconnect automatically on unplug or replug.
  - **No pyserial (amended 2026-11-16).** Open `/dev/cu.usbmodem*` with
    Python's standard library (`os`, `termios`, `fcntl`, `select`). Verified:
    Talon 1.0's bundled Python (3.14) imports all four, so nothing needs to be
    installed.
- **Mode tracking:** mirror the community `mode_indicator` logic.
  - `registry.register("update_contexts", ...)` for mode changes.
  - Poll `actions.sound.active_microphone()` for mute.
  - Push state on every change plus a heartbeat.
- **On `TAP` (my calls on edge cases):**
  - Command → dictation, and dictation → command.
  - Mixed → command.
  - Asleep → wake into the last of command/dictation.
  - Ignored while hard-muted (see gestures).
  - Then push the state.
- **On `DOUBLE`:**
  - Awake → sleep.
  - Asleep → wake into the last of command/dictation.
  - Ignored while hard-muted.
  - Then push the state.
  - The builder picks the Talon calls, mirroring community's
    `talon sleep` / `talon wake` and mode commands.
- **On `HOLD`:**
  - If the mic is not `None`: remember the current mic, then switch to `None`.
  - Otherwise: restore the remembered mic. Fall back to `System Default`.
  - Then push the state.
- **Remembered mic survives restarts (my call):** persist the last real
  (non-`None`) microphone to a small file in the add-on folder. Restore order:
  1. the remembered mic
  2. if that is unavailable, `System Default`
- **Heartbeat proves Talon is alive (my call):** send `PING` from Talon's main
  loop (`cron.interval`), not a background thread. A hung Talon then turns the
  ring "disconnected" instead of staying green. To avoid false alarms when
  Talon is merely busy, the device timeout is 8 s, not 5 s.
- **On `ROT`:** `actions.mouse_scroll(y=±N)`, scrolling the window under the
  pointer. Expose N as a setting (`user.talon_controller_scroll_amount`).
  Direction is invertible via a setting. **The knob always scrolls**,
  including while muted or asleep (Evan's decision). It cannot scroll while
  Talon is down, since Talon performs the scroll.
- **Colors:** settings per mode. Defaults (my call):

  | State | Color |
  |---|---|
  | mute | red |
  | sleep | dim amber |
  | command | green |
  | dictation | blue |
  | mixed | cyan |
  | disconnected | breathing white |

- **Voice command:** `controller status` shows the connection state, for
  debugging.

### Housing (Evan, 3D-printed, Bambu)

Superseded by the housing design:
`docs/superpowers/specs/2026-11-16-talon-housing-design.md`. The parametric
model and print notes live in `print/` (see `print/README.md`).

### Ring looks (Evan's playground design, 2026-11-12)

Source of truth: `docs/ring-design.json`. Brightness and speed are 0–100
playground units; calibrate on the real ring.

| State | Look |
|---|---|
| Hard mute | solid red, 70 |
| Sleep | amber breathe, slow (12), 25 |
| Command | solid green, 71 |
| Dictation | blue → purple gradient spin, 83 |
| Mixed | cyan → blue gradient spin, 83 |
| Disconnected | red breathe, very slow (9), dim (17) |
| Knob press flourish | green heartbeat pulse, fast, 36 |
| Knob turn flourish | purple half-ring, 75 |

**Red now means "not listening"**: solid for mute, a dim slow breathe when
Talon is down. Both mean "safe to talk". Telling them apart relies on solid
vs. breathing, which may be hard to read across a room. Check this on the
real ring.

### Pattern library (extensible by design)

- Animations run on-device. The host sends look parameters (pattern, c1, c2,
  speed, brightness), not frames, so a frozen Talon can never freeze an
  animation mid-"listening".
- Patterns are a firmware registry: one function per pattern. Adding one later
  means a new entry plus a Talon setting value, with no protocol change.
- The MVP ships with the patterns Evan picks in the ring playground. Evan will
  supply more explicit pattern specs later. Prototype new ones in the
  playground first, then port them to firmware.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| 3.3 V data into a 5 V WS2812B ring may flicker | Moderate | Short data wire, series resistor. The 74AHCT125 is the fallback, but needs more wiring. |
| Ring visibility at 4–5 m in daylight | Moderate | Diffusing disc. The fancy WLED light is the real answer later. |
| Serial from Talon's Python | FYI (was Moderate) | Standard-library serial, verified importable on Talon 1.0. Confirm a real open/read/write against the device in the plan's first task. |
| Encoder bounce causes jittery scroll | FYI | Use a quadrature state-table decode in firmware. |

## Left to the builder

- Arduino vs CircuitPython.
- Exact pins.
- `RGB` vs `MODE` protocol.
- Debounce timing.
- Reconnect strategy details.
- Repo layout. Firmware and add-on live in this repo; the add-on is symlinked
  into `~/.talon/user/`.

## Amendment 2026-11-16 (approved by Evan)

### New constraint: the work laptop

Evan must use the controller **and** the macro pad on his work laptop, a
company-managed Mac. Talon and accessibility peripherals are allowed there.
Evan is wary of installing custom software, management tools, or dependencies.

- **Strong preference, not a hard rule:** nothing installed on the work laptop
  beyond Talon user files (`.talon`, `.py`). If something genuinely needs
  installing, weigh cost against benefit and test it on the work laptop before
  relying on it.
- Consequence: drop pyserial (see the Talon add-on section).
- **Delivery to the work laptop (open):** Evan has cloned the public community
  repo there and created `.talon` files by hand. This repo is private, so
  cloning it would mean signing in to a personal GitHub account on a corporate
  device. Options:
  1. A publicly cloneable home for the Talon user files: make this repo
     public, or move `user/` into its own public repo. Recommended.
  2. Manual copy.

  Decide before the first deploy to the work laptop.

### Macro keys: a separate off-the-shelf pad

Evan wants 4–12 keys for daily macros, with knobs a bonus. Examples: start
Antigravity voice/live, mute/unmute Google Meet. He expects the list to grow
quickly. All macros run through Talon so they can be complex, e.g. find the
Meet tab, focus it, press ⌘D, and return.

| Approach | Trade-off | Outcome |
|---|---|---|
| Buttons on the custom board | Soldering per key; still Talon-only | Rejected |
| DIY second board on a XIAO ESP32-S3 (native USB HID) | Cheap, but solder time for something buyable | Rejected for now |
| **Off-the-shelf VIA/Vial macro pad, bound in Talon** | Costs money; no solder; real keycaps, knobs, often RGB | **Chosen** |

**Design:**
- The pad is a plain USB keyboard. Each key sends an unused code from
  **F13–F19**, alone or with modifiers (e.g. `ctrl-shift-f13`). That gives
  dozens of codes across keys and layers. F20 and up may not be recognized by
  macOS (unverified).
- **Configure the pad in VIA on the personal Mac only.** The settings are stored
  on the pad. Chrome's device access (WebHID) may be blocked by policy on the
  work laptop.
- Talon binds the codes with `key(...)` rules in `.talon` files. **Verified
  2026-11-16 on Talon 1.0:** `key(f13)` and `key(ctrl-shift-f19)` fire,
  including while Talon is asleep, with no `mode:` header. Caveat: tested with
  key events synthesized inside Talon, not a hardware press. Confirm on the
  first real press.

**Pad selection filter:**
- **Required:** VIA or Vial, ideally auto-detected from VIA's list rather than
  a seller-supplied JSON file. Avoid vendor-app-only pads.
- **Wired** preferred.
- **Bonus:** per-key RGB controllable in VIA, hot-swap sockets, 12–16 keys or
  layers, VIA-configurable knobs.
- **Tiebreaker:** public QMK source. That keeps open a later stretch goal:
  Talon drives key colors, e.g. the Meet key glows red while muted.
- **Budget:** under ~$50 preferred, up to ~$100 or more for real convenience.

**Risks:**

| Risk | Severity | Mitigation |
|---|---|---|
| Managed-Mac security tooling flags or blocks new USB keyboards | Moderate | Evan checks company peripheral policy before buying |
| Meet mute needs the Meet tab focused | Moderate | Macro design: find and focus the tab, then press ⌘D, then return |

**Open:**
- Which pad.
- The first macro set.
- Work-laptop delivery (above).

## Amendment 2026-11-16b: board swap to ESP32-C3-Zero (approved by Evan)

- **Why:** Evan has 5 Waveshare ESP32-C3-Zero boards and only one XIAO.
  Spares make soldering mistakes cheap, and the XIAO is saved for the WLED sign.
- **Same chip, same USB serial path.** The C3-Zero has no USB-to-UART chip; it
  uses the ESP32-C3's built-in USB Serial/JTAG, like the XIAO. Protocol,
  firmware logic and the Talon add-on are unchanged. Arduino needs
  "USB CDC On Boot: Enabled". Source: Waveshare wiki, ESP32-C3-Zero.
- **Cost:** wires must be soldered straight into the holes in use
  (amended 2026-11-17: direct solder, no header pins).
- **Flashing:** Waveshare says to hold BOOT (GPIO9) while plugging in USB to
  flash. Expect this at least for the first upload.
- **Antenna:** onboard ceramic. Irrelevant (no Wi-Fi), but don't cover it with
  metal in the housing.
- **Open:** count the GND holes. With one GND, the ring and knob grounds must
  share it (twisted together in the one hole). Measure the board for the housing.

## Amendment 2026-11-18: demo mode (approved by Evan)

**Intent:** lights only, for fun; Evan won't use it often. No control of the PC while in it.

- **Press bursts replace the instant double-tap.** The device counts presses in a quick burst (each within 250 ms of the last release) and acts when the burst ends: 1 = tap, 2 = double, 7 = enter/leave demo, any other count = red "refused" blink. Cost (accepted by Evan): double-tap fires ~250 ms later. Only a burst's first press can hold or hold+turn.
- **Demo mode:** handled entirely on the device; Talon is not told.
  - Starts cycling the four rainbow effects from `firmware/knob/rainbow/` (spin, wash, comet, breathing rainbow), 10 s each.
  - 1 press: next pattern, and stay on it. 2 presses: back to cycling. 7 presses: back to control mode.
  - Sends nothing to the host for any gesture; ignores host looks and the 8 s disconnect watchdog.
  - Hold + turn still sets brightness (my call). Plain turn and hold do nothing (my call).
  - A quick white double-flash on entering and leaving (my call).
  - Always boots into control mode, never demo (my call).
- **Accepted by Evan:** demo deliberately breaks the "never stale" anti-goal (the ring no longer shows Talon's state), no mute on entering demo.
- **Approaches:** device-side (chosen); Talon-driven demo (rejected: dies when Talon is down, and demo needs no PC).

## Amendment 2026-11-18b: ring tweaks (Evan)

- Press-burst window 250 → **200 ms**.
- The green press heartbeat and the white demo double-flash are replaced by one **250 ms fade out and back in**; the change swaps in at the dark point. Also used for demo pattern changes. The red "refused" double-blink stays.
- Gradient spins and demo rainbow spins move **clockwise**.
- Colors are treated as screen (sRGB) colors and decoded per channel before reaching the LEDs, so ring colors match the playground (command green had read as teal).
- Dictation is **mostly purple with some blue**: gradspin draws c1 over ~70 % of the ring (squared gradient), and dictation's colors are now c1 purple `9a3bff`, c2 blue `2f6bff` (also in `docs/ring-design.json`). Mixed becomes mostly cyan with a blue band.
- Turn flash: both directions start at noon; clockwise lights 12→5, counter-clockwise 12→7.
- Sleep: brightness 25 → 60 and breathe low point 3a1c00 → c07414 (same orange at 75 %). At the old settings the LEDs rounded to one step of pure red.
- Sleep is now **solid** orange at 60: the breathe visibly stepped (too few LED levels at that brightness).
- Sleep orange deepened ff9a1a → ff7a00.
- Sleep: split the difference, ff8a0d at brightness 55 (LED [6,2,0] at master 60).

## Amendment 2026-11-19: triple-tap = mixed mode

- A 3-press burst is now `TRIPLE` (was refused); 4-6 presses stay refused, 7 stays demo.
- `TRIPLE` enters mixed mode (command + dictation together) from any awake state or sleep; refused while muted.
- Tap from mixed or dictation returns to command (unchanged). Mixed now counts as an awake mode, so sleep wakes back into it.
- The add-on enables mixed itself (`mode.enable` command + dictation) rather than calling `user.mixed_mode` from Evan's personal repo, so it stays self-contained for others.

## Amendment 2026-11-19: auto-mute when the controller switches away

**Why:** Evan moves the controller between two machines on a USB switch, usually with the headset (WT-6 buds or Yealink). The machine left behind falls back to its built-in mic and keeps acting on speech meant for the other one.

**Approaches:** (1) hard mute on loss, (1b) the same but only after the controller was seen, with automatic restore on return, (2) sleep on loss, (3) watch the mic for a built-in fallback. Picked **1b**: (2) fails because "wake up" wakes both machines; (3) misses the times the headset doesn't switch; plain (1) blocks use without a controller.

**Behavior:**
- The controller connected, then gone for 3 s (`AUTO_MUTE_GRACE_S`; a hub blip shorter than that does nothing): mute exactly like a hold (save the mic, mic → None) and mark it automatic. Mode untouched. If the mic is already None (Evan muted by hand), nothing is marked.
- On reconnect: if marked AND the mic is still None, restore the saved mic. The mark always clears on reconnect, so a manual unmute or mic pick while away is never overridden.
- No controller at Talon start: nothing happens.
- The mark persists in `addon/.auto_muted` (git-ignored) so it survives a Talon restart.
- Setting `user.talon_controller_auto_mute` (bool, default on).
- Unplug is detected immediately (the port read fails), so the grace is the only delay.

## Amendment 2026-11-20: double-tap shortcut to dictation (Evan)

- Double-tap from **mixed** goes straight to dictation (mirrors tap taking mixed to command), so dictation no longer needs a trip through command.
- Double-tap from command or dictation still sleeps. From sleep, tap or double-tap still wakes into the last awake mode (a same-day draft sent sleep to dictation; Evan reverted it).
- Cost: sleeping from mixed is now two double-taps (mixed → dictation → sleep), or say it.

## Amendment 2026-11-23: tap and double-tap swapped (Evan)

Supersedes every earlier tap/double-tap description in this spec. Add-on only; the firmware is unchanged.

- **Tap** = sleep from any awake mode (including mixed); from sleep, wake into the last awake mode.
- **Double-tap** = command ⇄ dictation. Mixed → command (Evan, replaces the 2026-11-20 shortcut); asleep → wakes into the last awake mode (kept).
- Cost: mixed → dictation is now two double-taps, or say it. Sleeping from mixed is now one tap.
