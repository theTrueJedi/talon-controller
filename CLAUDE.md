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

**Housing model built** in `print/` (branch `housing`): parametric OpenSCAD,
tests via `bash print/tests/run.sh`, STLs in `print/stl/`. Housing spec:
`docs/superpowers/specs/2026-11-16-talon-housing-design.md`.

**Next:** Evan measures his USB-C plug (checkpoint g), prints the fit and
glow coupons, runs checkpoint (a)-(g) in `print/README.md`, and solders the
ring. Wiring is direct solder, no headers or jumpers; pin map in
`print/README.md`.

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
