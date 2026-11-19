import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.looks_store import effective_look, load_saved, save_looks  # noqa: E402
from addon.protocol import DEFAULT_LOOKS, Look, look_to_setting  # noqa: E402

SLEEP = Look("solid", "ff8a0d", "c07414", 12, 55)


class LooksStoreTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "looks.json")

    def tearDown(self):
        self.dir.cleanup()

    def write(self, text):
        with open(self.path, "w") as f:
            f.write(text)

    def test_round_trip(self):
        save_looks(self.path, {"sleep": SLEEP, "command": DEFAULT_LOOKS["command"]})
        self.assertEqual(load_saved(self.path), {"sleep": SLEEP, "command": DEFAULT_LOOKS["command"]})

    def test_load_missing_file(self):
        self.assertEqual(load_saved(self.path), {})

    def test_load_corrupt_file(self):
        self.write('{"sleep": "solid ff8a')
        self.assertEqual(load_saved(self.path), {})
        self.write('["not", "a", "dict"]')
        self.assertEqual(load_saved(self.path), {})

    def test_invalid_entry_ignored(self):
        self.write('{"sleep": "solid zzzzzz c07414 12 55", "command": "solid 18ff6a 109847 15 71", "mute": 7}')
        self.assertEqual(load_saved(self.path), {"command": DEFAULT_LOOKS["command"]})

    def test_unknown_state_ignored(self):
        self.write('{"party": "solid 18ff6a 109847 15 71"}')
        self.assertEqual(load_saved(self.path), {})

    def test_precedence_setting_override(self):
        default = DEFAULT_LOOKS["sleep"]
        override = "solid ff0000 000000 0 90"
        self.assertEqual(effective_look(override, look_to_setting(default), SLEEP, default),
                         Look("solid", "ff0000", "000000", 0, 90))

    def test_precedence_saved_over_default(self):
        default = DEFAULT_LOOKS["sleep"]
        self.assertEqual(effective_look(look_to_setting(default), look_to_setting(default), SLEEP, default), SLEEP)

    def test_precedence_default(self):
        default = DEFAULT_LOOKS["sleep"]
        self.assertEqual(effective_look(look_to_setting(default), look_to_setting(default), None, default), default)

    def test_bad_override_falls_to_saved(self):
        default = DEFAULT_LOOKS["sleep"]
        self.assertEqual(effective_look("garbage", look_to_setting(default), SLEEP, default), SLEEP)


if __name__ == "__main__":
    unittest.main()
