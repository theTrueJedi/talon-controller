# talon

Evan's Talon Voice setup. It currently holds the ring+knob USB controller
project. The room-scale WLED "on air" sign and custom Talon commands come
later.

## Layout (planned)

- `user/`: Talon add-ons and custom commands, symlinked into `~/.talon/user/`.
  Never edit `~/.talon/user/community`.
- `firmware/knob/`: ESP32-C3-Zero firmware (Arduino) for the controller.
- `firmware/sign/`: future WLED sign.
- `print/`: 3D-print files (housing, translucent cap).
- `docs/`
  - `docs/superpowers/specs/2026-11-12-talon-controller-design.md`: the
    approved design.
  - `docs/ring-design.json`: Evan's per-mode ring looks.

## Status (2026-11-17)

**Housing model built** in `print/`: parametric OpenSCAD, tests via `bash print/tests/run.sh`, STLs in
`print/stl/`. Spec: `docs/superpowers/specs/2026-11-16-talon-housing-design.md`.
Amended 2026-11-17 after the first test prints: the C3-Zero sits on a cradle
on the bottom plate, the base is 5 mm taller, four weights are sealed in the
plate (print pause), and the knob is 29 mm, 14 mm thick, diamond-knurled.
Wiring: one right-angle header on the C3; jumpers plug in only there.

**Next:** Evan measures the header and jumpers when they arrive (checkpoint
(h) in `print/README.md`) and his USB-C plug (checkpoint g), then prints
`bottom`, `shell` and `cap`.

**Later:** write the firmware and add-on plan with superpowers:writing-plans.
Its first task: confirm standard-library serial (no pyserial) can open,
read, and write the device from Talon 1.0.

**Amended 2026-11-16** (see the spec's amendment section):
- Work-laptop constraint: prefer no installs beyond Talon files.
- Macro keys come from a separate off-the-shelf VIA pad bound in Talon
  (`key(f13)` etc.; verified).
- Open items:
  - Evan sends pad listings.
  - Evan checks his company's USB keyboard policy.
  - Pick the first macro set.
  - Decide how Talon files reach the work laptop.

**Separate project:** the headset mic fix. Suspected cause: Bluetooth HFP
low-quality mic mode.
