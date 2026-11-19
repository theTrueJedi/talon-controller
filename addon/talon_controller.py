"""Talon side of the ring+knob controller.

Mirrors Talon's mode and mic mute onto the ring, and turns knob gestures into
Talon actions. Serial and decisions live in the pure modules beside this one;
this file only wires them to Talon. See addon/README.md.
"""

import os

from talon import Module, actions, app, cron, registry, scope, settings

from .link import Link
from .policy import Intent, choose_restore_mic, decide, derive_state
from .protocol import DEFAULT_LOOKS, format_look, look_to_setting, parse_look_setting

mod = Module()
mod.setting("talon_controller_scroll_amount", type=int, default=40,
            desc="How far one knob detent scrolls")
mod.setting("talon_controller_scroll_invert", type=bool, default=False,
            desc="Reverse the knob's scroll direction")
for _state, _look in DEFAULT_LOOKS.items():
    mod.setting(f"talon_controller_look_{_state}", type=str, default=look_to_setting(_look),
                desc=f"Ring look for {_state}: '<pattern> <color1> <color2> <speed 0-100> <brightness 0-100>'")

MIC_FILE = os.path.join(os.path.dirname(os.path.realpath(__file__)), ".last_mic")

link = Link()
state = "other"
last_awake = "command"
sent_line = None
_logged: set[str] = set()


def _log_once(where: str, e: Exception) -> None:
    key = f"{where}: {e!r}"
    if key not in _logged:
        _logged.add(key)
        print(f"[talon-controller] {key}")


def _look_for(s: str):
    return parse_look_setting(settings.get(f"user.talon_controller_look_{s}"), DEFAULT_LOOKS[s])


def refresh(force: bool = False) -> None:
    """Re-read Talon's real mode and mic, and push the look if it changed."""
    global state, last_awake, sent_line
    try:
        state = derive_state(set(scope.get("mode") or ()), actions.sound.active_microphone())
        if state in ("command", "dictation"):
            last_awake = state
        line = format_look(state, _look_for(state))
        if (force or line != sent_line) and link.send(line):
            sent_line = line
    except Exception as e:
        _log_once("refresh", e)


def _read_mic() -> str | None:
    try:
        with open(MIC_FILE) as f:
            return f.read().strip() or None
    except OSError:
        return None


def _do(intent: Intent) -> None:
    if intent == Intent.COMMAND or intent == Intent.DICTATION:
        actions.speech.enable()
        if intent == Intent.COMMAND:
            actions.user.command_mode()
        else:
            actions.user.dictation_mode()
    elif intent == Intent.SLEEP:
        actions.speech.disable()
    elif intent == Intent.MUTE:
        mic = actions.sound.active_microphone()
        if mic and mic != "None":
            with open(MIC_FILE, "w") as f:
                f.write(mic)
        actions.sound.set_microphone("None")
    elif intent == Intent.UNMUTE:
        actions.sound.set_microphone(choose_restore_mic(_read_mic(), list(actions.sound.microphones())))


def tick() -> None:
    global sent_line
    try:
        events = link.tick()
    except Exception as e:
        _log_once("link", e)
        return
    for name, value in events:
        try:
            if name == "CONNECTED":
                refresh(force=True)
            elif name == "DISCONNECTED":
                sent_line = None
            elif name == "ROT":
                amount = settings.get("user.talon_controller_scroll_amount")
                sign = -1 if settings.get("user.talon_controller_scroll_invert") else 1
                actions.mouse_scroll(y=value * amount * sign)
            else:
                _do(decide(name, state, last_awake))
        except Exception as e:
            _log_once(name, e)
        if name in ("TAP", "DOUBLE", "HOLD"):
            refresh()  # always show what Talon really did, even after a failure


def heartbeat() -> None:
    link.send("PING")


@mod.action_class
class Actions:
    def talon_controller_status():
        """Show the controller's connection state"""
        app.notify("Talon controller", f"{link.status()}, ring: {state}")


def _on_ready():
    cron.interval("20ms", tick)
    cron.interval("500ms", refresh)
    cron.interval("2s", heartbeat)
    registry.register("update_contexts", lambda *_: refresh())


app.register("ready", _on_ready)
