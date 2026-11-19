# Controller Firmware + Talon Add-on Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Real firmware for the ring+knob (gestures, on-device looks, brightness gauge, watchdog) and a Talon add-on that drives it over standard-library serial (mode/mute mirroring, tap/double/hold actions, knob scroll).

**Architecture:** Firmware logic lives in pure C++ (`src/`, no `Arduino.h`) so it is unit-tested on the Mac with `clang++`; the `.ino` only wires pins, NeoPixel, `Serial` and `Preferences` to it. The add-on is three pure-Python modules (protocol, policy, link) unit-tested with stdlib `unittest` + a pty, plus one Talon glue file that is verified live. The host sends **looks** (pattern + colors + speed + brightness), never frames, so a frozen Talon cannot freeze the ring on "listening".

**Tech Stack:** Arduino (arduino-cli at `~/.local/bin`, esp32 core 4.0.0, Adafruit NeoPixel 1.15.5, `Preferences`), C++17 host tests with `/usr/bin/clang++`; Talon 1.0 Python (3.14) using only `os`, `termios`, `fcntl`, `select`, `glob`; host tests with `/usr/local/bin/python3 -m unittest`.

**Spec:** `docs/superpowers/specs/2026-11-12-talon-controller-design.md` (+ amendments); looks from `docs/ring-design.json`.

## Global Constraints

- No pyserial, no installs: add-on imports only the stdlib and `talon`.
- Never edit `~/.talon/user/community`. Add-on is `addon/`, symlinked to `~/.talon/user/talon-controller`. Keep it out of `~/.talon/user/personal`.
- Pins: ring DIN GPIO0; KY-040 CLK GPIO3, DT GPIO4, SW GPIO5 (`INPUT_PULLUP`). Board LED GPIO10 free for debug. Avoid GPIO2/8/9/18/19.
- Encoder: **full-step, 4 edges per detent**; count one step only on returning to the rest state read at boot, `|accum| >= 3` (port from `firmware/knob/knob_test/knob_test.ino`). Knob CW = `+1` = ring CW.
- Button debounce 25 ms. Hold threshold `HOLD_MS = 700`. Double-tap window `DOUBLE_MS = 250`.
- Brightness: step 5 % per detent, floor 5 %, max 100 %, default 60 %, persisted in flash (`Preferences`, namespace `ctl`, key `master`), written only on release (flash wear).
- Watchdog: ring shows `disconnected` if no valid `LOOK`/`PING` for **8000 ms**; host sends `PING` every 2 s from `cron.interval` (main loop, not a thread).
- Protocol (newline-terminated ASCII, 115200, lines ≤ 95 chars):
  - Device → host: `HELLO talon-controller v1` (boot and reply to `PING`), `TAP`, `DOUBLE`, `HOLD`, `ROT +1`, `ROT -1`.
  - Host → device: `PING`; `LOOK <state> <pat> <c1> <c2> <speed> <bri>`, e.g. `LOOK command solid 18ff6a 109847 15 71`. `state ∈ mute|sleep|command|dictation|mixed|other`; `pat ∈ solid|breathe|gradspin` (unknown → solid); colors 6 hex digits; speed/bri 0–100.
- Default looks = `docs/ring-design.json` verbatim (mute, sleep, command, dictation, mixed). `other`: `solid ffffff 202020 0 20`. `disconnected`, `press` and `turn` flourishes are **firmware constants** from the same JSON (host can't be relied on for them). Note: the spec text says "breathing white" for disconnected; `ring-design.json` (Evan's later design) says red breathe — the JSON wins.
- Power: `HW_CAP = 110` (of 255) scales bri 100 × master 100 %, keeping 12 LEDs of white under ~350 mA.
- Firmware must never block on serial: `Serial.setTxTimeoutMs(0)` (HWCDC drops output when no host reads).
- Commits: simple `-m`, push after every commit. `git add` by path, never wholesale.

## Review Focus

1. **Port open resets or wedges the C3.** macOS asserts DTR on open; ESP32-C3 USB-Serial/JTAG resets on certain DTR/RTS sequences. Expected: opening/closing from Talon never reboots the device. Pinned by Task 1's live spike (log shows exactly one `HELLO` per open, from `PING`, not a boot banner twice).
2. **Unplug/replug while Talon runs** (port name changes, reads raise `OSError` EIO). Expected: no traceback spam, `controller status` says disconnected, reconnects within ~3 s of replug. Pinned by Task 8 (`test_read_error_drops_link`, `test_rescan_after_drop`) and Task 9 live check.
3. **Host silent while knob used** (Talon quit). Expected: ring goes red-breathe after 8 s, knob turns don't stall the render (non-blocking TX), brightness gauge still works. Pinned by Task 4 (`watchdog_*`) and Task 6 live check.
4. **Garbage / partial / overlong lines** in either direction (boot noise, a half line at connect). Expected: ignored, never crash, never refresh the watchdog. Pinned by Task 4 (`parse_rejects_*`, `overlong_line_dropped`) and Task 7 (`test_parse_device_garbage`).
5. **Mute fails or mic list changes** (remembered mic unplugged; `set_microphone` didn't take). Expected: ring shows what Talon actually reports afterwards; restore falls back to `System Default`. Pinned by Task 7 (`test_restore_mic_*`) and Task 9's re-read-after-action rule.

---

### Task 1: Serial spike — stdlib serial from Talon to the real device

Retires the spec's open risk before anything else is built.

**Files:**
- Create: `firmware/knob/serial_echo/serial_echo.ino`
- Create: `addon/serial_port.py`
- Create: `addon/talon_controller.py` (stub, replaced in Task 9)
- Test: `tests/addon/test_serial_port.py`

**Interfaces:**
- Produces: `class SerialPort` in `addon/serial_port.py`:
  - `SerialPort.open(path: str) -> SerialPort` (classmethod): `os.open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)`, termios raw (`cfmakeraw`-equivalent flags), 115200 in/out, `CLOCAL | CREAD`, keep `HUPCL` off. Skip baud/ioctl errors on non-tty fds only if `termios.error` (pty tests).
  - `write_line(text: str) -> None` (appends `\n`, writes all bytes; `BlockingIOError` → drop the line, never block).
  - `read_lines() -> list[str]`: drains available bytes via `select([fd],[],[],0)`, splits on `\n`, strips `\r`, keeps the partial tail buffered, drops buffered data over 256 bytes with no newline. Raises `OSError` when the device is gone (read returns `b""` after select said readable → raise `OSError("closed")`).
  - `close() -> None` (idempotent), `path: str`.
  - `candidates() -> list[str]`: `sorted(glob.glob("/dev/cu.usbmodem*"))`.

- [ ] **Step 1: Write the failing tests** (`unittest`, using `os.openpty()`; open the slave path via `os.ttyname(slave)`):
  - `test_round_trip`: write `b"HELLO talon-controller v1\r\nTAP\n"` to master → `read_lines() == ["HELLO talon-controller v1", "TAP"]`.
  - `test_partial_line_buffered`: write `b"RO"`, then `b"T +1\n"` → first read `[]`, second `["ROT +1"]`.
  - `test_overlong_without_newline_dropped`: 300 × `b"x"` then `b"TAP\n"` → result ends with `"TAP"` and contains no 300-char line.
  - `test_write_line`: `write_line("PING")` → master reads `b"PING\n"`.
  - `test_close_idempotent`.
  - Test files add the repo root to `sys.path` and `from addon.serial_port import SerialPort`; add empty `tests/__init__.py`, `tests/addon/__init__.py`. **Do not** put an `__init__.py` in `addon/` (Talon loads the folder itself).
- [ ] **Step 2:** `cd /Users/evan/git/talon-controller && python3 -m unittest discover -s tests -t .` → FAIL (module missing).
- [ ] **Step 3: Implement `addon/serial_port.py`** as above.
- [ ] **Step 4:** same command → PASS.
- [ ] **Step 5: Echo sketch.** `serial_echo.ino`: `Serial.begin(115200); Serial.setTxTimeoutMs(0);` prints `HELLO talon-controller v1` on boot and on each received `PING` line; echoes any other line as `ECHO <line>`; blinks GPIO10 board LED per line. Compile + upload:
  `arduino-cli compile --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc firmware/knob/serial_echo && arduino-cli upload --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc -p $(ls /dev/cu.usbmodem* | head -1) firmware/knob/serial_echo` → "Hard resetting".
- [ ] **Step 6: Talon stub + symlink.** `ln -s /Users/evan/git/talon-controller/addon ~/.talon/user/talon-controller`. Stub `talon_controller.py`: `from .serial_port import SerialPort, candidates` and `print("[talon-controller] loaded", candidates())`. Check `~/.talon/talon.log` shows the line (this also proves relative imports work from the hyphenated folder; if they don't, rename the symlink `talon_controller` and update CLAUDE.md).
- [ ] **Step 7: Live round trip in Talon's Python.** Pipe into `~/.talon/bin/repl`: open the first candidate, `write_line("PING")`, `write_line("hi")`, sleep 0.3 s, `read_lines()`, close; repeat open/close 3×. Expected each time: `["HELLO talon-controller v1", "ECHO hi"]` and **no** extra boot `HELLO` (Review Focus 1). If a reopen reboots the board, fix in `SerialPort.open` (clear `HUPCL`; set DTR/RTS explicitly via `fcntl.ioctl(fd, termios.TIOCMBIS/TIOCMBIC, ...)`) and re-run.
- [ ] **Step 8: Commit.**
  `git add addon/serial_port.py addon/talon_controller.py tests/ firmware/knob/serial_echo && git commit -m "Serial spike: stdlib serial port + echo sketch, verified from Talon" && git push origin`

### Task 2: Firmware input decoding (host-tested)

**Files:**
- Create: `firmware/knob/controller/src/input.h`, `src/input.cpp`
- Create: `firmware/knob/controller/test/test_main.cpp` (tiny `CHECK(cond)` macro + `TEST(name)` registry, nonzero exit on failure), `test/test_input.cpp`, `test/run.sh`
- Create: `firmware/knob/controller/controller.ino` (placeholder `setup(){} loop(){}` so the folder compiles)

**Interfaces:**
- Produces (pure C++, `<stdint.h>` only):
  - `class QuadDecoder { void begin(uint8_t restAB); int8_t feed(uint8_t ab); }` — returns `+1`/`-1` on a completed detent, else 0. Exact logic of `knob_test.ino` (QDEC table, rest-state counting, `|accum|>=3`, wiggle-back resets).
  - `class Debounce { explicit Debounce(uint16_t ms = 25); bool feed(uint32_t nowMs, bool raw); bool state() const; }` — `feed` returns true when the debounced state changed.
- `test/run.sh`: `clang++ -std=c++17 -Wall -Werror -I../src ../src/*.cpp *.cpp -o /tmp/ctl_tests && /tmp/ctl_tests` (cd to its own dir first; use `$TMPDIR`).

- [ ] **Step 1: Failing tests:** `quad_cw_full_cycle` (rest 3 → 1,0,2,3 sequence for CW as observed on this KY-040 = CLK<<1|DT; assert one `+1` only on the final edge), `quad_ccw_full_cycle` (reverse → `-1`), `quad_skipped_edge_still_counts` (3 valid edges + jump → still ±1), `quad_wiggle_back_no_step` (1 then 3 → 0, and next full cycle still gives exactly one step), `debounce_ignores_bounce` (toggles every 5 ms for 20 ms → no change), `debounce_accepts_after_25ms`.
  Derive the CW edge order from `knob_test.ino`'s QDEC table (CW = positive entries), not from memory.
- [ ] **Step 2:** `bash firmware/knob/controller/test/run.sh` → compile FAIL.
- [ ] **Step 3: Implement** `input.cpp`.
- [ ] **Step 4:** run.sh → all PASS; `arduino-cli compile --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc firmware/knob/controller` → success.
- [ ] **Step 5: Commit** `"Firmware: quadrature + debounce in host-tested src/"`, push.

### Task 3: Gesture state machine

**Files:** Create `src/gestures.h`, `src/gestures.cpp`, `test/test_gestures.cpp`

**Interfaces:**
- Consumes: debounced button edges and detents from Task 2 (the sketch passes them in).
- Produces:
  ```cpp
  enum class Out : uint8_t { None, Tap, Double, Hold, RotCW, RotCCW, BrightUp, BrightDown, AdjustEnd };
  class Gestures {
   public:
    Out onButton(uint32_t nowMs, bool pressed);
    Out onDetent(uint32_t nowMs, int8_t dir);   // dir = ±1
    Out onTick(uint32_t nowMs);                 // call every loop
    float holdProgress(uint32_t nowMs) const;   // 0..1 while a hold could still fire, else -1
    bool adjusting() const;                     // hold+turn brightness mode active
  };
  ```
- Rules (spec "Knob gestures"):
  - Release under `HOLD_MS` with no detent → pending tap; `onTick` emits `Tap` once `DOUBLE_MS` passes after release with no second press.
  - Second press within `DOUBLE_MS` of first release → `Double` **on that press**; the rest of that press is swallowed (no hold, no adjust, release emits nothing).
  - Held `HOLD_MS` with no detent → `Hold` from `onTick` at the threshold while still held; then detents return `None` until release; release emits `None`.
  - Detent while held before the threshold → enters adjust: returns `BrightUp`/`BrightDown` for that and each later detent; no tap/hold for this press; release returns `AdjustEnd`.
  - Detent while not pressed → `RotCW`/`RotCCW`. A detent during a pending tap's window passes through as rotation and does not cancel the tap.

- [ ] **Step 1: Failing tests** (each drives explicit timestamps): `tap_after_window` (press 0, release 100 → `onTick(349)` None, `onTick(351)` Tap), `double_on_second_press` (press 0/rel 100/press 300 → Double; release 400 → None; `onTick(1000)` None), `hold_fires_at_threshold_while_held` (press 0, `onTick(699)` None, `onTick(700)` Hold, release 900 → None, no Tap later), `hold_progress` (press 0 → `holdProgress(350)≈0.5`; after a detent → -1), `turn_while_held_adjusts` (press 0, detent +1 at 200 → BrightUp; `onTick(800)` None; release → AdjustEnd; no Tap), `rotation_ignored_after_hold`, `plain_rotation` (RotCW/RotCCW), `long_release_no_tap` (press 0 / release 800 after Hold → no Tap).
- [ ] **Step 2:** run.sh → FAIL. **Step 3:** implement. **Step 4:** run.sh → PASS.
- [ ] **Step 5: Commit** `"Firmware: gesture state machine (tap/double/hold/adjust)"`, push.

### Task 4: Protocol parsing + watchdog

**Files:** Create `src/protocol.h`, `src/protocol.cpp`, `test/test_protocol.cpp`

**Interfaces:**
- Produces:
  ```cpp
  struct Rgb { uint8_t r, g, b; };
  enum class Pat : uint8_t { Solid, Breathe, GradSpin };
  enum class State : uint8_t { Mute, Sleep, Command, Dictation, Mixed, Other };
  struct Look { State state; Pat pat; Rgb c1, c2; uint8_t speed, bri; };
  enum class MsgKind : uint8_t { Invalid, Ping, Look };
  struct HostMsg { MsgKind kind; Look look; };
  HostMsg parseHostLine(const char* line);
  class LineReader { bool feed(char c); const char* line() const; };  // true when a full line is ready; 95-char cap, overlong line discarded whole
  class Watchdog { void kick(uint32_t nowMs); bool expired(uint32_t nowMs) const; };  // 8000 ms; expired at boot until first kick
  ```
- Unknown `pat` → `Solid` (still valid). Unknown `state` → `Other`. speed/bri clamp to 100. Any other malformation → `Invalid`.

- [ ] **Step 1: Failing tests:** `parse_ping`, `parse_look_command` (the Global Constraints example → fields exact), `parse_unknown_pat_is_solid`, `parse_rejects_bad_hex` (`LOOK command solid 18ff6z ...`), `parse_rejects_missing_fields`, `parse_rejects_trailing_garbage`, `parse_clamps_bri` (`... 15 250` → 100), `linereader_strips_cr`, `overlong_line_dropped` (200 chars + `\n` then `PING\n` → only `PING` emitted), `watchdog_expired_at_boot`, `watchdog_kick_then_expire` (kick 1000 → not expired 8999, expired 9001), `watchdog_ignores_invalid` (the sketch kicks only on non-Invalid — assert via a helper `bool shouldKick(const HostMsg&)`).
- [ ] **Step 2–4:** run.sh FAIL → implement → PASS.
- [ ] **Step 5: Commit** `"Firmware: host protocol parser, line reader, 8 s watchdog"`, push.

### Task 5: Ring rendering

**Files:** Create `src/render.h`, `src/render.cpp`, `test/test_render.cpp`

**Interfaces:**
- Consumes: `Rgb`, `Look`, `Pat` (Task 4).
- Produces:
  ```cpp
  const int N_LEDS = 12;
  struct Frame { Rgb px[N_LEDS]; float level[N_LEDS]; };   // level 0..1 = bri fraction before master/cap
  void renderLook(const Look&, uint32_t nowMs, Frame&);
  void renderGauge(uint8_t masterPct, Frame&);                 // white, fill noon→CW, leading LED fractional
  void renderHoldProgress(float progress, Rgb color, Frame&);   // fill CW, leading LED fractional
  enum class Flourish : uint8_t { None, Press, Turn, Refuse };
  bool renderFlourish(Flourish, int8_t dir, uint32_t elapsedMs, Frame&);  // false when finished
  uint32_t toPixel(Rgb c, float level, uint8_t masterPct, uint8_t hwCap);  // gamma 2.6 on the final channel, returns 0x00RRGGBB
  int physIndex(int logical, int topIndex, bool cw);           // orientation; constants RING_TOP=0, RING_CW=true in the sketch
  extern const Look LOOK_DISCONNECTED;                        // breathe ff1a1a 202020 speed 9 bri 17
  ```
- Pattern math (playground source is not in the repo, so these are the definitions; Evan tunes speed/bri on the ring):
  - `solid`: all LEDs `c1`, level `bri/100`.
  - `breathe`: period `T = 10000 − 90·speed` ms; `k = (1 − cos(2π t/T))/2`; color `lerp(c2, c1, k)`, level `bri/100`.
  - `gradspin`: rev period `T = 8000 − 70·speed` ms; LED i color `lerp(c1, c2, tri(i/12 + t/T))` with `tri(x)` = triangle wave 0→1→0 over one unit (seamless loop).
  - Gauge: `masterPct/100 × 12` LEDs lit at level 1.0 (white `ffffff`); `toPixel` with that master shows the real brightness. 33 % → 3.96 LEDs: 3 full + 4th at 0.96.
  - Flourishes (from ring-design.json): `Press` green `18ff6a` bri 36 double-beat, 400 ms total (two 120 ms bumps, 80 ms gap); `Turn` purple `c03bff` bri 75 half-ring (6 LEDs) from noon in `dir`, fading out over 300 ms; `Refuse` red `ff1a1a` bri 70 two 100 ms blinks with 100 ms gap.
  - `toPixel`: perceived fraction `s = level · master/100`; each channel = `round(c · s^2.6 · hwCap/255)` (gamma 2.6, so the gauge's % matches what the eye sees). A channel with `c > 0` and `s > 0` is floored to ≥ 1, so a lit LED is never dark at the 5 % floor.

- [ ] **Step 1: Failing tests:** `solid_all_c1`, `breathe_extremes` (t=0 → c2, t=T/2 → c1 for the sleep look), `gradspin_loops` (frame at t=0 equals frame at t=T), `gauge_33pct` (LEDs 0–2 level 1, LED 3 ≈0.96, LEDs 4–11 level 0), `gauge_5pct_never_dark` (LED 0 level > 0 and `toPixel(white, level, 5, 110) != 0`), `hold_progress_half` (6 LEDs lit), `flourish_finishes` (`Press` returns false at 401 ms, `Turn` at 301, `Refuse` at 301), `turn_flourish_direction` (dir −1 lights LEDs 11..6), `physIndex_rotation` (`physIndex(0, 3, true)==3`, `physIndex(1, 3, false)==2`), `toPixel_gamma_monotonic` (level 0.25 < 0.5 < 1.0 outputs), `unknown_look_never_dark` (Solid with c1 000000 is the only dark case — document, don't fix).
- [ ] **Step 2–4:** run.sh FAIL → implement → PASS.
- [ ] **Step 5: Commit** `"Firmware: looks, gauge, hold progress, flourishes, gamma/cap"`, push.

### Task 6: Firmware sketch integration + flash

**Files:** Modify `firmware/knob/controller/controller.ino`; create `firmware/knob/controller/README.md`

**Interfaces:**
- Consumes everything in Tasks 2–5. Includes as `#include "src/input.h"` etc.

- [ ] **Step 1: Write the sketch.** `setup`: `Serial.begin(115200); Serial.setTxTimeoutMs(0);` pins per Global Constraints; `QuadDecoder.begin(readAB())`; load master from `Preferences` (`ctl`/`master`, default 60, clamp 5–100); print `HELLO talon-controller v1`. `loop` (no `delay`):
  1. Read serial bytes into `LineReader`; on a line: `PING` → reply HELLO + kick; `Look` → store as current (also store `lastAwake` when state ≠ Mute) + kick; Invalid → ignore.
  2. Feed debounce + decoder → `Gestures`; map `Out`: Tap/Double → `Serial.println`, then flourish `Refuse` if current state is Mute else `Press`; Hold → send `HOLD`; RotCW/CCW → `ROT +1`/`ROT -1` + `Turn` flourish; BrightUp/Down → master ±5 clamp 5–100; AdjustEnd → `Preferences.putUChar`.
  3. Render priority: adjusting → gauge; `holdProgress ≥ 0` (after 150 ms, so a tap doesn't flash) → progress in red if state ≠ Mute, else `lastAwake.c1`; active flourish; watchdog expired → `LOOK_DISCONNECTED`; else current look. Show at most every 16 ms via `physIndex` + `toPixel(..., master, HW_CAP)`.
- [ ] **Step 2:** `bash firmware/knob/controller/test/run.sh` → PASS; compile + upload (commands as Task 1 Step 5, path `firmware/knob/controller`) → success.
- [ ] **Step 3: Device checks over serial** (`stty -f <port> 115200 raw; cat <port>` in one shell, `printf 'LOOK command solid 18ff6a 109847 15 71\n' > <port>` in another):
  - Boot → red slow breathe (disconnected) and `HELLO` in the log.
  - Send the command LOOK → solid green; stop sending → red breathe after ~8 s.
  - `PING` → `HELLO` reply.
  - Tap → `TAP` ~250 ms after release + green double-beat; double-tap → `DOUBLE`; hold → red fill then `HOLD` at 0.7 s; turn → `ROT ±1` + purple half-ring.
  - Send `LOOK mute solid ff1a1a b91818 40 70`; tap → `TAP` still sent + red double-blink; hold → fill in green (lastAwake c1).
  - Hold + turn → white gauge follows; release; unplug/replug → brightness kept.
  - With nothing reading the port, spin the knob fast for 5 s → ring animation stays smooth (Review Focus 3).
- [ ] **Step 4:** README: flash commands, wiring, protocol table, constants to tune (`HOLD_MS`, `DOUBLE_MS`, `RING_TOP`, `RING_CW`, `HW_CAP`), how to run host tests.
- [ ] **Step 5: Commit** `"Firmware: controller sketch wiring gestures, protocol, looks, persisted brightness"`, push.

### Task 7: Add-on protocol + policy (pure Python)

**Files:** Create `addon/protocol.py`, `addon/policy.py`; Test `tests/addon/test_protocol.py`, `tests/addon/test_policy.py`

**Interfaces:**
- Produces in `addon/protocol.py`:
  - `@dataclass(frozen=True) class Look: pat: str; c1: str; c2: str; speed: int; bri: int`
  - `DEFAULT_LOOKS: dict[str, Look]` — keys `mute sleep command dictation mixed other`, values per Global Constraints.
  - `parse_look_setting(text: str, fallback: Look) -> Look` — `"<pat> <c1> <c2> <speed> <bri>"`, `#` optional on colors, invalid → `fallback`.
  - `format_look(state: str, look: Look) -> str` → `"LOOK command solid 18ff6a 109847 15 71"`.
  - `parse_device_line(line: str) -> tuple[str, int] | None` → `("TAP",0)`, `("DOUBLE",0)`, `("HOLD",0)`, `("ROT",±1)`, `("HELLO",0)`; anything else `None`.
- Produces in `addon/policy.py`:
  - `derive_state(modes: set[str], mic: str | None) -> str` — `mic in (None, "None")` → `mute`; else mode_indicator logic: `sleep` > (`dictation`+`command` → `mixed`) > `dictation` > `command` > `other`.
  - `class Intent(Enum): NONE, COMMAND, DICTATION, SLEEP, MUTE, UNMUTE`
  - `decide(event: str, state: str, last_awake: str) -> Intent` — spec "On TAP / DOUBLE / HOLD": TAP command→DICTATION, dictation→COMMAND, mixed→COMMAND, sleep→last_awake, other→COMMAND; DOUBLE awake→SLEEP, sleep→last_awake; TAP/DOUBLE while mute → NONE; HOLD mute→UNMUTE else MUTE. `last_awake ∈ {"command","dictation"}`.
  - `choose_restore_mic(remembered: str | None, available: list[str]) -> str` → remembered if in available and not `"None"`, else `"System Default"`.

- [ ] **Step 1: Failing tests:** `test_default_looks_match_ring_design` (load `docs/ring-design.json`, compare the five modes' pat/c1/c2/speed/bri), `test_format_look`, `test_parse_look_setting_hash_and_case`, `test_parse_look_setting_invalid_falls_back`, `test_parse_device_lines`, `test_parse_device_garbage` (`""`, `"ROT +2"`, `"TAPX"`, `"\x00\xff"`, boot-log text → None); `test_derive_state_table` (every row incl. mic `"None"` overriding sleep), `test_tap_table`, `test_double_table`, `test_mute_refuses_tap_double`, `test_hold_toggles`, `test_restore_mic_remembered`, `test_restore_mic_missing_falls_back`, `test_restore_mic_never_none`.
- [ ] **Step 2:** `python3 -m unittest discover -s tests -t .` → FAIL. **Step 3:** implement. **Step 4:** → PASS.
- [ ] **Step 5: Commit** `"Add-on: protocol + gesture policy (pure, unit-tested)"`, push.

### Task 8: Add-on link manager (discovery, handshake, reconnect)

**Files:** Create `addon/link.py`; Test `tests/addon/test_link.py`

**Interfaces:**
- Consumes: `SerialPort`, `candidates` (Task 1); `parse_device_line` (Task 7).
- Produces:
  ```python
  class Link:
      def __init__(self, list_ports=candidates, open_port=SerialPort.open, clock=time.monotonic): ...
      def tick(self) -> list[tuple[str, int]]   # call every 20 ms; returns device events except HELLO
      def send(self, line: str) -> bool          # False if not connected (never raises)
      connected: bool
      path: str | None
      def status(self) -> str                    # "connected /dev/cu.usbmodem101" | "searching" | "disconnected (<reason>)"
      def close(self) -> None
  ```
- Behavior, all non-blocking: not connected → at most one scan per 2 s; try candidates in order: open, send `PING`, wait up to 1.0 s (across ticks) for `HELLO`, else close and try the next. On `HELLO` → connected; set an `on_connect` flag the glue reads via `tick` returning `("CONNECTED",0)` once (so it pushes the current look). Any `OSError` from read/write → close, `connected=False`, return `("DISCONNECTED",0)` once. Don't re-raise or log more than once per drop.

- [ ] **Step 1: Failing tests** (fake clock; ports are pty pairs whose master side the test scripts):
  - `test_handshake_connects` (fake device replies HELLO to PING → `connected`, events include `("CONNECTED",0)`).
  - `test_wrong_device_skipped` (first candidate never answers → after 1.0 s fake time, second candidate connects).
  - `test_events_passed_through` (`TAP\nROT -1\n` → `[("TAP",0),("ROT",-1)]`).
  - `test_read_error_drops_link` (`open_port` returns a stub whose `read_lines` raises `OSError` → one `("DISCONNECTED",0)`, `connected False`, no exception).
  - `test_rescan_after_drop` (after drop, no scan before 2 s, scan at 2 s reconnects).
  - `test_send_when_disconnected_returns_false`.
- [ ] **Step 2–4:** unittest FAIL → implement → PASS.
- [ ] **Step 5: Commit** `"Add-on: non-blocking link manager with HELLO handshake and reconnect"`, push.

### Task 9: Talon glue + live end-to-end

**Files:** Replace `addon/talon_controller.py`; create `addon/talon_controller.talon`; modify `.gitignore` (add `addon/.last_mic`)

**Interfaces:**
- Consumes: `Link` (Task 8), `Look`, `DEFAULT_LOOKS`, `parse_look_setting`, `format_look` (Task 7), `derive_state`, `decide`, `Intent`, `choose_restore_mic` (Task 7).
- Produces (Talon):
  - Settings: `user.talon_controller_scroll_amount: int = 40`, `user.talon_controller_scroll_invert: bool = False`, `user.talon_controller_look_<state>: str` for each of the six states (defaults = `DEFAULT_LOOKS` formatted as setting strings).
  - Action: `user.talon_controller_status()` → `app.notify(link.status() + ", state " + state)`.
  - `.talon`: `controller status: user.talon_controller_status()` (no `mode:` header so it works in command mode; no sleep-mode exposure needed).

- [ ] **Step 1: Implement glue.** On `app.register("ready")`: `cron.interval("20ms", tick)`, `cron.interval("500ms", refresh)`, `cron.interval("2s", heartbeat)`, `registry.register("update_contexts", lambda *_: refresh())`.
  - `refresh()`: `state = derive_state(set(scope.get("mode")), actions.sound.active_microphone())`; track `last_awake` when state is command/dictation; when state ≠ last-sent state (or look setting changed) → `link.send(format_look(...))`.
  - `heartbeat()`: `link.send("PING")`.
  - `tick()`: for each event from `link.tick()`: `CONNECTED` → force a refresh push; `ROT` → `actions.mouse_scroll(y=dir * amount * (-1 if invert else 1))` (always, even muted/asleep); `TAP/DOUBLE/HOLD` → `decide(...)` then: COMMAND → `actions.user.command_mode()`, DICTATION → `actions.user.dictation_mode()`, SLEEP → `actions.speech.disable()`, MUTE → save current mic to `addon/.last_mic` (path from `os.path.dirname(os.path.realpath(__file__))`) then `actions.sound.set_microphone("None")`, UNMUTE → `actions.sound.set_microphone(choose_restore_mic(read_last_mic(), actions.sound.microphones()))`. **Always** call `refresh()` after an action (re-reads the real mic/mode — Review Focus 5); wrap each action in `try/except Exception` that logs once and still refreshes.
  - Wake from sleep: `command_mode()`/`dictation_mode()` already `mode.disable("sleep")`; also call `actions.speech.enable()` first.
- [ ] **Step 2:** `python3 -m unittest discover -s tests -t .` → PASS (glue isn't imported by tests; make sure no test imports `talon`).
- [ ] **Step 3: Live checks** (flash `controller` firmware; watch `tail -f ~/.talon/talon.log`; no tracebacks):
  - Within ~3 s of Talon start/save: ring shows the current mode's look; `controller status` → "connected …".
  - Say "dictation mode"/"command mode" → ring follows within 0.5 s.
  - Tap → command⇄dictation; double-tap → sleep (amber breathe); double-tap again → wakes into the prior mode.
  - Hold → Talon mic becomes None, ring solid red; tap now → refused (red blink, mode unchanged); hold → previous mic restored. Restart Talon while muted, hold → remembered mic restored.
  - Turn → window under the pointer scrolls; invert setting flips it.
  - Unplug/replug → status disconnected then reconnects ≤ 3 s; quit Talon → ring red-breathes after ~8 s (Review Focus 2, 3).
- [ ] **Step 4: Commit** `"Add-on: Talon glue (mode/mute mirroring, gestures, scroll, status)"` (add `addon/talon_controller.py addon/talon_controller.talon .gitignore`), push.

### Task 10: Docs + status

**Files:** Create `addon/README.md`, `TESTING.md`; modify `CLAUDE.md` (Status + Layout: `addon/` exists, `firmware/knob/controller/`)

- [ ] **Step 1:** `addon/README.md`: install (symlink command), settings with defaults, look-setting string format, `controller status`, how `.last_mic` works. `TESTING.md`: the Task 6 Step 3 and Task 9 Step 3 checks as a checklist table for Evan (row IDs T1…), plus "solid red vs red breathe readable across the room?" and "tap latency (~250 ms) acceptable?" rows.
- [ ] **Step 2:** Both test suites pass: `bash firmware/knob/controller/test/run.sh && python3 -m unittest discover -s tests -t .`.
- [ ] **Step 3: Commit** `"Docs: add-on README, TESTING checklist, status"`, push.

---

**Out of scope (unchanged open items in the spec):** work-laptop delivery (public repo vs copy), macro pad selection, WLED sign, headset mic fix, host-configurable flourish looks.
