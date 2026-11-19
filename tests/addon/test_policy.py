import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.policy import Intent, choose_restore_mic, decide, derive_state  # noqa: E402


class DeriveStateTest(unittest.TestCase):
    def test_derive_state_table(self):
        mic = "MacBook Pro Microphone"
        rows = [
            ({"command"}, mic, "command"),
            ({"dictation"}, mic, "dictation"),
            ({"command", "dictation"}, mic, "mixed"),
            ({"sleep"}, mic, "sleep"),
            ({"sleep", "command"}, mic, "sleep"),
            (set(), mic, "other"),
            ({"command"}, "None", "mute"),
            ({"sleep"}, "None", "mute"),
            ({"command"}, None, "mute"),
        ]
        for modes, m, want in rows:
            self.assertEqual(derive_state(modes, m), want, (modes, m))


class DecideTest(unittest.TestCase):
    def test_tap_table(self):
        self.assertEqual(decide("TAP", "command", "command"), Intent.DICTATION)
        self.assertEqual(decide("TAP", "dictation", "dictation"), Intent.COMMAND)
        self.assertEqual(decide("TAP", "mixed", "command"), Intent.COMMAND)
        self.assertEqual(decide("TAP", "sleep", "dictation"), Intent.DICTATION)
        self.assertEqual(decide("TAP", "sleep", "command"), Intent.COMMAND)
        self.assertEqual(decide("TAP", "other", "dictation"), Intent.COMMAND)

    def test_double_table(self):
        for awake in ("command", "dictation", "mixed", "other"):
            self.assertEqual(decide("DOUBLE", awake, "command"), Intent.SLEEP, awake)
        self.assertEqual(decide("DOUBLE", "sleep", "dictation"), Intent.DICTATION)
        self.assertEqual(decide("DOUBLE", "sleep", "command"), Intent.COMMAND)

    def test_mute_refuses_tap_double(self):
        self.assertEqual(decide("TAP", "mute", "command"), Intent.NONE)
        self.assertEqual(decide("DOUBLE", "mute", "command"), Intent.NONE)

    def test_hold_toggles(self):
        self.assertEqual(decide("HOLD", "mute", "command"), Intent.UNMUTE)
        for s in ("command", "dictation", "mixed", "sleep", "other"):
            self.assertEqual(decide("HOLD", s, "command"), Intent.MUTE, s)

    def test_unknown_event_is_none(self):
        self.assertEqual(decide("ROT", "command", "command"), Intent.NONE)


class RestoreMicTest(unittest.TestCase):
    def test_restore_mic_remembered(self):
        self.assertEqual(choose_restore_mic("USB Mic", ["None", "System Default", "USB Mic"]), "USB Mic")

    def test_restore_mic_missing_falls_back(self):
        self.assertEqual(choose_restore_mic("USB Mic", ["None", "System Default"]), "System Default")
        self.assertEqual(choose_restore_mic(None, ["None", "System Default"]), "System Default")

    def test_restore_mic_never_none(self):
        self.assertEqual(choose_restore_mic("None", ["None", "System Default"]), "System Default")


if __name__ == "__main__":
    unittest.main()
