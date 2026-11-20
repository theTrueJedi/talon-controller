#include <cstdlib>

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
static const Look DICT = {State::Dictation, Pat::GradSpin, {0x9a, 0x3b, 0xff}, {0x2f, 0x6b, 0xff}, 30, 83};

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

TEST(gradspin_mostly_first_color) {
  // Dictation: mostly c1 with a band of c2 (about 30 % of the ring).
  Frame f;
  renderLook(DICT, 0, f);
  int nearC1 = 0;
  for (int i = 0; i < N_LEDS; i++) {
    int d1 = std::abs(f.px[i].r - DICT.c1.r) + std::abs(f.px[i].b - DICT.c1.b);
    int d2 = std::abs(f.px[i].r - DICT.c2.r) + std::abs(f.px[i].b - DICT.c2.b);
    nearC1 += d1 < d2;
  }
  CHECK(nearC1 >= 8 && nearC1 <= 9);
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
  fillFrame(f, Rgb{255, 255, 255}, 1);
  CHECK(FADE_MS == 250);
  CHECK(renderFlourish(Flourish::Fade, 1, 0, f));
  CHECK(renderFlourish(Flourish::Fade, 1, FADE_MS - 1, f));
  CHECK(!renderFlourish(Flourish::Fade, 1, FADE_MS + 1, f));
  CHECK(!renderFlourish(Flourish::Turn, 1, 301, f));
  CHECK(!renderFlourish(Flourish::Refuse, 1, 301, f));
  CHECK(!renderFlourish(Flourish::None, 1, 0, f));
}

TEST(turn_flourish_direction) {
  Frame f;
  renderFlourish(Flourish::Turn, -1, 10, f);  // CCW: noon back to 7 o'clock
  CHECK(lit(f) == 6);
  CHECK(f.level[0] > 0);
  for (int i = 7; i < N_LEDS; i++) CHECK(f.level[i] > 0);
  CHECK(f.level[6] == 0);
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

TEST(fade_dims_the_frame_out_and_in) {
  Frame f;
  fillFrame(f, CMD.c1, 0.8f);
  renderFlourish(Flourish::Fade, 1, 0, f);
  CHECK_NEAR(f.level[0], 0.8, 1e-3);
  CHECK(same(f.px[0], CMD.c1));
  fillFrame(f, CMD.c1, 0.8f);
  renderFlourish(Flourish::Fade, 1, FADE_MS / 2, f);
  CHECK_NEAR(f.level[0], 0.0, 0.02);
  fillFrame(f, CMD.c1, 0.8f);
  renderFlourish(Flourish::Fade, 1, FADE_MS * 3 / 4, f);
  CHECK_NEAR(f.level[5], 0.4, 0.02);
}

TEST(gradspin_moves_clockwise) {
  Frame a, b;
  uint32_t T = 8000 - 70 * 30;
  renderLook(DICT, 0, a);
  renderLook(DICT, T / N_LEDS, b);
  CHECK(same(b.px[1], a.px[0]));  // what LED 0 showed has moved to LED 1
  CHECK(same(b.px[6], a.px[5]));
}

TEST(toPixel_decodes_screen_colors) {
  // Playground colors are sRGB: 18ff6a must light as green, not teal.
  uint32_t p = toPixel(Rgb{0x18, 0xff, 0x6a}, 1.0f, 100, 255);
  CHECK(((p >> 8) & 0xff) == 255);
  uint32_t b = p & 0xff;
  CHECK(b >= 30 && b <= 45);
  CHECK((p >> 16) <= 1);
}

TEST(toPixel_dim_keeps_hue) {
  // Disconnected look at default master: must stay red, never grey.
  uint32_t p = toPixel(Rgb{0xff, 0x1a, 0x1a}, 0.17f, 60, 110);
  CHECK((p >> 16) >= 1);
  CHECK(((p >> 8) & 0xff) == 0);
  CHECK((p & 0xff) == 0);
}

TEST(feedback_when_host_up) {
  CHECK(feedbackFor(Out::Tap, false, true) == Flourish::Fade);
  CHECK(feedbackFor(Out::Double, false, true) == Flourish::Fade);
  CHECK(feedbackFor(Out::RotCW, false, true) == Flourish::Turn);
  CHECK(feedbackFor(Out::Hold, false, true) == Flourish::None);
}

TEST(feedback_refuses_when_muted) {
  CHECK(feedbackFor(Out::Tap, true, true) == Flourish::Refuse);
  CHECK(feedbackFor(Out::Double, true, true) == Flourish::Refuse);
  CHECK(feedbackFor(Out::Triple, true, true) == Flourish::Refuse);
  CHECK(feedbackFor(Out::Triple, false, true) == Flourish::Fade);
  CHECK(feedbackFor(Out::Hold, true, true) == Flourish::None);  // hold unmutes
}

TEST(feedback_refuses_when_host_down) {
  // Nobody is listening: a press must not look accepted.
  CHECK(feedbackFor(Out::Tap, false, false) == Flourish::Refuse);
  CHECK(feedbackFor(Out::Double, false, false) == Flourish::Refuse);
  CHECK(feedbackFor(Out::Hold, false, false) == Flourish::Refuse);
  CHECK(feedbackFor(Out::RotCW, false, false) == Flourish::None);
}
