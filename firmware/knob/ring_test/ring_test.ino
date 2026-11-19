// Ring test for the Talon controller (ESP32-C3-Zero + 12-LED WS2812B ring).
// Checks the 3 ring joints, the data line, colour order and brightness range
// before any real firmware exists. Wiring: ring 5V -> 5V, GND -> GND,
// DIN -> GPIO0. Needs the "Adafruit NeoPixel" library.
//
// The board's own RGB LED (GPIO10) blinks dim white once per step, so
// "board alive but ring dark" points at the ring wiring, not the board.

#include <Adafruit_NeoPixel.h>

const int RING_PIN = 0;
const int RING_COUNT = 12;
const int ONBOARD_PIN = 10;

// 40/255 keeps 12 LEDs at full white near 110 mA: fine on USB, easy on eyes.
const uint8_t MAX_BRIGHT = 40;

Adafruit_NeoPixel ring(RING_COUNT, RING_PIN, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel onboard(1, ONBOARD_PIN, NEO_RGB + NEO_KHZ800);

void step(const char *name) {
  Serial.printf("[ring-test] %s\n", name);
  onboard.setPixelColor(0, onboard.Color(10, 10, 10));
  onboard.show();
  delay(80);
  onboard.clear();
  onboard.show();
}

void fill(uint8_t r, uint8_t g, uint8_t b, const char *name) {
  step(name);
  ring.fill(ring.Color(r, g, b));
  ring.show();
  delay(1500);
}

void setup() {
  Serial.begin(115200);
  onboard.begin();
  ring.begin();
  ring.setBrightness(MAX_BRIGHT);
  ring.clear();
  ring.show();
  delay(500);
  Serial.println("[ring-test] start");
}

void loop() {
  // 1. Chase: one LED at a time, LED 0 first. Every LED must light, in order.
  step("chase: LED 0..11 one at a time (LED 0 is white)");
  for (int i = 0; i < RING_COUNT; i++) {
    ring.clear();
    ring.setPixelColor(i, i == 0 ? ring.Color(255, 255, 255) : ring.Color(255, 80, 0));
    ring.show();
    delay(150);
  }

  // 2. Colour order: if "red" shows green, the colour order is wrong (tell Claude).
  fill(255, 0, 0, "solid RED");
  fill(0, 255, 0, "solid GREEN");
  fill(0, 0, 255, "solid BLUE");
  fill(255, 255, 255, "solid WHITE");

  // 3. Brightness: dimmest up to the cap and back, in blue.
  // setBrightness() is lossy on stored pixels, so refill before every show.
  step("fade: dimmest -> cap -> dimmest");
  const int floorB = 2;
  for (int b = floorB; b <= MAX_BRIGHT; b++) { ring.setBrightness(b); ring.fill(ring.Color(0, 0, 255)); ring.show(); delay(40); }
  for (int b = MAX_BRIGHT; b >= floorB; b--) { ring.setBrightness(b); ring.fill(ring.Color(0, 0, 255)); ring.show(); delay(40); }
  ring.setBrightness(MAX_BRIGHT);

  // 4. Rainbow spin: smooth data stream; flicker here hints at the 3.3 V data level.
  step("rainbow spin (watch for flicker)");
  for (int t = 0; t < 256 * 2; t += 4) {
    for (int i = 0; i < RING_COUNT; i++) {
      ring.setPixelColor(i, ring.gamma32(ring.ColorHSV((t * 256) + i * 65536L / RING_COUNT)));
    }
    ring.show();
    delay(15);
  }

  ring.clear();
  ring.show();
  delay(800);
}
