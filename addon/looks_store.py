"""Saved ring looks (addon/looks.json) and which look wins. Pure Python.

Precedence: a Talon settings() override > the saved file > built-in defaults.
"""

import json
import os

from .protocol import DEFAULT_LOOKS, Look, look_to_setting, parse_look_setting

_INVALID = Look("", "", "", -1, -1)  # sentinel: parse failed


def load_saved(path: str) -> dict[str, Look]:
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    if not isinstance(data, dict):
        return {}
    out = {}
    for state, text in data.items():
        if state in DEFAULT_LOOKS and isinstance(text, str):
            look = parse_look_setting(text, _INVALID)
            if look != _INVALID:
                out[state] = look
    return out


def save_looks(path: str, looks: dict[str, Look]) -> None:
    data = {s: look_to_setting(looks[s]) for s in DEFAULT_LOOKS if s in looks}
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)  # never leave a half-written file


def effective_look(setting_value: str, setting_default: str, saved: Look | None, default: Look) -> Look:
    base = saved or default
    if setting_value == setting_default:
        return base
    return parse_look_setting(setting_value, base)
