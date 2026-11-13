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

## Status (2026-11-13)

**Design approved.** Next step is hardware prep, before any code:
1. Evan finds his parts.
2. Confirm the models: ring pad labels, XIAO headers, KY-040, F–F jumpers,
   HY2.0→2.54 mm cables, data USB-C cable.
3. Check soldering supplies: solder, flux.

**After that:**
1. Confirm the wiring.
2. Write the plan with superpowers:writing-plans.
3. First plan task: verify that pyserial loads in Talon 1.0's Python.

**Separate project:** the headset mic fix. Suspected cause: Bluetooth HFP
low-quality mic mode.
