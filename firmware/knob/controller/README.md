# Controller firmware

The real firmware for the ring + knob: gestures, on-device looks, brightness
gauge, disconnect watchdog, demo mode. Talks to the Talon add-on (`addon/`)
over USB serial at 115200.

## Wiring

| From | To |
|---|---|
| Ring DIN | GPIO0 |
| KY-040 CLK / DT / SW | GPIO3 / GPIO4 / GPIO5 (internal pull-ups) |
| KY-040 + / ring 5V | 3V3 / 5V |

## Flash

```
export PATH=$HOME/.local/bin:$PATH
arduino-cli compile --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc firmware/knob/controller
arduino-cli upload  --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc -p $(ls /dev/cu.usbmodem* | head -1) firmware/knob/controller
```

The port name changes on replug. Quit Talon's hold on the port first only if
the upload can't connect (the add-on reconnects on its own afterwards).

## Host tests

All logic lives in `src/` (no Arduino headers) and is tested on the Mac:

```
bash firmware/knob/controller/test/run.sh
```

## Knob

| Gesture | Control mode | Demo mode |
|---|---|---|
| 1 press | `TAP` (sleep ⇄ wake) | next pattern, stay on it |
| 2 presses | `DOUBLE` (command ⇄ dictation) | back to cycling |
| 7 presses | enter demo (quick fade out/in) | leave demo |
| other counts | red blink, nothing sent | red blink |
| hold 0.7 s | `HOLD` (hard mute toggle), ring fills first | nothing |
| hold + turn | brightness gauge (saved on release) | same |
| turn | `ROT +1` / `ROT -1` (scroll) | nothing |

Presses count as one burst while each comes within 200 ms of the last
release; the burst acts 200 ms after the last release. An accepted tap or
double (and a demo pattern change) is acknowledged by a 250 ms fade out and
back in; the change swaps in at the dark point. While muted, taps
are still sent (Talon refuses them) and the ring blinks red.

## Protocol

| Direction | Line |
|---|---|
| device → host | `HELLO talon-controller v1` (boot, and reply to `PING`) |
| device → host | `TAP`, `DOUBLE`, `HOLD`, `ROT +1`, `ROT -1` |
| host → device | `PING` (every 2 s) |
| host → device | `LOOK <state> <pat> <c1> <c2> <speed> <bri>` |

`state`: mute, sleep, command, dictation, mixed, other. `pat`: solid,
breathe, gradspin (unknown → solid). Colors are 6 hex digits; speed and bri
are 0–100. No valid line for 8 s → the ring shows "disconnected" (dim red
breathe). Output is dropped, never blocks, when nothing reads the port; lines
queued while the port was closed arrive on the next open, so the host ignores
everything before `HELLO`.

## Tunables

| Constant | Where | Default |
|---|---|---|
| `HOLD_MS`, `DOUBLE_MS` | `src/gestures.h` | 700, 200 |
| `FADE_MS` | `src/render.h` | 250 |
| `DEMO_CYCLE_MS` | `src/demo.h` | 10000 |
| `WATCHDOG_MS` | `src/protocol.h` | 8000 |
| `RING_TOP`, `RING_CW` | `controller.ino` | 0, true |
| `HW_CAP` | `controller.ino` | 110 of 255 |
| `MASTER_DEFAULT` | `controller.ino` | 60 % |
