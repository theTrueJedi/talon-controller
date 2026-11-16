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
- No soldering beyond the 3 ring joints. No parts that must be bought before
  the MVP works, except jumper wires if Evan has none.

## Constraints

**Hardware Evan owns:**
- Seeed XIAO ESP32C3 (headers pre-soldered)
- EC Buying 12-LED WS2812B ring
- KY-040 rotary encoder with push switch
- Spare JST SM leads, 330 Ω resistors, capacitors, 74AHCT125

**Soldering:** only the ring needs it. Three joints (5V, GND, DIN) on the
ring's pads, which Evan has agreed to.

**Board limits:** the ESP32-C3 has **no native USB HID**, so it can't act as a
keyboard or mouse. Its built-in USB Serial/JTAG gives a CDC serial port, so all
host interaction goes through Talon over serial.

**Software:**
- Talon 1.0 on macOS, with talonhub/community installed at
  `~/.talon/user/community`. Do not edit those files.
- Evan's own code lives in a separate folder.

**Power:** USB 5V from the XIAO's 5V pin. Cap brightness in firmware so the
ring stays well under USB current limits.

## Approaches considered

| Approach | Trade-off | Outcome |
|---|---|---|
| A. Macro pad + WLED light over Wi-Fi | Off-the-shelf firmware for the light, but a WLED device can't easily send a button press back to Talon. Two devices. | Deferred. Its light becomes the later fancy light. |
| B. **One USB device, custom firmware (XIAO + ring + knob)** | Small custom firmware and protocol to write. Uses parts Evan owns, one cable, two-way by design. | **Chosen** |
| C. Stream Deck + smart bulb | Polished, but costs money. Local control and pricing unverified. Not an "on air" look. | Rejected |

## Design

### Hardware wiring (my calls on pins; the builder may move them)

| From | To |
|---|---|
| Ring 5V / GND | XIAO 5V / GND |
| Ring DIN | XIAO D10 via the 330 Ω series resistor, if it can be inserted without solder; otherwise direct |
| KY-040 CLK / DT / SW | XIAO D1 / D2 / D3 |
| KY-040 + / GND | XIAO 3V3 / GND |

Use female–female jumpers between the header pins. Optionally put a 1000 µF
capacitor across the ring's power.

### Firmware (XIAO ESP32C3)

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

- Knob shaft through the center of the ring.
- A custom cap: a narrow stem through the ring opening, widening to a graspable
  disc above it.
- Print the disc in translucent PETG so it acts as the diffuser. Use an opaque
  rim so light exits the top and sides.
- Measure first: the ring's inner and outer diameter, and the cap and shaft
  dimensions.

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
