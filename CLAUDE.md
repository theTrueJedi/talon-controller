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
tests via `bash print/tests/run.sh`, STLs in `print/stl/`. Next: Evan prints
the fit and glow coupons, runs checkpoint (a)-(f) in `print/README.md`, and
solders the ring. Housing spec:
`docs/superpowers/specs/2026-11-16-talon-housing-design.md`.

**Design approved.** Next step is hardware prep, before any code:
1. Evan finds his parts. Confirmed 2026-11-16: ring, HY2.0-4P cables, F–F jumpers, KY-040, C3-Zero.
2. Confirm the models: ring pad labels, C3-Zero pinout, KY-040, F–F jumpers,
   HY2.0→2.54 mm cables, data USB-C cable. Board is now the ESP32-C3-Zero
   (spec amendment 2026-11-16b): count its GND holes, find header pins.
3. Check soldering supplies: solder, flux.

**After that:**
1. Confirm the wiring.
2. Write the plan with superpowers:writing-plans.
3. First plan task: confirm standard-library serial (no pyserial) can open,
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
