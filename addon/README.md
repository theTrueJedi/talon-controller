# Talon add-on

Mirrors Talon's state onto the controller's ring and turns knob gestures into
Talon actions. Standard library only (no pyserial, nothing to install).

## Install

Clone only the add-on straight into Talon (skips the STLs, print files and
firmware):

```
git clone --filter=blob:none --sparse https://github.com/theTrueJedi/talon-controller.git ~/.talon/user/talon-controller
cd ~/.talon/user/talon-controller && git sparse-checkout set addon
```

Update with `cd ~/.talon/user/talon-controller && git pull`. Keep the sparse
checkout: without it Talon would also load `tests/`.

For development (firmware, print files), clone the full repo elsewhere and link
just the add-on: `ln -s <repo>/addon ~/.talon/user/talon-controller`.

Talon loads it immediately. It finds the controller on its own
(`/dev/cu.usbmodem*` + a `HELLO` handshake) and reconnects after a replug.

## What the knob does

| Gesture | Action |
|---|---|
| tap | command ⇄ dictation (mixed → command; asleep → wakes into the last awake mode) |
| double-tap | command or dictation → sleep; mixed → dictation; asleep → wakes into the last awake mode |
| triple-tap | mixed (command + dictation); tap returns to command |
| hold 0.7 s | hard mute: mic → None; hold again restores it |
| turn | scroll the window under the pointer: clockwise = down the page (also while muted or asleep) |

Taps are refused while muted (the ring blinks red); only a hold unmutes.
The mic you muted from is saved in `addon/.last_mic` (git-ignored), so it
survives a Talon restart. If that mic is gone, unmute picks `System Default`.

**Switching machines:** if the controller disappears for 3 s (e.g. a USB
switch moved it to your other computer), this machine hard-mutes so it stops
hearing you. When the controller comes back, the mic is restored, unless you
picked a mic by hand meanwhile. A mute you made yourself is never undone.
Without a controller at Talon start nothing happens. Turn it off with
`settings(): user.talon_controller_auto_mute = false`.

## Voice commands

- `controller status` shows the connection and the ring's current state.
- `controller tuner` opens the look tuner at `http://127.0.0.1:8737`
  (this Mac only).

## Look tuner

One tab per mode with pattern, two colors, speed and brightness. The ring
shows the selected tab live (the knob keeps working); close the page, or
leave it 3 s without contact, and the ring returns to Talon's real mode.
**Save all** writes `addon/looks.json`, which Talon uses at once. Commit it
to carry your looks to another machine. Brightness on screen is approximate;
judge it on the ring.

Which look wins: a `settings():` override, then `looks.json`, then the
defaults below.

## Settings

Put overrides in any `.talon` file's `settings():` block. If clockwise scrolls
up on a machine (macOS scroll-direction setting), set `scroll_invert` to `True` there.

| Setting | Default |
|---|---|
| `user.talon_controller_scroll_amount` | `40` (pixels per detent) |
| `user.talon_controller_scroll_invert` | `False` |
| `user.talon_controller_scroll_by_lines` | `False` (pixels); `True` sends mouse-wheel notches, which snap carousels advance on |
| `user.talon_controller_scroll_lines` | `3` (notches per detent, used when `scroll_by_lines` is on) |
| `user.talon_controller_look_mute` | `solid ff1a1a b91818 40 70` |
| `user.talon_controller_look_sleep` | `solid ff8a0d c07414 12 55` |
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
