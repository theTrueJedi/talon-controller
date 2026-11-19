#include <cstdlib>

#include "demo.h"
#include "testing.h"

static bool same(Rgb a, Rgb b) { return a.r == b.r && a.g == b.g && a.b == b.b; }

TEST(demo_inactive_at_boot) {
  Demo d;
  CHECK(!d.active());
}

TEST(toggle_enters_cycling) {
  Demo d;
  d.toggle(1000);
  CHECK(d.active());
  CHECK(d.pattern(1000) == 0);
  CHECK(d.pattern(11000) == 1);
  CHECK(d.pattern(41000) == 0);
}

TEST(next_while_cycling_holds_next) {
  Demo d;
  d.toggle(1000);
  CHECK(d.pattern(13000) == 1);
  d.next(13000);
  CHECK(d.pattern(13000) == 2);
  CHECK(d.pattern(61000) == 2);
}

TEST(next_wraps) {
  Demo d;
  d.toggle(0);
  d.next(0);  // 1
  d.next(1);  // 2
  d.next(2);  // 3
  CHECK(d.pattern(3) == 3);
  d.next(4);
  CHECK(d.pattern(5) == 0);
}

TEST(cycle_resumes_rotation) {
  Demo d;
  d.toggle(0);
  d.next(0);
  d.next(0);  // held at 2
  d.cycle(70000);
  CHECK(d.pattern(70000) == 2);
  CHECK(d.pattern(80000) == 3);
}

TEST(toggle_exits) {
  Demo d;
  d.toggle(0);
  d.toggle(500);
  CHECK(!d.active());
}

TEST(toggle_reenters_from_first_pattern) {
  Demo d;
  d.toggle(0);
  d.next(0);
  d.toggle(100);
  d.toggle(200);
  CHECK(d.pattern(200) == 0);
  CHECK(d.pattern(10200) == 1);  // cycling again
}

TEST(hsv_primaries) {
  CHECK(same(hsv(0), (Rgb{255, 0, 0})));
  CHECK(same(hsv(21845), (Rgb{0, 255, 0})));
  CHECK(same(hsv(43690), (Rgb{0, 0, 255})));
}

TEST(wash_all_same_color) {
  Frame f;
  renderDemo(1, 5000, f);
  for (int i = 1; i < N_LEDS; i++) {
    CHECK(same(f.px[i], f.px[0]));
    CHECK(f.level[i] == f.level[0]);
  }
}

TEST(comet_six_lit) {
  Frame f;
  renderDemo(2, 70 * 5, f);  // head at LED 5
  int n = 0;
  for (int i = 0; i < N_LEDS; i++) n += f.level[i] > 0;
  CHECK(n == 6);
  CHECK_NEAR(f.level[5], 1.0, 1e-4);
  CHECK(f.level[5] > f.level[4] && f.level[4] > f.level[0]);
  CHECK(f.level[6] == 0);
}

TEST(spin_hues_distinct) {
  Frame f;
  renderDemo(0, 0, f);
  CHECK(!same(f.px[0], f.px[6]));
  CHECK(f.level[0] == 1);
}

TEST(demo_spin_moves_clockwise) {
  Frame a, b;
  renderDemo(0, 0, a);
  renderDemo(0, 137, b);  // ~1/12 of the hue wheel at 40 hue units per ms
  CHECK(std::abs(b.px[1].r - a.px[0].r) <= 8);
  CHECK(std::abs(b.px[1].g - a.px[0].g) <= 8);
  CHECK(std::abs(b.px[1].b - a.px[0].b) <= 8);
}

TEST(breathe_pulses) {
  Frame a, b;
  renderDemo(3, 0, a);
  renderDemo(3, 1500, b);
  CHECK_NEAR(a.level[0], 40 / 255.0, 0.01);
  CHECK_NEAR(b.level[0], 1.0, 0.01);
}
