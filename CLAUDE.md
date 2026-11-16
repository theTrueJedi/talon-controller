# talon

Evan's Talon Voice setup. It currently holds the ring+knob USB controller
project. The room-scale WLED "on air" sign and custom Talon commands come
later.

## Layout (planned)

- `user/`: Talon add-ons and custom commands, symlinked into `~/.talon/user/`.
  Never edit `~/.talon/user/community`.
- `firmware/knob/`: XIAO ESP32C3 firmware (Arduino) for the controller.
- `firmware/sign/`: future WLED sign.
- `print/`: 3D-print files (housing, translucent cap).
- `docs/`
  - `docs/superpowers/specs/2026-11-12-talon-controller-design.md`: the
    approved design.
  - `docs/ring-design.json`: Evan's per-mode ring looks.

## Status (2026-11-16)

**Design approved.** Next step is hardware prep, before any code:
1. Evan finds his parts.
2. Confirm the models: ring pad labels, XIAO headers, KY-040, F–F jumpers,
   HY2.0→2.54 mm cables, data USB-C cable.
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
