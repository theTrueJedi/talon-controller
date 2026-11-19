#include "input.h"
#include "testing.h"

// AB = CLK<<1 | DT. Rest state 3; CW per knob_test's QDEC: 3,1,0,2,3.
static int feedAll(QuadDecoder& q, const uint8_t* seq, int n, int* lastIdx) {
  int sum = 0;
  for (int i = 0; i < n; i++) {
    int8_t d = q.feed(seq[i]);
    if (d) *lastIdx = i;
    sum += d;
  }
  return sum;
}

TEST(quad_cw_full_cycle) {
  QuadDecoder q; q.begin(3);
  const uint8_t s[] = {1, 0, 2, 3};
  int last = -1;
  CHECK(feedAll(q, s, 4, &last) == 1);
  CHECK(last == 3);
}

TEST(quad_ccw_full_cycle) {
  QuadDecoder q; q.begin(3);
  const uint8_t s[] = {2, 0, 1, 3};
  int last = -1;
  CHECK(feedAll(q, s, 4, &last) == -1);
  CHECK(last == 3);
}

TEST(quad_bounce_mid_click_one_step) {
  QuadDecoder q; q.begin(3);
  const uint8_t s[] = {1, 0, 1, 0, 2, 3};  // bounce on the 1<->0 edge
  int last = -1;
  CHECK(feedAll(q, s, 6, &last) == 1);
  CHECK(last == 5);
}

TEST(quad_wiggle_back_no_step) {
  QuadDecoder q; q.begin(3);
  CHECK(q.feed(1) == 0);
  CHECK(q.feed(3) == 0);
  const uint8_t s[] = {1, 0, 2, 3};
  int last = -1;
  CHECK(feedAll(q, s, 4, &last) == 1);
}

TEST(debounce_ignores_bounce) {
  Debounce d(25);
  bool changed = false;
  for (uint32_t t = 0; t <= 20; t += 5) changed |= d.feed(t, (t / 5) % 2 == 0);
  CHECK(!changed);
  CHECK(d.state() == false);
}

TEST(debounce_accepts_after_25ms) {
  Debounce d(25);
  CHECK(!d.feed(0, true));
  CHECK(!d.feed(20, true));
  CHECK(d.feed(26, true));
  CHECK(d.state());
}
