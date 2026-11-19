"""What the knob's gestures do to Talon, as pure decisions. Pure Python."""

from enum import Enum


class Intent(Enum):
    NONE = "none"
    COMMAND = "command"
    DICTATION = "dictation"
    SLEEP = "sleep"
    MUTE = "mute"
    UNMUTE = "unmute"


def derive_state(modes: set[str], mic: str | None) -> str:
    """Ring state: hard mute wins, then community mode_indicator's order."""
    if mic in (None, "None"):
        return "mute"
    if "sleep" in modes:
        return "sleep"
    if "dictation" in modes:
        return "mixed" if "command" in modes else "dictation"
    if "command" in modes:
        return "command"
    return "other"


def decide(event: str, state: str, last_awake: str) -> Intent:
    """last_awake is the last of command/dictation, used to wake from sleep."""
    wake = Intent.DICTATION if last_awake == "dictation" else Intent.COMMAND
    if event == "HOLD":
        return Intent.UNMUTE if state == "mute" else Intent.MUTE
    if state == "mute" or event not in ("TAP", "DOUBLE"):
        return Intent.NONE
    if state == "sleep":
        return wake
    if event == "DOUBLE":
        return Intent.SLEEP
    return Intent.DICTATION if state == "command" else Intent.COMMAND


def choose_restore_mic(remembered: str | None, available: list[str]) -> str:
    if remembered and remembered != "None" and remembered in available:
        return remembered
    return "System Default"


def scroll_delta(direction: int, amount: int, invert: bool) -> int:
    """mouse_scroll y for one detent. Clockwise (+1) scrolls the page down,
    which on Evan's Mac is a negative y; `invert` flips it (e.g. a machine
    with the other macOS scroll-direction setting)."""
    y = -direction * amount
    return -y if invert else y
