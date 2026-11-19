# Ring test

Lights the 12-LED ring from the C3-Zero with nothing else attached. This
checks the three ring joints and the data line before the knob or the real
firmware exist.

Wiring: ring 5V to header pin 1 (5V), GND to pin 2, DIN to pin 4 (GPIO0).

## Flash it (Arduino IDE 2, free)

1. Install Arduino IDE 2 from arduino.cc/en/software.
2. Open Boards Manager and install **esp32 by Espressif Systems**.
3. Open Library Manager and install **Adafruit NeoPixel**.
4. Open `ring_test.ino`. Set these Tools menu options:
   - Board: **ESP32C3 Dev Module**
   - USB CDC On Boot: **Enabled**. Without this you get no serial log.
   - Port: the `/dev/cu.usbmodem…` entry.
5. Upload. If it won't connect, hold **BOOT**, tap **RESET**, let go of
   BOOT, and upload again.
6. Open Serial Monitor at 115200 baud. Each step prints its name.

## What a pass looks like

The test loops through four steps, and each one starts with a short white
blink on the board's own LED:

| Step | What you should see | If not |
|------|---------------------|--------|
| Chase | One LED at a time steps all the way round; the first one is white, the rest orange | Ring dark but board LED blinking: check the DIN joint and that you soldered to **DIN**, not DOUT. Stops partway: a bad LED or a solder bridge |
| Red / green / blue / white | Each colour matches its label in the serial log | Red and green swapped: the colour order is wrong (change `NEO_GRB`) |
| Fade | Smooth blue fade from dim to bright and back | — |
| Rainbow | A smooth spinning rainbow, no flicker | Flicker or random colours: the 3.3 V data level. Fix it with the 74AHCT125 |

If the board LED never blinks, the sketch isn't running. Check the upload
and the USB CDC setting.
