// Knob input decoding: quadrature detents and button debounce. Pure C++.
#pragma once
#include <stdint.h>

// KY-040 here is full-step: 4 edges per detent, passing through the
// opposite state mid-click. Counts one step on returning to the rest state.
class QuadDecoder {
 public:
  void begin(uint8_t restAB);   // AB = CLK<<1 | DT, read at boot (knob at rest)
  int8_t feed(uint8_t ab);      // +1 CW / -1 CCW on a completed detent, else 0
 private:
  uint8_t ab_ = 0, rest_ = 0;
  int accum_ = 0;
};

class Debounce {
 public:
  explicit Debounce(uint16_t ms = 25) : ms_(ms) {}
  bool feed(uint32_t nowMs, bool raw);  // true when the debounced state changed
  bool state() const { return state_; }
 private:
  uint16_t ms_;
  bool state_ = false, raw_ = false;
  uint32_t changedAt_ = 0;
};
