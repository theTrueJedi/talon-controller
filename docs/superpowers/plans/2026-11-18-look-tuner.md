# Look Tuner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** Live slider GUI for the ring looks, served by the Talon add-on.
**Architecture:** pure `looks_store.py` (load/save/precedence) + `tuner.py` (stdlib `ThreadingHTTPServer`, thread-safe preview/save hand-off) + `tuner.html` (inline JS); glue wires them into `refresh()`/`tick()`.
**Tech Stack:** Python stdlib (`http.server`, `json`, `threading`), Talon 1.0; tests `python3 -m unittest`.
**Spec:** `docs/superpowers/specs/2026-11-18-look-tuner-design.md`

## Global Constraints
- Stdlib only; bind `127.0.0.1`; port `8737`; preview expires `3.0` s after the last page contact.
- Talon API calls only on Talon's main thread; the HTTP thread touches only locked data and the looks file.
- `looks.json`: `{"<state>": "<pat> <c1> <c2> <speed> <bri>", ...}`; invalid entries ignored.

## Review Focus
1. Two servers after an add-on reload (port in use) → old one stopped via the `sys` handoff (Task 3 live check).
2. Page closed mid-preview → ring back to the real look within ~3 s (Task 2 `test_preview_expires`).
3. Malformed POST bodies → 400, no crash, no state change (Task 2 `test_bad_json_400`).
4. Corrupt or partial `looks.json` → defaults used, no crash (Task 1 `test_load_corrupt_file`).
5. Save while previewing → saved looks used once the preview ends (Task 3 live check).

### Task 1: looks_store
**Files:** Create `addon/looks_store.py`; Test `tests/addon/test_looks_store.py`
**Produces:** `load_saved(path) -> dict[str, Look]`, `save_looks(path, looks: dict[str, Look]) -> None` (atomic write via temp + `os.replace`), `effective_look(setting_value: str, setting_default: str, saved: Look | None, default: Look) -> Look` (setting wins only when it differs from its registered default).
- [ ] Tests: `test_round_trip`, `test_load_missing_file` (→ {}), `test_load_corrupt_file` (→ {}), `test_invalid_entry_ignored`, `test_unknown_state_ignored`, `test_precedence_setting_override`, `test_precedence_saved_over_default`, `test_precedence_default`. → FAIL → implement → PASS → commit.

### Task 2: tuner server
**Files:** Create `addon/tuner.py`, `addon/tuner.html`; Test `tests/addon/test_tuner.py`
**Produces:** `class Tuner(html_path, get_looks: Callable[[], dict[str, Look]], on_save: Callable[[dict[str, Look]], None], clock=time.monotonic)` with `start(port: int) -> bool`, `stop()`, `url: str`, `preview() -> tuple[str, Look] | None`. Routes: `GET /` (html), `GET /looks` (`{"looks": {state: {pat,c1,c2,speed,bri}}, "patterns": [...]}`), `POST /preview` `{"state", "look"}`, `POST /end`, `POST /save` `{"looks": {...}}`.
- [ ] Tests (port 0, `urllib`): `test_serves_page`, `test_get_looks`, `test_preview_round_trip`, `test_preview_expires` (fake clock), `test_end_clears_preview`, `test_save_calls_on_save`, `test_bad_json_400`, `test_bad_look_400`, `test_binds_localhost`. → FAIL → implement → PASS → commit.

### Task 3: glue + voice + live check
**Files:** Modify `addon/talon_controller.py`, `addon/talon_controller.talon`, `addon/README.md`, `TESTING.md`
- [ ] `refresh()` uses `effective_look(...)` and the active preview's look; snapshot looks for `get_looks`; `tick()` refreshes when the preview changes; `on_save` writes `looks.json` and swaps the saved dict; `user.talon_controller_tuner()` opens the URL (`open`); retire the previous tuner via `sys` handoff; suite PASS.
- [ ] Live: `curl` GET /looks, POST preview → `sent_line` shows it within 0.1 s; stop → reverts ≤ 3.5 s; reload twice → still one server answering. Commit; merge.
