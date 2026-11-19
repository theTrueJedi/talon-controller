// Knob test: KY-040 on CLK GPIO3, DT GPIO4, SW GPIO5 (+ on 3V3), ring on GPIO0.
// Turning moves one lit LED around the ring (clockwise should go "up").
// Holding the button lights the whole ring white. Every event is logged at
// 115200 baud, including raw edges per detent so we learn this encoder's
// steps-per-click before the real firmware.

#include <Adafruit_NeoPixel.h>

const int RING_PIN = 0, N = 12;
const int CLK = 3, DT = 4, SW = 5;
const uint8_t MAX_BRIGHT = 40;

Adafruit_NeoPixel ring(N, RING_PIN, NEO_GRB + NEO_KHZ800);

// Quadrature table: index = (prev << 2) | now, value = -1/0/+1 per valid edge.
const int8_t QDEC[16] = {0, -1, 1, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 1, -1, 0};

uint8_t ab;          // last 2-bit state (CLK<<1 | DT)
int accum = 0;       // edges since the last detent
int edgesSeen = 0;   // raw edges since the last detent (for the log)
long pos = 0;        // detent count
bool btnDown = false, btnRaw = false;
uint32_t btnChangedAt = 0, pressedAt = 0;

uint8_t readAB() { return (digitalRead(CLK) << 1) | digitalRead(DT); }

void draw() {
  if (btnDown) {
    ring.fill(ring.Color(255, 255, 255));
  } else {
    ring.clear();
    int i = ((pos % N) + N) % N;
    ring.setPixelColor(i, ring.gamma32(ring.ColorHSV(i * 65536L / N)));
  }
  ring.show();
}

void setup() {
  Serial.begin(115200);
  pinMode(CLK, INPUT_PULLUP);
  pinMode(DT, INPUT_PULLUP);
  pinMode(SW, INPUT_PULLUP);  // KY-040 boards often lack a pull-up on SW
  ab = readAB();
  ring.begin();
  ring.setBrightness(MAX_BRIGHT);
  draw();
  delay(500);
  Serial.printf("[knob-test] start, rest state CLK=%d DT=%d SW=%d\n", ab >> 1, ab & 1, digitalRead(SW));
}

void loop() {
  // Rotation: poll fast; count a detent at 4 edges, or 2 edges on reaching a rest state.
  uint8_t now = readAB();
  if (now != ab) {
    int8_t d = QDEC[(ab << 2) | now];
    if (d == 0) Serial.println("[knob-test] skipped edge (bounce or too fast)");
    accum += d;
    edgesSeen++;
    ab = now;
    bool rest = (now == 0b11 || now == 0b00);
    if (abs(accum) >= 4 || (rest && abs(accum) >= 2)) {
      int step = accum > 0 ? 1 : -1;
      pos += step;
      Serial.printf("[knob-test] turn %s  pos=%ld  (edges this click: %d)\n",
                    step > 0 ? "CW " : "CCW", pos, edgesSeen);
      accum = 0;
      edgesSeen = 0;
      draw();
    } else if (rest && accum == 0) {
      edgesSeen = 0;
    }
  }

  // Button: 25 ms debounce, log press and release with hold time.
  bool raw = digitalRead(SW) == LOW;
  uint32_t ms = millis();
  if (raw != btnRaw) { btnRaw = raw; btnChangedAt = ms; }
  if (raw != btnDown && ms - btnChangedAt > 25) {
    btnDown = raw;
    if (btnDown) {
      pressedAt = ms;
      Serial.println("[knob-test] press");
    } else {
      Serial.printf("[knob-test] release (held %lu ms)\n", (unsigned long)(ms - pressedAt));
    }
    draw();
  }
}
