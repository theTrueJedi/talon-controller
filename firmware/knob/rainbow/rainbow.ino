// Rainbow show for the 12-LED ring (ring DIN on GPIO0). Just for fun:
// cycles through four rainbow effects, ~10 s each, forever.

#include <Adafruit_NeoPixel.h>

const int RING_PIN = 0;
const int N = 12;
const uint8_t MAX_BRIGHT = 40;  // same cap as the ring test (~110 mA max)
const uint32_t EFFECT_MS = 10000;

Adafruit_NeoPixel ring(N, RING_PIN, NEO_GRB + NEO_KHZ800);

uint32_t hsv(uint16_t hue, uint8_t val = 255) {
  return ring.gamma32(ring.ColorHSV(hue, 255, val));
}

// 1. Spin: the full rainbow around the ring, rotating.
void spin(uint32_t t) {
  for (int i = 0; i < N; i++) ring.setPixelColor(i, hsv(t * 40 + i * 65536L / N));
}

// 2. Whole ring fades through every colour together.
void wash(uint32_t t) {
  ring.fill(hsv(t * 20));
}

// 3. Comet: a bright head with a fading rainbow tail.
void comet(uint32_t t) {
  int head = (t / 70) % N;
  ring.clear();
  for (int k = 0; k < 6; k++) {
    int i = (head - k + N) % N;
    ring.setPixelColor(i, hsv(t * 30 + k * 3000, 255 - k * 42));
  }
}

// 4. Breathing rainbow: the spin, pulsing in and out.
void breathe(uint32_t t) {
  float phase = (t % 3000) / 3000.0f * 2 * PI;
  uint8_t v = 40 + (uint8_t)(215 * (0.5f - 0.5f * cosf(phase)));
  for (int i = 0; i < N; i++) ring.setPixelColor(i, hsv(t * 15 + i * 65536L / N, v));
}

void (*effects[])(uint32_t) = {spin, wash, comet, breathe};
const int EFFECTS = sizeof(effects) / sizeof(effects[0]);

void setup() {
  ring.begin();
  ring.setBrightness(MAX_BRIGHT);
  ring.clear();
  ring.show();
}

void loop() {
  uint32_t t = millis();
  effects[(t / EFFECT_MS) % EFFECTS](t);
  ring.show();
  delay(15);
}
