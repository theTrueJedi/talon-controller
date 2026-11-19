import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.link import HANDSHAKE_S, PROBE_BACKOFF_S, SCAN_S, Link  # noqa: E402

HELLO = "HELLO talon-controller v1"


class FakePort:
    """Device side of a serial port: answers PING with HELLO if `talks`."""

    def __init__(self, path, talks=True, backlog=()):
        self.path, self.talks = path, talks
        self.inbox = list(backlog)  # lines the device has queued for the host
        self.sent = []
        self.closed = False
        self.fail = False
        self.ignore_pings = 0

    def write_line(self, text):
        if self.fail:
            raise OSError("gone")
        self.sent.append(text)
        if text == "PING" and self.talks:
            if self.ignore_pings:
                self.ignore_pings -= 1
            else:
                self.inbox.append(HELLO)

    def read_lines(self):
        if self.fail:
            raise OSError("gone")
        out, self.inbox = self.inbox, []
        return out

    def close(self):
        self.closed = True


class Clock:
    def __init__(self):
        self.t = 100.0

    def __call__(self):
        return self.t


class LinkTest(unittest.TestCase):
    def make(self, ports, open_port=None):
        self.ports = {p.path: p for p in ports}
        self.listing = [p.path for p in ports]
        self.clock = Clock()
        return Link(list_ports=lambda: list(self.listing),
                    open_port=open_port or (lambda path: self.ports[path]), clock=self.clock)

    def run_ticks(self, link, seconds, step=0.02):
        events = []
        end = self.clock.t + seconds
        while self.clock.t < end:
            events += link.tick()
            self.clock.t += step
        return events

    def test_handshake_connects(self):
        link = self.make([FakePort("/dev/a")])
        events = self.run_ticks(link, 0.1)
        self.assertTrue(link.connected)
        self.assertIn(("CONNECTED", 0), events)
        self.assertEqual(link.status(), "connected /dev/a")

    def test_wrong_device_skipped(self):
        link = self.make([FakePort("/dev/a", talks=False), FakePort("/dev/b")])
        self.run_ticks(link, HANDSHAKE_S - 0.1)
        self.assertFalse(link.connected)
        self.run_ticks(link, 0.3)
        self.assertTrue(link.connected)
        self.assertEqual(link.path, "/dev/b")
        self.assertTrue(self.ports["/dev/a"].closed)

    def test_ping_retried_when_reply_lost(self):
        a = FakePort("/dev/a")
        a.ignore_pings = 2
        link = self.make([a])
        self.run_ticks(link, HANDSHAKE_S - 0.1)
        self.assertTrue(link.connected)
        self.assertGreaterEqual(a.sent.count("PING"), 3)

    def test_backlog_before_hello_dropped(self):
        a = FakePort("/dev/a", backlog=["TAP", "ROT +1", "ROT +1", "HOLD"])
        link = self.make([a])
        events = self.run_ticks(link, 0.2)
        self.assertEqual(events, [("CONNECTED", 0)])

    def test_events_passed_through(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        a.inbox += ["TAP", "garbage", "ROT -1"]
        self.assertEqual(link.tick(), [("TAP", 0), ("ROT", -1)])

    def test_hello_while_connected_resyncs(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        a.inbox += [HELLO]  # device rebooted (or answered a PING): resend the look
        self.assertEqual(link.tick(), [("RESYNC", 0)])

    def test_read_error_drops_link(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        a.fail = True
        self.assertEqual(link.tick(), [("DISCONNECTED", 0)])
        self.assertFalse(link.connected)
        self.assertEqual(link.tick(), [])
        self.assertTrue(a.closed)
        self.assertTrue(link.status().startswith("disconnected"))

    def test_rescan_after_drop(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        a.fail = True
        link.tick()
        b = FakePort("/dev/b")
        self.ports["/dev/b"] = b
        self.listing = ["/dev/b"]  # replug: new port name
        self.run_ticks(link, SCAN_S - 0.1)
        self.assertFalse(link.connected)
        self.run_ticks(link, 0.3)
        self.assertTrue(link.connected)
        self.assertEqual(link.path, "/dev/b")

    def test_send_when_disconnected_returns_false(self):
        link = self.make([])
        self.assertFalse(link.send("PING"))
        link.tick()
        self.assertEqual(link.status(), "disconnected (no device found)")

    def test_send_error_drops_link(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        self.assertTrue(link.send("LOOK x"))
        a.fail = True
        self.assertFalse(link.send("PING"))
        self.assertEqual(link.tick(), [("DISCONNECTED", 0)])

    def test_open_failure_skips_port(self):
        def open_port(path):
            if path == "/dev/busy":
                raise OSError("Resource busy")
            return self.ports[path]

        link = self.make([FakePort("/dev/b")], open_port)
        self.listing = ["/dev/busy", "/dev/b"]
        self.run_ticks(link, 0.2)
        self.assertTrue(link.connected)

    def test_silent_port_backed_off(self):
        opens = []

        def open_port(path):
            opens.append(path)
            return FakePort(path, talks=False)

        link = self.make([FakePort("/dev/printer", talks=False)], open_port)
        self.run_ticks(link, HANDSHAKE_S + 0.1)
        self.run_ticks(link, PROBE_BACKOFF_S - HANDSHAKE_S - 1)
        self.assertEqual(opens, ["/dev/printer"])
        self.run_ticks(link, SCAN_S + 1.5)
        self.assertEqual(opens, ["/dev/printer", "/dev/printer"])

    def test_retired_link_is_inert(self):
        a = FakePort("/dev/a")
        link = self.make([a])
        self.run_ticks(link, 0.1)
        link.retire()
        self.assertTrue(a.closed)
        self.assertFalse(link.send("PING"))
        self.assertEqual(self.run_ticks(link, SCAN_S * 2), [])
        self.assertFalse(link.connected)
        self.assertEqual(link.status(), "retired")


if __name__ == "__main__":
    unittest.main()
