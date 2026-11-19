#include "input.h"

// index = (prev << 2) | now; value = -1/0/+1 per valid edge.
static const int8_t QDEC[16] = {0, -1, 1, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 1, -1, 0};

void QuadDecoder::begin(uint8_t restAB) {
  ab_ = rest_ = restAB & 3;
  accum_ = 0;
}

int8_t QuadDecoder::feed(uint8_t ab) {
  ab &= 3;
  if (ab == ab_) return 0;
  accum_ += QDEC[(ab_ << 2) | ab];
  ab_ = ab;
  if (ab != rest_) return 0;
  int8_t step = 0;
  if (accum_ >= 3) step = 1;
  else if (accum_ <= -3) step = -1;
  accum_ = 0;  // back at rest: a step, or a wiggle back to the same click
  return step;
}

bool Debounce::feed(uint32_t nowMs, bool raw) {
  if (raw != raw_) {
    raw_ = raw;
    changedAt_ = nowMs;
  }
  if (raw_ != state_ && nowMs - changedAt_ > ms_) {
    state_ = raw_;
    return true;
  }
  return false;
}
