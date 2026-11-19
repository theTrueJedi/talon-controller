// Ring rendering: looks, brightness gauge, hold progress, flourishes, and the
// final gamma/cap step. Logical LED 0 = 12 o'clock, increasing clockwise.
#pragma once
#include <stdint.h>

#include "protocol.h"

const int N_LEDS = 12;

// px = color at full value; level = 0..1 brightness before master and cap.
struct Frame { Rgb px[N_LEDS]; float level[N_LEDS]; };

void renderLook(const Look& look, uint32_t nowMs, Frame& f);
void renderGauge(uint8_t masterPct, Frame& f);
void renderHoldProgress(float progress, Rgb color, Frame& f);

enum class Flourish : uint8_t { None, Press, Turn, Refuse, Demo };
bool renderFlourish(Flourish kind, int8_t dir, uint32_t elapsedMs, Frame& f);  // false when finished

// Perceived fraction s = level * master/100; channel = c * s^2.6 * hwCap/255.
uint32_t toPixel(Rgb c, float level, uint8_t masterPct, uint8_t hwCap);  // 0x00RRGGBB
int physIndex(int logical, int topIndex, bool cw);

void clearFrame(Frame& f);
void fillFrame(Frame& f, Rgb c, float level);
// Fills `amount` LEDs (fractional) clockwise from noon; the leading LED is partial.
void fillArc(Frame& f, float amount, Rgb c, float level);

extern const Look LOOK_DISCONNECTED;
