"""Local web page for tuning ring looks live (stdlib http.server).

Runs on a daemon thread and only exchanges data under a lock; the Talon glue
reads preview() from its main loop and does all Talon/serial work itself.
"""

import json
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from .protocol import DEFAULT_LOOKS, Look, parse_look_setting

PATTERNS = ["solid", "breathe", "gradspin"]
PREVIEW_TTL_S = 3.0  # the page re-sends its preview every second while open
_INVALID = Look("", "", "", -1, -1)


def look_to_json(look: Look) -> dict:
    return {"pat": look.pat, "c1": look.c1, "c2": look.c2, "speed": look.speed, "bri": look.bri}


def look_from_json(d) -> Look | None:
    if not isinstance(d, dict):
        return None
    try:
        speed, bri = d["speed"], d["bri"]
        if not (isinstance(speed, int) and isinstance(bri, int)) or speed < 0 or bri < 0:
            return None
        text = f'{d["pat"]} {d["c1"]} {d["c2"]} {speed} {bri}'
    except (KeyError, TypeError):
        return None
    look = parse_look_setting(text, _INVALID)
    return None if look == _INVALID else look


class Tuner:
    def __init__(self, html_path, get_looks, on_save, clock=time.monotonic):
        self.html_path = html_path
        self._get_looks = get_looks
        self._on_save = on_save
        self._clock = clock
        self._lock = threading.Lock()
        self._preview: tuple[str, Look] | None = None
        self._preview_at = 0.0
        self._server = None
        self.url = ""

    def start(self, port: int) -> bool:
        try:
            self._server = ThreadingHTTPServer(("127.0.0.1", port), self._handler())
        except OSError:
            return False
        self._server.daemon_threads = True
        self.url = f"http://127.0.0.1:{self._server.server_address[1]}"
        threading.Thread(target=self._server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True).start()
        return True

    def stop(self) -> None:
        if self._server:
            self._server.shutdown()
            self._server.server_close()
            self._server = None

    def preview(self) -> tuple[str, Look] | None:
        with self._lock:
            if self._preview and self._clock() - self._preview_at <= PREVIEW_TTL_S:
                return self._preview
            return None

    # --- request handling (server thread) --------------------------------

    def _set_preview(self, value) -> None:
        with self._lock:
            self._preview, self._preview_at = value, self._clock()

    def _handler(self):
        tuner = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):  # keep Talon's log clean
                pass

            def _send(self, code, body=b"", ctype="application/json"):
                self.send_response(code)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self):
                if self.path == "/":
                    with open(tuner.html_path, "rb") as f:
                        self._send(200, f.read(), "text/html; charset=utf-8")
                elif self.path == "/looks":
                    looks = {s: look_to_json(l) for s, l in tuner._get_looks().items()}
                    self._send(200, json.dumps({"looks": looks, "patterns": PATTERNS}).encode())
                else:
                    self._send(404)

            def do_POST(self):
                try:
                    n = int(self.headers.get("Content-Length") or 0)
                    body = json.loads(self.rfile.read(n) or b"{}")
                except ValueError:
                    return self._send(400)
                if not isinstance(body, dict):
                    return self._send(400)
                if self.path == "/preview":
                    state, look = body.get("state"), look_from_json(body.get("look"))
                    if state not in DEFAULT_LOOKS or look is None:
                        return self._send(400)
                    tuner._set_preview((state, look))
                elif self.path == "/end":
                    tuner._set_preview(None)
                elif self.path == "/save":
                    raw = body.get("looks")
                    if not isinstance(raw, dict):
                        return self._send(400)
                    looks = {s: look_from_json(v) for s, v in raw.items()}
                    if any(s not in DEFAULT_LOOKS or l is None for s, l in looks.items()):
                        return self._send(400)
                    tuner._on_save(looks)
                else:
                    return self._send(404)
                self._send(204)

        return Handler
