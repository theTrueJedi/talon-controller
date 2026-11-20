#include "gestures.h"

Out Gestures::resolveBurst() {
  int n = count_;
  count_ = 0;
  if (n == 1) return Out::Tap;
  if (n == 2) return Out::Double;
  if (n == 3) return Out::Triple;
  if (n == 7) return Out::Seven;
  return Out::Refuse;
}

Out Gestures::onButton(uint32_t now, bool pressed) {
  if (pressed == pressed_) return Out::None;
  pressed_ = pressed;
  if (pressed) {
    Out flushed = Out::None;
    if (count_ > 0 && now - lastRelease_ > DOUBLE_MS) flushed = resolveBurst();  // tick missed it
    first_ = (count_ == 0);
    pressAt_ = now;
    holdFired_ = adjusting_ = false;
    return flushed;
  }
  if (adjusting_) {
    adjusting_ = false;
    return Out::AdjustEnd;
  }
  if (holdFired_) return Out::None;
  if (first_ && now - pressAt_ >= HOLD_MS) {  // held past the threshold with no tick
    holdFired_ = true;
    return Out::Hold;
  }
  count_++;
  lastRelease_ = now;
  return Out::None;
}

Out Gestures::onDetent(uint32_t, int8_t dir) {
  if (!pressed_) return dir > 0 ? Out::RotCW : Out::RotCCW;
  if (adjusting_ || canHold()) {
    adjusting_ = true;
    return dir > 0 ? Out::BrightUp : Out::BrightDown;
  }
  return Out::None;  // after a hold fired, or on a later press of a burst
}

Out Gestures::onTick(uint32_t now) {
  if (canHold() && now - pressAt_ >= HOLD_MS) {
    holdFired_ = true;
    return Out::Hold;
  }
  if (!pressed_ && count_ > 0 && now - lastRelease_ > DOUBLE_MS) return resolveBurst();
  return Out::None;
}

float Gestures::holdProgress(uint32_t now) const {
  if (!canHold()) return -1;
  float p = (float)(now - pressAt_) / HOLD_MS;
  return p > 1 ? 1 : p;
}
