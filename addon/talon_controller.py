# Stub for the serial spike (Task 1); replaced by the real glue in Task 10.
from .serial_port import SerialPort, candidates  # noqa: F401

print("[talon-controller] loaded", candidates())
