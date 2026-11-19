// Host -> device protocol: "PING" and
// "LOOK <state> <pat> <c1> <c2> <speed> <bri>". Pure C++.
#pragma once
#include <stdint.h>

struct Rgb { uint8_t r, g, b; };
enum class Pat : uint8_t { Solid, Breathe, GradSpin };
enum class State : uint8_t { Mute, Sleep, Command, Dictation, Mixed, Other };
struct Look { State state; Pat pat; Rgb c1, c2; uint8_t speed, bri; };
enum class MsgKind : uint8_t { Invalid, Ping, Look };
struct HostMsg { MsgKind kind; Look look; };

HostMsg parseHostLine(const char* line);
inline bool shouldKick(const HostMsg& m) { return m.kind != MsgKind::Invalid; }

const int HOST_LINE_MAX = 95;

class LineReader {
 public:
  bool feed(char c);  // true when a complete line is ready in line()
  const char* line() const { return buf_; }
 private:
  char buf_[HOST_LINE_MAX + 1] = {0};
  int len_ = 0;
  bool overflow_ = false;
};

const uint32_t WATCHDOG_MS = 8000;

class Watchdog {
 public:
  void kick(uint32_t nowMs) { last_ = nowMs; kicked_ = true; }
  bool expired(uint32_t nowMs) const { return !kicked_ || nowMs - last_ > WATCHDOG_MS; }
 private:
  uint32_t last_ = 0;
  bool kicked_ = false;
};
