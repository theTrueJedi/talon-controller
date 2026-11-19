#include "protocol.h"

#include <string.h>

namespace {

// Splits s in place on single spaces; returns the token count (max n).
int split(char* s, char** tok, int n) {
  int k = 0;
  while (*s && k < n + 1) {
    tok[k++] = s;
    char* sp = strchr(s, ' ');
    if (!sp) break;
    *sp = 0;
    s = sp + 1;
  }
  return k;
}

int hexVal(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

bool parseRgb(const char* s, Rgb& out) {
  if (strlen(s) != 6) return false;
  uint8_t v[3];
  for (int i = 0; i < 3; i++) {
    int hi = hexVal(s[2 * i]), lo = hexVal(s[2 * i + 1]);
    if (hi < 0 || lo < 0) return false;
    v[i] = (uint8_t)(hi * 16 + lo);
  }
  out = {v[0], v[1], v[2]};
  return true;
}

bool parsePct(const char* s, uint8_t& out) {
  if (!*s || strlen(s) > 3) return false;
  int v = 0;
  for (; *s; s++) {
    if (*s < '0' || *s > '9') return false;
    v = v * 10 + (*s - '0');
  }
  out = (uint8_t)(v > 100 ? 100 : v);
  return true;
}

State parseState(const char* s) {
  if (!strcmp(s, "mute")) return State::Mute;
  if (!strcmp(s, "sleep")) return State::Sleep;
  if (!strcmp(s, "command")) return State::Command;
  if (!strcmp(s, "dictation")) return State::Dictation;
  if (!strcmp(s, "mixed")) return State::Mixed;
  return State::Other;
}

Pat parsePat(const char* s) {
  if (!strcmp(s, "breathe")) return Pat::Breathe;
  if (!strcmp(s, "gradspin")) return Pat::GradSpin;
  return Pat::Solid;  // unknown pattern still lights the ring
}

}  // namespace

HostMsg parseHostLine(const char* line) {
  HostMsg m{};
  m.kind = MsgKind::Invalid;
  if (!strcmp(line, "PING")) {
    m.kind = MsgKind::Ping;
    return m;
  }
  char buf[LINE_MAX + 1];
  if (strlen(line) > LINE_MAX) return m;
  strcpy(buf, line);
  char* t[8];
  if (split(buf, t, 7) != 7 || strcmp(t[0], "LOOK")) return m;
  Look& l = m.look;
  l.state = parseState(t[1]);
  l.pat = parsePat(t[2]);
  if (!parseRgb(t[3], l.c1) || !parseRgb(t[4], l.c2)) return m;
  if (!parsePct(t[5], l.speed) || !parsePct(t[6], l.bri)) return m;
  m.kind = MsgKind::Look;
  return m;
}

bool LineReader::feed(char c) {
  if (c == '\r') return false;
  if (c == '\n') {
    bool ok = !overflow_ && len_ > 0;
    buf_[len_] = 0;
    len_ = 0;
    overflow_ = false;
    return ok;
  }
  if (len_ >= LINE_MAX) {
    overflow_ = true;
    return false;
  }
  buf_[len_++] = c;
  return false;
}
