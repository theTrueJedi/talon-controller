"""Controller line protocol (see firmware/knob/controller/README.md). Pure Python."""

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Look:
    pat: str
    c1: str
    c2: str
    speed: int
    bri: int


# docs/ring-design.json (Evan's ring playground), plus "other".
DEFAULT_LOOKS: dict[str, Look] = {
    "mute": Look("solid", "ff1a1a", "b91818", 40, 70),
    "sleep": Look("solid", "ff8a0d", "c07414", 12, 55),
    "command": Look("solid", "18ff6a", "109847", 15, 71),
    "dictation": Look("gradspin", "9a3bff", "2f6bff", 30, 83),
    "mixed": Look("gradspin", "14e0ff", "2f6bff", 35, 83),
    "other": Look("solid", "ffffff", "202020", 0, 20),
}

_LOOK_RE = re.compile(r"([a-z]+) #?([0-9a-f]{6}) #?([0-9a-f]{6}) (\d{1,3}) (\d{1,3})")


def look_to_setting(look: Look) -> str:
    return f"{look.pat} {look.c1} {look.c2} {look.speed} {look.bri}"


def parse_look_setting(text: str, fallback: Look) -> Look:
    """'<pat> <c1> <c2> <speed> <bri>' (colors may start with #); invalid -> fallback."""
    m = _LOOK_RE.fullmatch(" ".join(str(text).lower().split()))
    if not m:
        return fallback
    speed, bri = int(m[4]), int(m[5])
    if speed > 100 or bri > 100:
        return fallback
    return Look(m[1], m[2], m[3], speed, bri)


def format_look(state: str, look: Look) -> str:
    return f"LOOK {state} {look_to_setting(look)}"


_EVENTS = {"TAP": ("TAP", 0), "DOUBLE": ("DOUBLE", 0), "TRIPLE": ("TRIPLE", 0), "HOLD": ("HOLD", 0),
           "ROT +1": ("ROT", 1), "ROT -1": ("ROT", -1),
           "HELLO talon-controller v1": ("HELLO", 0)}


def parse_device_line(line: str) -> tuple[str, int] | None:
    return _EVENTS.get(line)
