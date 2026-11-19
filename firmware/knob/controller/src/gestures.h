// Knob gestures: press bursts (tap/double/seven), hold, hold+turn adjust.
// Pure C++; the sketch feeds debounced button edges, detents and ticks.
#pragma once
#include <stdint.h>

const uint32_t HOLD_MS = 700;    // hold threshold (fires while still held)
const uint32_t DOUBLE_MS = 250;  // max gap between presses in one burst

enum class Out : uint8_t {
  None, Tap, Double, Seven, Refuse, Hold, RotCW, RotCCW, BrightUp, BrightDown, AdjustEnd
};

class Gestures {
 public:
  Out onButton(uint32_t nowMs, bool pressed);
  Out onDetent(uint32_t nowMs, int8_t dir);  // dir = +1 / -1
  Out onTick(uint32_t nowMs);                // call every loop
  float holdProgress(uint32_t nowMs) const;  // 0..1 while a hold could still fire, else -1
  bool adjusting() const { return adjusting_; }

 private:
  bool canHold() const { return pressed_ && first_ && !holdFired_ && !adjusting_; }
  Out resolveBurst();

  bool pressed_ = false, first_ = false, holdFired_ = false, adjusting_ = false;
  uint32_t pressAt_ = 0, lastRelease_ = 0;
  int count_ = 0;  // completed presses in the current burst
};
