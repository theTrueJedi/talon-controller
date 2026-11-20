// Talon controller firmware: 12-LED ring + KY-040 knob on an ESP32-C3-Zero.
// Logic lives in src/ (host-tested: bash test/run.sh); this file wires it to
// the pins, the ring, USB serial and flash. Protocol: see README.md.

#include <Adafruit_NeoPixel.h>
#include <Preferences.h>

#include "src/demo.h"
#include "src/gestures.h"
#include "src/input.h"
#include "src/protocol.h"
#include "src/render.h"

// --- Pins and tunables -----------------------------------------------------
const int RING_PIN = 0, CLK = 3, DT = 4, SW = 5;
const int RING_TOP = 0;       // LED index at 12 o'clock
const bool RING_CW = true;    // LED index increases clockwise
const uint8_t HW_CAP = 110;   // of 255: keeps 12 white LEDs under ~350 mA
const uint8_t MASTER_DEFAULT = 60, MASTER_MIN = 5, MASTER_MAX = 100, MASTER_STEP = 5;
const uint32_t FRAME_MS = 16;
const uint32_t PROGRESS_DELAY_MS = 150;  // don't flash the hold fill on a tap
const char* HELLO = "HELLO talon-controller v1";
const Rgb RED = {0xff, 0x1a, 0x1a};

Adafruit_NeoPixel ring(N_LEDS, RING_PIN, NEO_GRB + NEO_KHZ800);
Preferences prefs;
QuadDecoder quad;
Debounce button(25);
Gestures gestures;
LineReader reader;
Watchdog watchdog;
Demo demo;

Look current = LOOK_DISCONNECTED;
Rgb lastAwakeC1 = {0x18, 0xff, 0x6a};  // hold-to-unmute fill color
uint8_t master = MASTER_DEFAULT;
Flourish flourish = Flourish::None;
int8_t flourishDir = 1;
uint32_t flourishAt = 0, lastShow = 0;
Frame shown;     // the frame last sent to the ring
Frame fadeFrom;  // frozen during a fade's dark-going half, so changes swap in the dark

uint8_t readAB() { return (digitalRead(CLK) << 1) | digitalRead(DT); }

void startFlourish(Flourish f, int8_t dir, uint32_t now) {
  if (f == Flourish::Fade) fadeFrom = shown;
  flourish = f;
  flourishDir = dir;
  flourishAt = now;
}

void readHost(uint32_t now) {
  while (Serial.available()) {
    if (!reader.feed((char)Serial.read())) continue;
    HostMsg m = parseHostLine(reader.line());
    if (m.kind == MsgKind::Ping) Serial.println(HELLO);
    if (m.kind == MsgKind::Look) {
      current = m.look;
      if (current.state != State::Mute) lastAwakeC1 = current.c1;
    }
    if (shouldKick(m)) watchdog.kick(now);
  }
}

void handle(Out out, uint32_t now, int8_t dir = 1) {
  if (out == Out::None) return;
  switch (out) {
    case Out::Seven:
      demo.toggle(now);
      startFlourish(Flourish::Fade, 1, now);
      return;
    case Out::Refuse:
      startFlourish(Flourish::Refuse, 1, now);
      return;
    case Out::BrightUp:
    case Out::BrightDown: {
      int m = master + (out == Out::BrightUp ? MASTER_STEP : -MASTER_STEP);
      master = m < MASTER_MIN ? MASTER_MIN : (m > MASTER_MAX ? MASTER_MAX : m);
      return;
    }
    case Out::AdjustEnd:
      prefs.putUChar("master", master);
      return;
    default:
      break;
  }
  if (demo.active()) {  // lights only: nothing goes to the host
    if (out == Out::Tap) demo.next(now);
    if (out == Out::Double) demo.cycle(now);
    if (out == Out::Tap || out == Out::Double) startFlourish(Flourish::Fade, 1, now);
    return;
  }
  // Events are sent even with no host heard from (harmless); the ring just
  // refuses, so a press never looks accepted when nothing will act on it.
  switch (out) {
    case Out::Tap: Serial.println("TAP"); break;
    case Out::Double: Serial.println("DOUBLE"); break;
    case Out::Triple: Serial.println("TRIPLE"); break;
    case Out::Hold: Serial.println("HOLD"); break;
    case Out::RotCW: Serial.println("ROT +1"); break;
    case Out::RotCCW: Serial.println("ROT -1"); break;
    default: return;
  }
  Flourish f = feedbackFor(out, current.state == State::Mute, !watchdog.expired(now));
  if (f != Flourish::None) startFlourish(f, dir, now);
}

// Applies the active flourish on top of the base frame already in f.
void applyFlourish(uint32_t now, Frame& f) {
  if (flourish == Flourish::None) return;
  if (!renderFlourish(flourish, flourishDir, now - flourishAt, f)) flourish = Flourish::None;
}

void render(uint32_t now) {
  Frame f;
  float p = gestures.holdProgress(now);
  uint32_t heldMs = p >= 0 ? (uint32_t)(p * HOLD_MS) : 0;
  if (gestures.adjusting()) {
    renderGauge(master, f);
  } else if (!demo.active() && p >= 0 && heldMs >= PROGRESS_DELAY_MS && !watchdog.expired(now)) {
    float fill = (float)(heldMs - PROGRESS_DELAY_MS) / (HOLD_MS - PROGRESS_DELAY_MS);
    renderHoldProgress(fill, current.state == State::Mute ? lastAwakeC1 : RED, f);
  } else {
    if (flourish == Flourish::Fade && now - flourishAt < FADE_MS / 2) f = fadeFrom;
    else if (demo.active()) renderDemo(demo.pattern(now), now, f);
    else renderLook(watchdog.expired(now) ? LOOK_DISCONNECTED : current, now, f);
    applyFlourish(now, f);
  }
  shown = f;
  for (int i = 0; i < N_LEDS; i++)
    ring.setPixelColor(physIndex(i, RING_TOP, RING_CW), toPixel(f.px[i], f.level[i], master, HW_CAP));
  ring.show();
}

void setup() {
  Serial.begin(115200);
  Serial.setTxTimeoutMs(0);  // never block the ring when no host is reading
  pinMode(CLK, INPUT_PULLUP);
  pinMode(DT, INPUT_PULLUP);
  pinMode(SW, INPUT_PULLUP);
  quad.begin(readAB());
  prefs.begin("ctl", false);
  uint8_t m = prefs.getUChar("master", MASTER_DEFAULT);
  master = m < MASTER_MIN ? MASTER_MIN : (m > MASTER_MAX ? MASTER_MAX : m);
  ring.begin();
  ring.setBrightness(255);  // scaling is done in toPixel
  Serial.println(HELLO);
}

void loop() {
  uint32_t now = millis();
  readHost(now);
  handle(gestures.onTick(now), now);
  if (button.feed(now, digitalRead(SW) == LOW)) handle(gestures.onButton(now, button.state()), now);
  int8_t d = quad.feed(readAB());
  if (d) handle(gestures.onDetent(now, d), now, d);
  if (now - lastShow >= FRAME_MS) {
    render(now);
    lastShow = now;
  }
}
