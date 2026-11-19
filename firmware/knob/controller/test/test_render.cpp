#include "protocol.h"
#include "render.h"
#include "testing.h"

static bool same(Rgb a, Rgb b) { return a.r == b.r && a.g == b.g && a.b == b.b; }
static int lit(const Frame& f) {
  int n = 0;
  for (int i = 0; i < N_LEDS; i++) n += f.level[i] > 0;
  return n;
}

static const Look CMD = {State::Command, Pat::Solid, {0x18, 0xff, 0x6a}, {0x10, 0x98, 0x47}, 15, 71};
static const Look SLEEP = {State::Sleep, Pat::Breathe, {0xff, 0x9a, 0x1a}, {0x3a, 0x1c, 0x00}, 12, 25};
static const Look DICT = {State::Dictation, Pat::GradSpin, {0x2f, 0x6b, 0xff}, {0x9a, 0x3b, 0xff}, 30, 83};

TEST(solid_all_c1) {
  Frame f;
  renderLook(CMD, 1234, f);
  for (int i = 0; i < N_LEDS; i++) {
    CHECK(same(f.px[i], CMD.c1));
    CHECK_NEAR(f.level[i], 0.71, 1e-4);
  }
}

TEST(breathe_extremes) {
  Frame f;
  uint32_t T = 10000 - 90 * 12;
  renderLook(SLEEP, 0, f);
  CHECK(same(f.px[0], SLEEP.c2));
  renderLook(SLEEP, T / 2, f);
  CHECK(same(f.px[5], SLEEP.c1));
  CHECK_NEAR(f.level[5], 0.25, 1e-4);
}

TEST(gradspin_loops) {
  Frame a, b;
  uint32_t T = 8000 - 70 * 30;
  renderLook(DICT, 0, a);
  renderLook(DICT, T, b);
  for (int i = 0; i < N_LEDS; i++) CHECK(same(a.px[i], b.px[i]));
  CHECK(same(a.px[0], DICT.c1));
  CHECK(same(a.px[6], DICT.c2));
}

TEST(gauge_33pct) {
  Frame f;
  renderGauge(33, f);
  for (int i = 0; i < 3; i++) CHECK_NEAR(f.level[i], 1.0, 1e-4);
  CHECK_NEAR(f.level[3], 0.96, 1e-3);
  for (int i = 4; i < N_LEDS; i++) CHECK(f.level[i] == 0);
  CHECK(same(f.px[0], (Rgb{255, 255, 255})));
}

TEST(gauge_5pct_never_dark) {
  Frame f;
  renderGauge(5, f);
  CHECK(f.level[0] > 0);
  CHECK(toPixel(f.px[0], f.level[0], 5, 110) != 0);
}

TEST(hold_progress_half) {
  Frame f;
  renderHoldProgress(0.5f, Rgb{255, 26, 26}, f);
  CHECK(lit(f) == 6);
  CHECK(f.level[0] > 0 && f.level[6] == 0);
}

TEST(flourish_finishes) {
  Frame f;
  CHECK(renderFlourish(Flourish::Press, 1, 0, f));
  CHECK(renderFlourish(Flourish::Press, 1, 399, f));
  CHECK(!renderFlourish(Flourish::Press, 1, 401, f));
  CHECK(!renderFlourish(Flourish::Turn, 1, 301, f));
  CHECK(!renderFlourish(Flourish::Refuse, 1, 301, f));
  CHECK(!renderFlourish(Flourish::None, 1, 0, f));
}

TEST(turn_flourish_direction) {
  Frame f;
  renderFlourish(Flourish::Turn, -1, 10, f);
  CHECK(lit(f) == 6);
  for (int i = 6; i < N_LEDS; i++) CHECK(f.level[i] > 0);
  renderFlourish(Flourish::Turn, 1, 10, f);
  for (int i = 0; i < 6; i++) CHECK(f.level[i] > 0);
  CHECK(f.level[6] == 0);
}

TEST(physIndex_rotation) {
  CHECK(physIndex(0, 3, true) == 3);
  CHECK(physIndex(11, 3, true) == 2);
  CHECK(physIndex(1, 3, false) == 2);
  CHECK(physIndex(4, 3, false) == 11);
}

TEST(toPixel_gamma_monotonic) {
  Rgb w{255, 255, 255};
  uint32_t a = toPixel(w, 0.25f, 100, 110) & 0xff;
  uint32_t b = toPixel(w, 0.5f, 100, 110) & 0xff;
  uint32_t c = toPixel(w, 1.0f, 100, 110) & 0xff;
  CHECK(a < b && b < c);
  CHECK(c == 110);
  CHECK(toPixel(w, 0, 100, 110) == 0);
  CHECK(toPixel(Rgb{255, 0, 0}, 1.0f, 100, 110) == (110u << 16));
}

TEST(demo_flourish_finishes) {
  Frame f;
  CHECK(renderFlourish(Flourish::Demo, 1, 50, f));
  CHECK(f.level[0] > 0);
  CHECK(renderFlourish(Flourish::Demo, 1, 150, f));
  CHECK(f.level[0] == 0);
  CHECK(!renderFlourish(Flourish::Demo, 1, 301, f));
}

TEST(toPixel_dim_keeps_hue) {
  // Disconnected look at default master: must stay red, never grey.
  uint32_t p = toPixel(Rgb{0xff, 0x1a, 0x1a}, 0.17f, 60, 110);
  CHECK((p >> 16) >= 1);
  CHECK(((p >> 8) & 0xff) == 0);
  CHECK((p & 0xff) == 0);
}
