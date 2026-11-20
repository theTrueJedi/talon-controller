# Auto-mute on switch-away Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the controller disappears for 3 s, hard-mute Talon; when it returns, restore the mic if that auto-mute is still in place.

**Architecture:** A pure `AutoMute` state machine in `addon/policy.py` decides; `addon/talon_controller.py` feeds it link events and the clock, persists its mark in `addon/.auto_muted`, and reuses the existing `_do(Intent.MUTE/UNMUTE)`.

**Tech Stack:** Talon Python, stdlib only; `python3 -m unittest discover -s tests -t .`

**Spec:** `docs/superpowers/specs/2026-11-12-talon-controller-design.md`, amendment "auto-mute when the controller switches away".

## Global Constraints

- Grace `AUTO_MUTE_GRACE_S = 3.0`.
- Setting `user.talon_controller_auto_mute`, bool, default True.
- Mark file `addon/.auto_muted`, git-ignored.

## Review Focus

- Reconnect within the grace (hub blip): no mute — `test_blip_shorter_than_grace_does_nothing`.
- Manual mute before switching: never restored on return — `test_already_muted_is_not_marked`.
- Manual unmute while away: return doesn't override — `test_reconnect_after_manual_unmute_does_not_restore`.
- Setting off: no mute — `test_disabled_never_mutes`.
- Talon restart while auto-muted: mark loaded from file, restore still happens — `test_mark_survives_restart`.

---

### Task 1: AutoMute policy + wiring

**Files:**
- Modify: `addon/policy.py`, `addon/talon_controller.py`, `addon/README.md`, `.gitignore`, `TESTING.md`
- Test: `tests/addon/test_policy.py`

**Interfaces:**
- Produces: `class AutoMute(marked: bool = False)` with `.marked: bool`, `disconnected(now: float) -> None`, `tick(now: float, mic_is_none: bool, enabled: bool) -> Intent` (MUTE once, when the grace has elapsed, enabled, and mic not None; then sets `marked`), `connected(mic_is_none: bool) -> Intent` (UNMUTE if `marked and mic_is_none`, else NONE; always clears pending and `marked`).

- [ ] **Step 1:** Tests in `AutoMuteTest`: `test_mutes_after_grace` (disconnected(0); tick(2.9)→NONE; tick(3.0)→MUTE, marked; tick(4)→NONE), `test_blip_shorter_than_grace_does_nothing` (disconnected(0); connected(False)→NONE; tick(5)→NONE), `test_restores_on_reconnect` (after mute, connected(True)→UNMUTE, not marked), the three Review Focus tests (already-muted: tick with mic_is_none=True→NONE, not marked; manual unmute: connected(False)→NONE, not marked; disabled: tick(enabled=False)→NONE), `test_mark_survives_restart` (AutoMute(marked=True).connected(True)→UNMUTE).
- [ ] **Step 2:** Run; expect ImportError on `AutoMute`.
- [ ] **Step 3:** Implement `AutoMute` in `policy.py`.
- [ ] **Step 4:** Wire in `talon_controller.py`: setting; `auto_mute = AutoMute(os.path.exists(MARK_FILE))`; DISCONNECTED → `auto_mute.disconnected(time.monotonic())`; CONNECTED → `_do(auto_mute.connected(mic_none))`; every `tick()` → `_do(auto_mute.tick(...))`; write/remove MARK_FILE when `marked` changes. Refresh after.
- [ ] **Step 5:** Docs: README row, `.gitignore` `addon/.auto_muted`, TESTING rows T28-T31.
- [ ] **Step 6:** Full suite green; commit + push.
