#include "demo.h"

#include <math.h>

Rgb hsv(uint16_t hue16) {
  uint32_t h = ((uint32_t)hue16 * 1530 + 32768) / 65536;
  if (h < 510) return h < 255 ? Rgb{255, (uint8_t)h, 0} : Rgb{(uint8_t)(510 - h), 255, 0};
  if (h < 1020) return h < 765 ? Rgb{0, 255, (uint8_t)(h - 510)} : Rgb{0, (uint8_t)(1020 - h), 255};
  if (h < 1530) return h < 1275 ? Rgb{(uint8_t)(h - 1020), 0, 255} : Rgb{255, 0, (uint8_t)(1530 - h)};
  return Rgb{255, 0, 0};
}

// Hue falls with the LED index, so the rainbow moves clockwise as base grows.
static uint16_t ledHue(uint32_t base, int i) { return (uint16_t)(base - i * 65536L / N_LEDS); }

void renderDemo(int pattern, uint32_t t, Frame& f) {
  clearFrame(f);
  switch (pattern) {
    case 0:  // spin: the full rainbow around the ring, rotating
      for (int i = 0; i < N_LEDS; i++) {
        f.px[i] = hsv(ledHue(t * 40, i));
        f.level[i] = 1;
      }
      break;
    case 1:  // wash: whole ring fades through every colour together
      fillFrame(f, hsv((uint16_t)(t * 20)), 1);
      break;
    case 2: {  // comet: bright head, fading rainbow tail
      int head = (t / 70) % N_LEDS;
      for (int k = 0; k < 6; k++) {
        int i = (head - k + N_LEDS) % N_LEDS;
        f.px[i] = hsv((uint16_t)(t * 30 + k * 3000));
        f.level[i] = (255 - k * 42) / 255.0f;
      }
      break;
    }
    default: {  // rainbow breathe: the spin, pulsing in and out
      float phase = (t % 3000) / 3000.0f * 2 * 3.14159265f;
      float v = (40 + 215 * (0.5f - 0.5f * cosf(phase))) / 255.0f;
      for (int i = 0; i < N_LEDS; i++) {
        f.px[i] = hsv(ledHue(t * 15, i));
        f.level[i] = v;
      }
      break;
    }
  }
}

void Demo::toggle(uint32_t now) {
  active_ = !active_;
  cycling_ = true;
  base_ = 0;
  since_ = now;
}

void Demo::next(uint32_t now) {
  base_ = (pattern(now) + 1) % DEMO_PATTERNS;
  cycling_ = false;
}

void Demo::cycle(uint32_t now) {
  base_ = pattern(now);
  cycling_ = true;
  since_ = now;
}

int Demo::pattern(uint32_t now) const {
  if (!cycling_) return base_;
  return (base_ + (now - since_) / DEMO_CYCLE_MS) % DEMO_PATTERNS;
}
