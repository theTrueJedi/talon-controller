// Demo mode: lights only. Four rainbow patterns ported from
// firmware/knob/rainbow/, cycling 10 s each or held on one.
#pragma once
#include <stdint.h>

#include "render.h"

const int DEMO_PATTERNS = 4;  // 0 spin, 1 wash, 2 comet, 3 rainbow breathe
const uint32_t DEMO_CYCLE_MS = 10000;

Rgb hsv(uint16_t hue);  // full saturation and value; Adafruit ColorHSV-compatible
void renderDemo(int pattern, uint32_t nowMs, Frame& f);

class Demo {
 public:
  bool active() const { return active_; }
  void toggle(uint32_t nowMs);  // enter: cycling from pattern 0; or exit
  void next(uint32_t nowMs);    // hold the pattern after the one shown now
  void cycle(uint32_t nowMs);   // resume cycling from the pattern shown now
  int pattern(uint32_t nowMs) const;

 private:
  bool active_ = false, cycling_ = true;
  int base_ = 0;         // held pattern, or the pattern cycling started from
  uint32_t since_ = 0;   // when cycling (re)started
};
