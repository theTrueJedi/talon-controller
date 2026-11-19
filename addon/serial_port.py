"""Standard-library serial port for the controller (no pyserial).

Non-blocking: reads drain what is available, writes never wait. A vanished
device surfaces as OSError so the caller can drop the link and rescan.
"""

import glob
import os
import select
import termios

MAX_PARTIAL = 256  # bytes buffered without a newline before we discard them


def candidates() -> list[str]:
    return sorted(glob.glob("/dev/cu.usbmodem*"))


def _make_raw(fd: int) -> None:
    attrs = termios.tcgetattr(fd)
    iflag, oflag, cflag, lflag = attrs[0], attrs[1], attrs[2], attrs[3]
    iflag &= ~(termios.IGNBRK | termios.BRKINT | termios.PARMRK | termios.ISTRIP
               | termios.INLCR | termios.IGNCR | termios.ICRNL | termios.IXON)
    oflag &= ~termios.OPOST
    lflag &= ~(termios.ECHO | termios.ECHONL | termios.ICANON | termios.ISIG | termios.IEXTEN)
    cflag &= ~(termios.CSIZE | termios.PARENB | termios.HUPCL)
    cflag |= termios.CS8 | termios.CLOCAL | termios.CREAD
    attrs[0], attrs[1], attrs[2], attrs[3] = iflag, oflag, cflag, lflag
    attrs[4] = attrs[5] = termios.B115200
    attrs[6][termios.VMIN] = 0
    attrs[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, attrs)


class SerialPort:
    def __init__(self, fd: int, path: str):
        self._fd = fd
        self._buf = b""
        self.path = path

    @classmethod
    def open(cls, path: str) -> "SerialPort":
        fd = os.open(path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        try:
            _make_raw(fd)
        except termios.error:
            pass  # not a real tty (only happens in tests)
        return cls(fd, path)

    def write_line(self, text: str) -> None:
        data = (text + "\n").encode("ascii", "replace")
        try:
            while data:
                n = os.write(self._fd, data)
                data = data[n:]
        except BlockingIOError:
            pass  # device not draining: drop the line rather than block Talon

    def read_lines(self) -> list[str]:
        while select.select([self._fd], [], [], 0)[0]:
            try:
                chunk = os.read(self._fd, 1024)
            except BlockingIOError:
                break
            if not chunk:
                raise OSError("serial device closed")
            self._buf += chunk
        *lines, self._buf = self._buf.split(b"\n")
        if len(self._buf) > MAX_PARTIAL:
            self._buf = b""
        return [ln.rstrip(b"\r").decode("ascii", "replace") for ln in lines
                if len(ln) < MAX_PARTIAL]

    def close(self) -> None:
        if self._fd is not None:
            try:
                os.close(self._fd)
            except OSError:
                pass
            self._fd = None
