# Talon add-on

Mirrors Talon's state onto the controller's ring and turns knob gestures into
Talon actions. Standard library only (no pyserial, nothing to install).

## Install

```
ln -s /Users/evan/git/talon-controller/addon ~/.talon/user/talon-controller
```

Talon loads it immediately. It finds the controller on its own
(`/dev/cu.usbmodem*` + a `HELLO` handshake) and reconnects after a replug.

## What the knob does

| Gesture | Action |
|---|---|
| tap | command ⇄ dictation (mixed → command; asleep → wakes into the last of the two) |
| double-tap | sleep ⇄ wake |
| hold 0.7 s | hard mute: mic → None; hold again restores it |
| turn | scroll the window under the pointer (also while muted or asleep) |

Taps are refused while muted (the ring blinks red); only a hold unmutes.
The mic you muted from is saved in `addon/.last_mic` (git-ignored), so it
survives a Talon restart. If that mic is gone, unmute picks `System Default`.

## Voice command

`controller status` shows the connection and the ring's current state.

## Settings

Put overrides in any `.talon` file's `settings():` block.

| Setting | Default |
|---|---|
| `user.talon_controller_scroll_amount` | `40` |
| `user.talon_controller_scroll_invert` | `False` |
| `user.talon_controller_look_mute` | `solid ff1a1a b91818 40 70` |
| `user.talon_controller_look_sleep` | `breathe ff9a1a 3a1c00 12 50` |
| `user.talon_controller_look_command` | `solid 18ff6a 109847 15 71` |
| `user.talon_controller_look_dictation` | `gradspin 9a3bff 2f6bff 30 83` |
| `user.talon_controller_look_mixed` | `gradspin 14e0ff 2f6bff 35 83` |
| `user.talon_controller_look_other` | `solid ffffff 202020 0 20` |

A look is `<pattern> <color1> <color2> <speed 0-100> <brightness 0-100>`.
Patterns: `solid`, `breathe`, `gradspin`. An invalid look falls back to
its default. The disconnected look and the flourishes live in the firmware.

## Tests

```
python3 -m unittest discover -s tests -t .
```
