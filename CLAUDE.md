# talon-controller

Evan's Talon hardware: the ring+knob USB controller, and later the
room-scale WLED "on air" sign. Public (MIT, since 2026-11-19).

Evan's personal Talon commands and settings are NOT here. They live in the
public, MIT-licensed repo `theTrueJedi/talon`, cloned straight into
`~/.talon/user/personal` (same on the work machine, beside an unversioned
`work/` folder). Keep anything controller-related out of that repo.

## Layout

- `addon/`: the controller's Talon add-on (stdlib only), symlinked into
  `~/.talon/user/talon-controller`. Never edit `~/.talon/user/community`.
  Tests: `python3 -m unittest discover -s tests -t .` (tests live in `tests/`,
  outside `addon/`, so Talon never loads them).
- `firmware/knob/`: ESP32-C3-Zero firmware (Arduino) for the controller.
  The real one is `firmware/knob/controller/` (logic in `src/`, host tests
  `bash firmware/knob/controller/test/run.sh`); the rest are hardware tests.
- `firmware/sign/`: future WLED sign.
- `print/`: 3D-print files (housing, translucent cap).
- `docs/`
  - `docs/superpowers/specs/2026-11-12-talon-controller-design.md`: the
    approved design.
  - `docs/ring-design.json`: Evan's per-mode ring looks.

## Status (2026-11-18)

**Housing model built** in `print/`: parametric OpenSCAD, tests via `bash print/tests/run.sh`, STLs in
`print/stl/`. Spec: `docs/superpowers/specs/2026-11-16-talon-housing-design.md`.
Amended 2026-11-17 after the first test prints: the C3-Zero sits on a cradle
on the bottom plate, the base is 5 mm taller, four weights are sealed in the
plate (print pause), and the knob is 29 mm, 14 mm thick, diamond-knurled.
Wiring: one right-angle header on the C3; jumpers plug in only there.

**Diffuser + knob (2026-11-19, printing overnight):** white PLA, 100% infill (the 1.5 mm well floor felt thin at lower infill). Knob `cap_6mm_v1` (34 x 8.5 mm, 1.5 mm above the hood; Evan: no bigger gap) fits every `hood_6mm_*`:
`hood_6mm_v2` square, 0.8 top / 0.84 wall (2 loops), 720 segments, the main version (0.8 judged better than v2b);
`hood_6mm_v2b` 0.4 top / 0.42 wall (1 loop), gap 6.4, same height;
`hood_6mm_v2r` = v2 with a rounded top outer corner (3 mm arc to 50 deg from vertical, then a straight 50 deg run; support-free face down), opt-in via `hood_round_r=3`.
Evan to judge v2r vs v2 (corner print quality, even glow); the winner becomes the default. Hood/cap STLs are named by glow gap (`run.sh export` does it).

**Next (2026-11-18):** print `bottom_v9` and `c3_clip_v3` (shell stays v6), check (i)-(l) in `print/README.md`, glue the 15 x 60 TPU pads. Guide: `print/guide/talon-housing-guide.pdf`. Header legs still to measure (checkpoint h).
Amended 2026-11-18: plate lip, two-tooth clip, board 0.4 mm inward, port tab with hooks (pinches the board), 2x 15x60 TPU pads.

**Ring wired and passing (2026-11-18):** `firmware/knob/ring_test/` flashed via arduino-cli
(`~/.local/bin`, esp32 core 4.0.0, port `/dev/cu.usbmodem101`); ring on GPIO0, no
330 Ω resistor. Serial log: `stty -f <port> 115200 raw; cat <port>` (`arduino-cli monitor` exits without a TTY).

**Knob wired and passing (2026-11-18):** `firmware/knob/knob_test/`. KY-040 is **full-step: 4 edges
per detent**, passing through the opposite state mid-click. Count one step only on returning to the
rest state read at boot (|accum| >= 3 tolerates bounce; a truly skipped edge loses that click); counting at the mid-click state
double-fired (2 LEDs per click, fixed 2026-11-18); button clean with INPUT_PULLUP + 25 ms debounce. Direction confirmed: knob clockwise =
ring clockwise (pos++ with CLK=GPIO3, DT=GPIO4). The USB port name changes on replug (`ls /dev/cu.usbmodem*`).

**Firmware + add-on built (2026-11-18):** plan `docs/superpowers/plans/2026-11-18-firmware-and-addon.md` (plans are local-only, git-ignored since 2026-11-20).
Controller firmware flashed; add-on live and verified in Talon (tap/double/hold/mute restore).
Includes demo mode (7 presses). **Next:** Evan runs `TESTING.md` (T1-T19, J1-J5).

**Amended 2026-11-16** (see the spec's amendment section):
- Work-laptop constraint: prefer no installs beyond Talon files.
- Macro keys come from a separate off-the-shelf VIA pad bound in Talon
  (`key(f13)` etc.; verified).
- Open items:
  - Evan sends pad listings.
  - Evan checks his company's USB keyboard policy.
  - Pick the first macro set.
  - Work laptop: sparse clone of `addon/` only (see `addon/README.md`), decided 2026-11-19.

**Separate project:** the headset mic fix. Suspected cause: Bluetooth HFP
low-quality mic mode.
