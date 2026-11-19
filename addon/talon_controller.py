"""Talon side of the ring+knob controller.

Mirrors Talon's mode and mic mute onto the ring, and turns knob gestures into
Talon actions. Serial and decisions live in the pure modules beside this one;
this file only wires them to Talon. See addon/README.md.
"""

import os
import subprocess
import sys

from talon import Module, actions, app, cron, registry, scope, settings

from .link import Link
from .looks_store import effective_look, load_saved, save_looks
from .policy import Intent, choose_restore_mic, decide, derive_state, scroll_delta
from .protocol import DEFAULT_LOOKS, format_look, look_to_setting
from .tuner import Tuner

mod = Module()
mod.setting("talon_controller_scroll_amount", type=int, default=40,
            desc="How far one knob detent scrolls")
mod.setting("talon_controller_scroll_invert", type=bool, default=False,
            desc="Reverse the knob's scroll direction")
for _state, _look in DEFAULT_LOOKS.items():
    mod.setting(f"talon_controller_look_{_state}", type=str, default=look_to_setting(_look),
                desc=f"Ring look for {_state}: '<pattern> <color1> <color2> <speed 0-100> <brightness 0-100>'")

HERE = os.path.dirname(os.path.realpath(__file__))
MIC_FILE = os.path.join(HERE, ".last_mic")
LOOKS_FILE = os.path.join(HERE, "looks.json")  # written by the tuner's Save
TUNER_PORT = 8737

# Talon doesn't cancel this file's crons on reload, so the previous load's
# Link would keep reading the port beside the new one. Retire it through a
# process-wide handle (sys outlives module reloads).
_prev = getattr(sys, "_talon_controller_link", None)
if _prev is not None:  # may be an older Link class without retire()
    try:
        (getattr(_prev, "retire", None) or _prev.close)()
    except Exception as e:
        print(f"[talon-controller] retiring previous link: {e!r}")
link = Link()
sys._talon_controller_link = link
saved = load_saved(LOOKS_FILE)
current_looks = dict(DEFAULT_LOOKS)  # snapshot for the tuner page (read off-thread)
last_preview = None
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
    return effective_look(settings.get(f"user.talon_controller_look_{s}"),
                          look_to_setting(DEFAULT_LOOKS[s]), saved.get(s), DEFAULT_LOOKS[s])


def refresh(force: bool = False) -> None:
    """Re-read Talon's real mode and mic, and push the look if it changed."""
    global state, last_awake, sent_line, current_looks
    try:
        state = derive_state(set(scope.get("mode") or ()), actions.sound.active_microphone())
        if state in ("command", "dictation"):
            last_awake = state
        current_looks = {s: _look_for(s) for s in DEFAULT_LOOKS}
        preview = tuner.preview()
        # A tuner preview overrides the look but keeps the real state name, so
        # the firmware's mute behavior is unchanged.
        line = format_look(state, preview[1] if preview else current_looks[state])
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
            try:  # remembering the mic must never stand in the way of muting
                with open(MIC_FILE, "w") as f:
                    f.write(mic)
            except OSError as e:
                _log_once("save mic", e)
        actions.sound.set_microphone("None")
    elif intent == Intent.UNMUTE:
        actions.sound.set_microphone(choose_restore_mic(_read_mic(), list(actions.sound.microphones())))


def _on_save(looks) -> None:  # tuner thread: file + an atomic dict swap only
    global saved
    save_looks(LOOKS_FILE, looks)
    saved = dict(looks)


_prev_tuner = getattr(sys, "_talon_controller_tuner", None)
if _prev_tuner is not None:  # free the port before the new server binds it
    try:
        _prev_tuner.stop()
    except Exception as e:
        print(f"[talon-controller] stopping previous tuner: {e!r}")
tuner = Tuner(os.path.join(HERE, "tuner.html"), lambda: current_looks, _on_save)
sys._talon_controller_tuner = tuner


def _start_tuner() -> None:
    # Started just after import: starting the thread while Talon holds its
    # import lock stalled Talon's main loop for seconds.
    if not tuner.start(TUNER_PORT):
        print(f"[talon-controller] tuner unavailable: port {TUNER_PORT} in use")


cron.after("100ms", _start_tuner)


def tick() -> None:
    global sent_line, last_preview
    preview = tuner.preview()
    if preview != last_preview:
        last_preview = preview
        refresh()
    try:
        events = link.tick()
    except Exception as e:
        _log_once("link", e)
        return
    for name, value in events:
        try:
            if name in ("CONNECTED", "RESYNC"):
                refresh(force=True)
            elif name == "DISCONNECTED":
                sent_line = None
            elif name == "ROT":
                actions.mouse_scroll(y=scroll_delta(
                    value, settings.get("user.talon_controller_scroll_amount"),
                    settings.get("user.talon_controller_scroll_invert")))
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

    def talon_controller_tuner():
        """Open the ring look tuner in the browser"""
        if tuner.url:
            subprocess.Popen(["open", tuner.url])
        else:
            app.notify("Talon controller", f"Tuner unavailable: port {TUNER_PORT} in use")


cron.interval("20ms", tick)
cron.interval("500ms", refresh)
cron.interval("2s", heartbeat)
registry.register("update_contexts", lambda *_: refresh())
