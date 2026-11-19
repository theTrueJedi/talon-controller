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

uint8_t readAB() { return (digitalRead(CLK) << 1) | digitalRead(DT); }

void startFlourish(Flourish f, int8_t dir, uint32_t now) {
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
      startFlourish(Flourish::Demo, 1, now);
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
    return;
  }
  bool muted = current.state == State::Mute;
  switch (out) {
    case Out::Tap:
    case Out::Double:
      Serial.println(out == Out::Tap ? "TAP" : "DOUBLE");
      startFlourish(muted ? Flourish::Refuse : Flourish::Press, 1, now);
      break;
    case Out::Hold:
      Serial.println("HOLD");
      break;
    case Out::RotCW:
    case Out::RotCCW:
      Serial.println(out == Out::RotCW ? "ROT +1" : "ROT -1");
      startFlourish(Flourish::Turn, dir, now);
      break;
    default:
      break;
  }
}

bool flourishFrame(uint32_t now, Frame& f) {
  if (flourish == Flourish::None) return false;
  if (renderFlourish(flourish, flourishDir, now - flourishAt, f)) return true;
  flourish = Flourish::None;
  return false;
}

void render(uint32_t now) {
  Frame f;
  float p = gestures.holdProgress(now);
  uint32_t heldMs = p >= 0 ? (uint32_t)(p * HOLD_MS) : 0;
  if (gestures.adjusting()) {
    renderGauge(master, f);
  } else if (demo.active()) {
    if (!flourishFrame(now, f)) renderDemo(demo.pattern(now), now, f);
  } else if (p >= 0 && heldMs >= PROGRESS_DELAY_MS) {
    float fill = (float)(heldMs - PROGRESS_DELAY_MS) / (HOLD_MS - PROGRESS_DELAY_MS);
    renderHoldProgress(fill, current.state == State::Mute ? lastAwakeC1 : RED, f);
  } else if (!flourishFrame(now, f)) {
    renderLook(watchdog.expired(now) ? LOOK_DISCONNECTED : current, now, f);
  }
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
