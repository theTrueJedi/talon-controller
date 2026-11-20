"""What the knob's gestures do to Talon, as pure decisions. Pure Python."""

from enum import Enum


class Intent(Enum):
    NONE = "none"
    COMMAND = "command"
    DICTATION = "dictation"
    MIXED = "mixed"
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
    """last_awake is the last of command/dictation/mixed, used to wake from sleep."""
    wake = {"dictation": Intent.DICTATION, "mixed": Intent.MIXED}.get(last_awake, Intent.COMMAND)
    if event == "HOLD":
        return Intent.UNMUTE if state == "mute" else Intent.MUTE
    if state == "mute" or event not in ("TAP", "DOUBLE", "TRIPLE"):
        return Intent.NONE
    if event == "TRIPLE":
        return Intent.MIXED
    if state == "sleep":
        return wake
    if event == "DOUBLE":
        return Intent.SLEEP
    return Intent.DICTATION if state == "command" else Intent.COMMAND


AUTO_MUTE_GRACE_S = 3.0  # a hub blip shorter than this does nothing


class AutoMute:
    """Hard-mutes when the controller has been gone AUTO_MUTE_GRACE_S (it was
    switched to the other machine), and restores the mic when it returns,
    unless the mic was changed by hand meanwhile. `marked`: this auto-mute
    is still in place (persisted by the caller across Talon restarts)."""

    def __init__(self, marked: bool = False):
        self.marked = marked
        self._gone_since: float | None = None

    @property
    def waiting(self) -> bool:
        return self._gone_since is not None

    def disconnected(self, now: float) -> None:
        self._gone_since = now

    def tick(self, now: float, mic_is_none: bool, enabled: bool) -> Intent:
        if self._gone_since is None or now - self._gone_since < AUTO_MUTE_GRACE_S:
            return Intent.NONE
        self._gone_since = None
        if not enabled or mic_is_none:  # off, or already muted by hand
            return Intent.NONE
        self.marked = True
        return Intent.MUTE

    def connected(self, mic_is_none: bool) -> Intent:
        restore = self.marked and mic_is_none
        self._gone_since, self.marked = None, False
        return Intent.UNMUTE if restore else Intent.NONE


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
