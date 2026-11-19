"""Finds the controller, keeps the link up, and reconnects. Pure Python.

Non-blocking: call tick() often (every ~20 ms) from Talon's main loop.
"""

import time

from .protocol import parse_device_line
from .serial_port import SerialPort, candidates

SCAN_S = 2.0        # between scans while no device is connected
HANDSHAKE_S = 1.5   # per candidate, waiting for HELLO
PING_RETRY_S = 0.25  # the device may drop a reply while its TX buffer drains
PROBE_BACKOFF_S = 60.0  # a port that never answered isn't re-probed for this long


class Link:
    def __init__(self, list_ports=candidates, open_port=SerialPort.open, clock=time.monotonic):
        self._list_ports = list_ports
        self._open_port = open_port
        self._clock = clock
        self._port = None
        self._queue: list[str] = []
        self._opened_at = self._pinged_at = 0.0
        self._last_scan = None
        self._reason = "no device found"
        self._dropped = False  # a send() failure, reported by the next tick()
        self._failed = False   # the candidate being probed errored out
        self._retired = False
        self._backoff: dict[str, float] = {}  # path -> time it may be probed again
        self.connected = False
        self.path: str | None = None

    def status(self) -> str:
        if self._retired:
            return "retired"
        if self.connected:
            return f"connected {self.path}"
        if self._port:
            return f"searching {self.path}"
        return f"disconnected ({self._reason})"

    def send(self, line: str) -> bool:
        if not self.connected:
            return False
        try:
            self._port.write_line(line)
            return True
        except OSError as e:
            self._drop(str(e))
            self._dropped = True
            return False

    def retire(self) -> None:
        """Close for good: a reloaded add-on retires its predecessor's link."""
        self.close()
        self._retired = True

    def close(self) -> None:
        if self._port:
            self._port.close()
        self._port, self.connected = None, False

    def tick(self) -> list[tuple[str, int]]:
        if self._retired:
            return []
        if self._dropped:
            self._dropped = False
            return [("DISCONNECTED", 0)]
        if self.connected:
            return self._read_connected()
        if self._port:
            return self._handshake()
        self._next_candidate()
        return []

    # --- internals -----------------------------------------------------

    def _drop(self, reason: str) -> None:
        self.close()
        self._reason = reason or "device closed"
        self._last_scan = self._clock()  # wait a scan interval before retrying

    def _read_connected(self) -> list[tuple[str, int]]:
        try:
            lines = self._port.read_lines()
        except OSError as e:
            self._drop(str(e))
            return [("DISCONNECTED", 0)]
        events = (parse_device_line(ln) for ln in lines)
        # HELLO while connected: a PING reply, or the device rebooted and lost
        # its look. Either way the host resends the look.
        return [("RESYNC", 0) if e[0] == "HELLO" else e for e in events if e]

    def _handshake(self) -> list[tuple[str, int]]:
        now = self._clock()
        try:
            lines = self._port.read_lines()
        except OSError:
            lines, self._failed = [], True
        events = [parse_device_line(ln) for ln in lines]
        if ("HELLO", 0) in events:
            # Everything up to the last HELLO was queued while nobody listened.
            last = len(events) - 1 - events[::-1].index(("HELLO", 0))
            self.connected = True
            return [("CONNECTED", 0)] + [e for e in events[last + 1:] if e and e[0] != "HELLO"]
        if self._failed or now - self._opened_at >= HANDSHAKE_S:
            self._backoff[self.path] = now + PROBE_BACKOFF_S  # not ours (or not answering)
            self.close()
            self._next_candidate()
        elif now - self._pinged_at >= PING_RETRY_S:
            self._ping(now)
        return []

    def _ping(self, now: float) -> None:
        self._pinged_at = now
        try:
            self._port.write_line("PING")
        except OSError:
            self._failed = True

    def _next_candidate(self) -> None:
        now = self._clock()
        if not self._queue:
            if self._last_scan is not None and now - self._last_scan < SCAN_S:
                return
            self._last_scan = now
            self._queue = [p for p in self._list_ports() if self._backoff.get(p, 0) <= now]
            if not self._queue:
                self._reason = "no device found"
                return
        while self._queue:
            path = self._queue.pop(0)
            try:
                self._port = self._open_port(path)
            except OSError as e:
                self._reason = f"{path}: {e}"
                continue
            self.path, self._opened_at, self._failed = path, now, False
            self._ping(now)
            return
