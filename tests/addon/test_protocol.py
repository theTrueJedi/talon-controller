import json
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, ROOT)

from addon.protocol import (  # noqa: E402
    DEFAULT_LOOKS, Look, format_look, parse_device_line, parse_look_setting)


class ProtocolTest(unittest.TestCase):
    def test_default_looks_match_ring_design(self):
        with open(os.path.join(ROOT, "docs", "ring-design.json")) as f:
            modes = {m["id"]: m for m in json.load(f)["modes"]}
        for state in ("mute", "sleep", "command", "dictation", "mixed"):
            m = modes[state]
            want = Look(m["pat"], m["c1"].lstrip("#"), m["c2"].lstrip("#"), m["speed"], m["bri"])
            self.assertEqual(DEFAULT_LOOKS[state], want, state)
        self.assertEqual(DEFAULT_LOOKS["other"], Look("solid", "ffffff", "202020", 0, 20))

    def test_format_look(self):
        self.assertEqual(format_look("command", DEFAULT_LOOKS["command"]),
                         "LOOK command solid 18ff6a 109847 15 71")

    def test_parse_look_setting_hash_and_case(self):
        fb = DEFAULT_LOOKS["other"]
        self.assertEqual(parse_look_setting("Solid #18FF6A #109847 15 71", fb),
                         Look("solid", "18ff6a", "109847", 15, 71))
        self.assertEqual(parse_look_setting("  breathe ff9a1a 3a1c00 12 25 ", fb),
                         Look("breathe", "ff9a1a", "3a1c00", 12, 25))

    def test_parse_look_setting_invalid_falls_back(self):
        fb = DEFAULT_LOOKS["command"]
        for bad in ("", "solid", "solid 18ff6a 109847 15", "solid 18ff6z 109847 15 71",
                    "solid 18ff6a 109847 15 171", "solid 18ff6a 109847 -1 71",
                    "so-lid 18ff6a 109847 15 71", "solid 18ff6a 109847 15 71 extra"):
            self.assertEqual(parse_look_setting(bad, fb), fb, bad)

    def test_parse_device_lines(self):
        self.assertEqual(parse_device_line("TAP"), ("TAP", 0))
        self.assertEqual(parse_device_line("DOUBLE"), ("DOUBLE", 0))
        self.assertEqual(parse_device_line("HOLD"), ("HOLD", 0))
        self.assertEqual(parse_device_line("ROT +1"), ("ROT", 1))
        self.assertEqual(parse_device_line("ROT -1"), ("ROT", -1))
        self.assertEqual(parse_device_line("HELLO talon-controller v1"), ("HELLO", 0))

    def test_parse_device_garbage(self):
        for bad in ("", "ROT +2", "ROT 1", "TAPX", "\x00\xff", "HELLO other-device v1",
                    "ESP-ROM:esp32c3-api1-20210207", "tap"):
            self.assertIsNone(parse_device_line(bad), repr(bad))


if __name__ == "__main__":
    unittest.main()
