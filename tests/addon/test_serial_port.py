import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.serial_port import SerialPort  # noqa: E402


class SerialPortTest(unittest.TestCase):
    def setUp(self):
        self.master, slave = os.openpty()
        self.path = os.ttyname(slave)
        self.port = SerialPort.open(self.path)
        os.close(slave)

    def tearDown(self):
        self.port.close()
        os.close(self.master)

    def test_round_trip(self):
        os.write(self.master, b"HELLO talon-controller v1\r\nTAP\n")
        self.assertEqual(self.port.read_lines(), ["HELLO talon-controller v1", "TAP"])

    def test_partial_line_buffered(self):
        os.write(self.master, b"RO")
        self.assertEqual(self.port.read_lines(), [])
        os.write(self.master, b"T +1\n")
        self.assertEqual(self.port.read_lines(), ["ROT +1"])

    def test_overlong_without_newline_dropped(self):
        os.write(self.master, b"x" * 300)
        self.port.read_lines()
        os.write(self.master, b"TAP\n")
        lines = self.port.read_lines()
        self.assertEqual(lines[-1], "TAP")
        self.assertFalse(any(len(line) >= 256 for line in lines))

    def test_write_line(self):
        self.port.write_line("PING")
        self.assertEqual(os.read(self.master, 64), b"PING\n")

    def test_garbage_collected_port_closes_fd(self):
        fd = self.port._fd
        self.port = SerialPort.open(self.path)  # drop the only reference to the first
        with self.assertRaises(OSError):
            os.fstat(fd)

    def test_close_idempotent(self):
        self.port.close()
        self.port.close()


if __name__ == "__main__":
    unittest.main()
