// Ring rendering: looks, brightness gauge, hold progress, flourishes, and the
// final gamma/cap step. Logical LED 0 = 12 o'clock, increasing clockwise.
#pragma once
#include <stdint.h>

#include "gestures.h"
#include "protocol.h"

const int N_LEDS = 12;

// px = color at full value; level = 0..1 brightness before master and cap.
struct Frame { Rgb px[N_LEDS]; float level[N_LEDS]; };

void renderLook(const Look& look, uint32_t nowMs, Frame& f);
void renderGauge(uint8_t masterPct, Frame& f);
void renderHoldProgress(float progress, Rgb color, Frame& f);

// Turn and Refuse replace the frame; Fade dims the frame already in f out
// and back in (FADE_MS), e.g. to acknowledge a tap or entering demo.
enum class Flourish : uint8_t { None, Turn, Refuse, Fade };
const uint32_t FADE_MS = 250;
bool renderFlourish(Flourish kind, int8_t dir, uint32_t elapsedMs, Frame& f);  // false when finished
// Flourish acknowledging a control-mode gesture. A press never looks accepted
// when it won't be acted on: refused while muted (tap/double) or host down.
Flourish feedbackFor(Out out, bool muted, bool hostUp);

// Colors are screen (sRGB) colors, decoded per channel to LED-linear (^2.2),
// so playground colors look the same on the ring. Perceived brightness
// s = level * master/100 is applied as s^2.6; then scaled by hwCap/255.
// A lit LED never goes dark: if every channel rounds to 0, the brightest is 1.
uint32_t toPixel(Rgb c, float level, uint8_t masterPct, uint8_t hwCap);  // 0x00RRGGBB
int physIndex(int logical, int topIndex, bool cw);

void clearFrame(Frame& f);
void fillFrame(Frame& f, Rgb c, float level);
// Fills `amount` LEDs (fractional) clockwise from noon; the leading LED is partial.
void fillArc(Frame& f, float amount, Rgb c, float level);

extern const Look LOOK_DISCONNECTED;
