#include <cstring>

#include "protocol.h"
#include "testing.h"

TEST(parse_ping) { CHECK(parseHostLine("PING").kind == MsgKind::Ping); }

TEST(parse_look_command) {
  HostMsg m = parseHostLine("LOOK command solid 18ff6a 109847 15 71");
  CHECK(m.kind == MsgKind::Look);
  CHECK(m.look.state == State::Command);
  CHECK(m.look.pat == Pat::Solid);
  CHECK(m.look.c1.r == 0x18 && m.look.c1.g == 0xff && m.look.c1.b == 0x6a);
  CHECK(m.look.c2.r == 0x10 && m.look.c2.g == 0x98 && m.look.c2.b == 0x47);
  CHECK(m.look.speed == 15 && m.look.bri == 71);
}

TEST(parse_all_states_and_pats) {
  CHECK(parseHostLine("LOOK mute solid ff1a1a b91818 40 70").look.state == State::Mute);
  CHECK(parseHostLine("LOOK sleep breathe ff9a1a 3a1c00 12 25").look.pat == Pat::Breathe);
  CHECK(parseHostLine("LOOK dictation gradspin 2f6bff 9a3bff 30 83").look.pat == Pat::GradSpin);
  CHECK(parseHostLine("LOOK mixed gradspin 14e0ff 2f6bff 35 83").look.state == State::Mixed);
  CHECK(parseHostLine("LOOK weird solid ffffff 202020 0 20").look.state == State::Other);
}

TEST(parse_unknown_pat_is_solid) {
  HostMsg m = parseHostLine("LOOK command sparkle 18ff6a 109847 15 71");
  CHECK(m.kind == MsgKind::Look);
  CHECK(m.look.pat == Pat::Solid);
}

TEST(parse_rejects_bad_hex) {
  CHECK(parseHostLine("LOOK command solid 18ff6z 109847 15 71").kind == MsgKind::Invalid);
  CHECK(parseHostLine("LOOK command solid 18ff6 109847 15 71").kind == MsgKind::Invalid);
}

TEST(parse_rejects_missing_fields) {
  CHECK(parseHostLine("LOOK command solid 18ff6a 109847 15").kind == MsgKind::Invalid);
  CHECK(parseHostLine("LOOK").kind == MsgKind::Invalid);
  CHECK(parseHostLine("").kind == MsgKind::Invalid);
}

TEST(parse_rejects_trailing_garbage) {
  CHECK(parseHostLine("LOOK command solid 18ff6a 109847 15 71 x").kind == MsgKind::Invalid);
  CHECK(parseHostLine("PINGX").kind == MsgKind::Invalid);
  CHECK(parseHostLine("LOOK command solid 18ff6a 109847 1x 71").kind == MsgKind::Invalid);
}

TEST(parse_clamps_bri) {
  HostMsg m = parseHostLine("LOOK command solid 18ff6a 109847 150 250");
  CHECK(m.kind == MsgKind::Look);
  CHECK(m.look.speed == 100 && m.look.bri == 100);
}

static int feedStr(LineReader& r, const char* s, char out[][100]) {
  int n = 0;
  for (; *s; s++)
    if (r.feed(*s)) std::strcpy(out[n++], r.line());
  return n;
}

TEST(linereader_strips_cr) {
  LineReader r;
  char out[4][100];
  CHECK(feedStr(r, "PING\r\n", out) == 1);
  CHECK(std::strcmp(out[0], "PING") == 0);
}

TEST(overlong_line_dropped) {
  LineReader r;
  char out[4][100];
  char buf[260];
  std::memset(buf, 'x', 200);
  std::strcpy(buf + 200, "\nPING\n");
  CHECK(feedStr(r, buf, out) == 1);
  CHECK(std::strcmp(out[0], "PING") == 0);
}

TEST(watchdog_expired_at_boot) {
  Watchdog w;
  CHECK(w.expired(0));
  CHECK(w.expired(100000));
}

TEST(watchdog_kick_then_expire) {
  Watchdog w;
  w.kick(1000);
  CHECK(!w.expired(8999));
  CHECK(w.expired(9001));
}

TEST(watchdog_ignores_invalid) {
  CHECK(!shouldKick(parseHostLine("garbage")));
  CHECK(shouldKick(parseHostLine("PING")));
  CHECK(shouldKick(parseHostLine("LOOK command solid 18ff6a 109847 15 71")));
}
