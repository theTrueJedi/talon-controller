#include "gestures.h"
#include "testing.h"

TEST(tap_after_window) {
  Gestures g;
  CHECK(g.onButton(0, true) == Out::None);
  CHECK(g.onButton(100, false) == Out::None);
  CHECK(g.onTick(349) == Out::None);
  CHECK(g.onTick(351) == Out::Tap);
  CHECK(g.onTick(400) == Out::None);
}

TEST(double_after_window) {
  Gestures g;
  g.onButton(0, true);
  g.onButton(100, false);
  CHECK(g.onButton(300, true) == Out::None);
  CHECK(g.onButton(400, false) == Out::None);
  CHECK(g.onTick(649) == Out::None);
  CHECK(g.onTick(651) == Out::Double);
  CHECK(g.onTick(1000) == Out::None);
}

static Out pressBurst(Gestures& g, int n, uint32_t* lastRelease) {
  Out seen = Out::None;
  for (int i = 0; i < n; i++) {
    uint32_t t = i * 150;
    if (g.onButton(t, true) != Out::None) seen = Out::Hold;  // anything is wrong
    if (g.onTick(t + 25) != Out::None) seen = Out::Hold;
    if (g.onButton(t + 50, false) != Out::None) seen = Out::Hold;
    *lastRelease = t + 50;
  }
  return seen;
}

TEST(seven_presses) {
  Gestures g;
  uint32_t last = 0;
  CHECK(pressBurst(g, 7, &last) == Out::None);
  CHECK(g.onTick(last + 249) == Out::None);
  CHECK(g.onTick(last + 251) == Out::Seven);
  CHECK(g.onTick(last + 500) == Out::None);
}

TEST(three_presses_refused) {
  Gestures g;
  uint32_t last = 0;
  pressBurst(g, 3, &last);
  CHECK(g.onTick(last + 251) == Out::Refuse);
}

TEST(second_press_cannot_hold) {
  Gestures g;
  g.onButton(0, true);
  g.onButton(100, false);
  g.onButton(300, true);
  CHECK(g.onTick(1100) == Out::None);
  CHECK(g.holdProgress(1100) < 0);
  CHECK(g.onDetent(1150, 1) == Out::None);
  CHECK(g.onButton(1200, false) == Out::None);
  CHECK(g.onTick(1451) == Out::Double);
}

TEST(hold_fires_at_threshold_while_held) {
  Gestures g;
  g.onButton(0, true);
  CHECK(g.onTick(699) == Out::None);
  CHECK(g.onTick(700) == Out::Hold);
  CHECK(g.onTick(750) == Out::None);
  CHECK(g.onButton(900, false) == Out::None);
  CHECK(g.onTick(2000) == Out::None);
}

TEST(hold_progress) {
  Gestures g;
  CHECK(g.holdProgress(0) < 0);
  g.onButton(0, true);
  CHECK_NEAR(g.holdProgress(350), 0.5, 0.01);
  g.onDetent(400, 1);
  CHECK(g.holdProgress(450) < 0);
}

TEST(turn_while_held_adjusts) {
  Gestures g;
  g.onButton(0, true);
  CHECK(g.onDetent(200, 1) == Out::BrightUp);
  CHECK(g.onDetent(300, -1) == Out::BrightDown);
  CHECK(g.adjusting());
  CHECK(g.onTick(800) == Out::None);
  CHECK(g.onButton(900, false) == Out::AdjustEnd);
  CHECK(!g.adjusting());
  CHECK(g.onTick(2000) == Out::None);
}

TEST(rotation_ignored_after_hold) {
  Gestures g;
  g.onButton(0, true);
  CHECK(g.onTick(700) == Out::Hold);
  CHECK(g.onDetent(800, 1) == Out::None);
  CHECK(!g.adjusting());
}

TEST(plain_rotation) {
  Gestures g;
  CHECK(g.onDetent(0, 1) == Out::RotCW);
  CHECK(g.onDetent(10, -1) == Out::RotCCW);
}

TEST(rotation_during_window_keeps_tap) {
  Gestures g;
  g.onButton(0, true);
  g.onButton(100, false);
  CHECK(g.onDetent(200, 1) == Out::RotCW);
  CHECK(g.onTick(351) == Out::Tap);
}

TEST(long_release_no_tap) {
  Gestures g;
  g.onButton(0, true);
  CHECK(g.onButton(800, false) == Out::Hold);  // no tick ran during the hold
  CHECK(g.onTick(2000) == Out::None);
}

TEST(stale_burst_flushed_by_next_press) {
  Gestures g;
  g.onButton(0, true);
  g.onButton(100, false);
  CHECK(g.onButton(600, true) == Out::Tap);  // no tick ran in between
  g.onButton(700, false);
  CHECK(g.onTick(951) == Out::Tap);
}
