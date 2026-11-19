#include "render.h"

#include <math.h>

const Look LOOK_DISCONNECTED = {State::Other, Pat::Breathe, {0xff, 0x1a, 0x1a}, {0x20, 0x20, 0x20}, 9, 17};

namespace {

const float PI_F = 3.14159265f;

uint8_t mix(uint8_t a, uint8_t b, float k) { return (uint8_t)lroundf(a + (b - a) * k); }
Rgb lerp(Rgb a, Rgb b, float k) { return {mix(a.r, b.r, k), mix(a.g, b.g, k), mix(a.b, b.b, k)}; }

float frac(float x) { return x - floorf(x); }
float tri(float x) {  // 0 -> 1 -> 0 over one unit
  float u = frac(x);
  return u < 0.5f ? 2 * u : 2 - 2 * u;
}

const Rgb WHITE = {255, 255, 255};
const Rgb TURN_PURPLE = {0xc0, 0x3b, 0xff};
const Rgb REFUSE_RED = {0xff, 0x1a, 0x1a};

}  // namespace

void clearFrame(Frame& f) { fillFrame(f, {0, 0, 0}, 0); }

void fillFrame(Frame& f, Rgb c, float level) {
  for (int i = 0; i < N_LEDS; i++) {
    f.px[i] = c;
    f.level[i] = level;
  }
}

void fillArc(Frame& f, float amount, Rgb c, float level) {
  clearFrame(f);
  for (int i = 0; i < N_LEDS; i++) {
    float part = amount - i;
    if (part <= 0) break;
    f.px[i] = c;
    f.level[i] = level * (part > 1 ? 1 : part);
  }
}

void renderLook(const Look& look, uint32_t now, Frame& f) {
  float lvl = look.bri / 100.0f;
  switch (look.pat) {
    case Pat::Solid:
      fillFrame(f, look.c1, lvl);
      break;
    case Pat::Breathe: {
      uint32_t T = 10000 - 90 * look.speed;
      float k = (1 - cosf(2 * PI_F * (now % T) / T)) / 2;
      fillFrame(f, lerp(look.c2, look.c1, k), lvl);
      break;
    }
    case Pat::GradSpin: {
      uint32_t T = 8000 - 70 * look.speed;
      float phase = (float)(now % T) / T;
      for (int i = 0; i < N_LEDS; i++) {
        f.px[i] = lerp(look.c1, look.c2, tri((float)i / N_LEDS - phase));  // moves clockwise
        f.level[i] = lvl;
      }
      break;
    }
  }
}

void renderGauge(uint8_t masterPct, Frame& f) { fillArc(f, masterPct / 100.0f * N_LEDS, WHITE, 1); }

void renderHoldProgress(float progress, Rgb color, Frame& f) { fillArc(f, progress * N_LEDS, color, 1); }

bool renderFlourish(Flourish kind, int8_t dir, uint32_t e, Frame& f) {
  if (kind != Flourish::Fade) clearFrame(f);
  switch (kind) {
    case Flourish::Fade: {  // out to dark and back in
      if (e > FADE_MS) return false;
      float half = FADE_MS / 2.0f;
      float k = fabsf(1 - e / half);
      for (int i = 0; i < N_LEDS; i++) f.level[i] *= k;
      return true;
    }
    case Flourish::Turn:  // half ring from noon in the turn direction, fading
      if (e > 300) return false;
      for (int k = 0; k < N_LEDS / 2; k++) {
        int i = dir > 0 ? k : N_LEDS - 1 - k;
        f.px[i] = TURN_PURPLE;
        f.level[i] = 0.75f * (1 - e / 300.0f);
      }
      return true;
    case Flourish::Refuse:  // two 100 ms red blinks
      if (e > 300) return false;
      if (e < 100 || e >= 200) fillFrame(f, REFUSE_RED, 0.70f);
      return true;
    case Flourish::None:
      break;
  }
  return false;
}

Flourish feedbackFor(Out out, bool muted, bool hostUp) {
  switch (out) {
    case Out::Tap:
    case Out::Double:
      return (muted || !hostUp) ? Flourish::Refuse : Flourish::Fade;
    case Out::Hold:
      return hostUp ? Flourish::None : Flourish::Refuse;
    case Out::RotCW:
    case Out::RotCCW:
      return hostUp ? Flourish::Turn : Flourish::None;
    default:
      return Flourish::None;
  }
}

uint32_t toPixel(Rgb c, float level, uint8_t masterPct, uint8_t hwCap) {
  float s = level * masterPct / 100.0f;
  if (s <= 0) return 0;
  if (s > 1) s = 1;
  float g = powf(s, 2.6f) * hwCap;
  auto lin = [](uint8_t v) { return powf(v / 255.0f, 2.2f); };
  uint32_t r = lroundf(lin(c.r) * g), gr = lroundf(lin(c.g) * g), b = lroundf(lin(c.b) * g);
  if (!r && !gr && !b) {  // too dim to show: light only the brightest channel(s) at 1
    uint8_t m = c.r > c.g ? (c.r > c.b ? c.r : c.b) : (c.g > c.b ? c.g : c.b);
    if (!m) return 0;
    r = c.r == m, gr = c.g == m, b = c.b == m;
  }
  return (r << 16) | (gr << 8) | b;
}

int physIndex(int logical, int top, bool cw) {
  return cw ? (top + logical) % N_LEDS : (top - logical % N_LEDS + N_LEDS) % N_LEDS;
}
