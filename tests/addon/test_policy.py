import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.policy import AutoMute, Intent, choose_restore_mic, decide, derive_state, scroll_delta  # noqa: E402


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
        for awake in ("command", "dictation", "other"):
            self.assertEqual(decide("DOUBLE", awake, "command"), Intent.SLEEP, awake)
        # From sleep or mixed, double-tap is a shortcut straight to dictation.
        for s in ("sleep", "mixed"):
            for last in ("command", "dictation", "mixed"):
                self.assertEqual(decide("DOUBLE", s, last), Intent.DICTATION, (s, last))

    def test_triple_enters_mixed(self):
        for s in ("command", "dictation", "mixed", "sleep", "other"):
            self.assertEqual(decide("TRIPLE", s, "command"), Intent.MIXED, s)

    def test_tap_wakes_into_mixed_if_last_awake(self):
        self.assertEqual(decide("TAP", "sleep", "mixed"), Intent.MIXED)

    def test_mute_refuses_tap_double_triple(self):
        self.assertEqual(decide("TAP", "mute", "command"), Intent.NONE)
        self.assertEqual(decide("DOUBLE", "mute", "command"), Intent.NONE)
        self.assertEqual(decide("TRIPLE", "mute", "command"), Intent.NONE)

    def test_hold_toggles(self):
        self.assertEqual(decide("HOLD", "mute", "command"), Intent.UNMUTE)
        for s in ("command", "dictation", "mixed", "sleep", "other"):
            self.assertEqual(decide("HOLD", s, "command"), Intent.MUTE, s)

    def test_unknown_event_is_none(self):
        self.assertEqual(decide("ROT", "command", "command"), Intent.NONE)


class AutoMuteTest(unittest.TestCase):
    def _muted(self):
        a = AutoMute()
        a.disconnected(0)
        self.assertEqual(a.tick(3.0, False, True), Intent.MUTE)
        return a

    def test_mutes_after_grace(self):
        a = AutoMute()
        a.disconnected(0)
        self.assertEqual(a.tick(2.9, False, True), Intent.NONE)
        self.assertEqual(a.tick(3.0, False, True), Intent.MUTE)
        self.assertTrue(a.marked)
        self.assertEqual(a.tick(4.0, True, True), Intent.NONE)

    def test_blip_shorter_than_grace_does_nothing(self):
        a = AutoMute()
        a.disconnected(0)
        self.assertEqual(a.connected(False), Intent.NONE)
        self.assertEqual(a.tick(5.0, False, True), Intent.NONE)
        self.assertFalse(a.marked)

    def test_restores_on_reconnect(self):
        a = self._muted()
        self.assertEqual(a.connected(True), Intent.UNMUTE)
        self.assertFalse(a.marked)

    def test_already_muted_is_not_marked(self):
        a = AutoMute()
        a.disconnected(0)
        self.assertEqual(a.tick(3.0, True, True), Intent.NONE)
        self.assertFalse(a.marked)
        self.assertEqual(a.connected(True), Intent.NONE)

    def test_reconnect_after_manual_unmute_does_not_restore(self):
        a = self._muted()
        self.assertEqual(a.connected(False), Intent.NONE)
        self.assertFalse(a.marked)

    def test_disabled_never_mutes(self):
        a = AutoMute()
        a.disconnected(0)
        self.assertEqual(a.tick(10.0, False, False), Intent.NONE)
        self.assertFalse(a.marked)

    def test_mark_survives_restart(self):
        self.assertEqual(AutoMute(marked=True).connected(True), Intent.UNMUTE)


class ScrollTest(unittest.TestCase):
    def test_clockwise_scrolls_down(self):
        # Evan's Mac: Talon's mouse_scroll(y>0) moved the page up, so clockwise sends y<0.
        self.assertEqual(scroll_delta(1, 40, False), -40)
        self.assertEqual(scroll_delta(-1, 40, False), 40)

    def test_invert_flips(self):
        self.assertEqual(scroll_delta(1, 40, True), 40)


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
