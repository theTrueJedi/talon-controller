# Look tuner — design (v1)

Date: 2026-11-18 · Status: APPROVED by Evan 2026-11-18

## Intent

Tune the ring's per-mode looks live with sliders instead of one change per
chat message. Evan was iterating sleep's orange step by step.

## Approaches

| Approach | Outcome |
|---|---|
| **A. Local web page served by the Talon add-on** | **Chosen**: real sliders, no installs (work-laptop constraint) |
| B. Talon imgui panel | Rejected: imgui has no sliders, only buttons |
| C. Separate desktop app | Rejected: would fight Talon for the serial port; tkinter may be missing |

Talon owns the port and re-pushes the look, so previews must flow through Talon.

## Design

- Voice **"controller tuner"** opens `http://localhost:8737` (bound to 127.0.0.1 only).
- One tab per state (mute, sleep, command, dictation, mixed, other): pattern
  (solid/breathe/gradspin), color 1, color 2, speed and brightness sliders; Save; Revert.
- **Live preview:** the ring shows the selected tab's look within ~50 ms of each
  change, overriding the real mode; the LOOK keeps Talon's real state name, so the
  firmware's mute behavior is unchanged. The page heartbeats; closing it, or 3 s of
  silence, returns the ring to Talon's real state. The knob keeps working.
- **Save** writes `addon/looks.json` (committed, so the work laptop gets it); used at once.
- **Precedence:** a `settings():` override > `looks.json` > built-in defaults.
- The HTTP server runs on a daemon thread and only hands data to the main loop
  (Talon calls stay on the main thread); stopped on add-on reload; if 8737 is
  taken, one log line and no tuner.

## Not in v1 / gaps

Firmware-side looks (disconnected, fade, turn flash) and master brightness
(on-device, unknown to the host, so judge brightness on the ring). Low
brightness still steps coarsely (LED resolution).
