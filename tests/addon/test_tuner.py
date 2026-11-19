import json
import os
import sys
import tempfile
import unittest
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from addon.protocol import DEFAULT_LOOKS, Look  # noqa: E402
from addon.tuner import PREVIEW_TTL_S, Tuner  # noqa: E402


class Clock:
    def __init__(self):
        self.t = 50.0

    def __call__(self):
        return self.t


class TunerTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        html = os.path.join(self.dir.name, "tuner.html")
        with open(html, "w") as f:
            f.write("<!doctype html><title>Ring tuner</title>")
        self.saved = []
        self.clock = Clock()
        self.tuner = Tuner(html, lambda: dict(DEFAULT_LOOKS), self.saved.append, clock=self.clock)
        self.assertTrue(self.tuner.start(0))

    def tearDown(self):
        self.tuner.stop()
        self.dir.cleanup()

    def get(self, path):
        with urllib.request.urlopen(self.tuner.url + path, timeout=2) as r:
            return r.status, r.read()

    def post(self, path, body):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        req = urllib.request.Request(self.tuner.url + path, data=data, method="POST",
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=2) as r:
                return r.status
        except urllib.error.HTTPError as e:
            return e.code

    LOOK = {"pat": "solid", "c1": "ff8a0d", "c2": "c07414", "speed": 12, "bri": 55}

    def test_serves_page(self):
        status, body = self.get("/")
        self.assertEqual(status, 200)
        self.assertIn(b"Ring tuner", body)

    def test_get_looks(self):
        _, body = self.get("/looks")
        data = json.loads(body)
        self.assertEqual(data["looks"]["command"],
                         {"pat": "solid", "c1": "18ff6a", "c2": "109847", "speed": 15, "bri": 71})
        self.assertEqual(data["patterns"], ["solid", "breathe", "gradspin"])

    def test_preview_round_trip(self):
        self.assertIsNone(self.tuner.preview())
        self.assertEqual(self.post("/preview", {"state": "sleep", "look": self.LOOK}), 204)
        self.assertEqual(self.tuner.preview(), ("sleep", Look("solid", "ff8a0d", "c07414", 12, 55)))

    def test_preview_expires(self):
        self.post("/preview", {"state": "sleep", "look": self.LOOK})
        self.clock.t += PREVIEW_TTL_S - 0.1
        self.assertIsNotNone(self.tuner.preview())
        self.clock.t += 0.2
        self.assertIsNone(self.tuner.preview())

    def test_end_clears_preview(self):
        self.post("/preview", {"state": "sleep", "look": self.LOOK})
        self.assertEqual(self.post("/end", {}), 204)
        self.assertIsNone(self.tuner.preview())

    def test_save_calls_on_save(self):
        self.assertEqual(self.post("/save", {"looks": {"sleep": self.LOOK}}), 204)
        self.assertEqual(self.saved, [{"sleep": Look("solid", "ff8a0d", "c07414", 12, 55)}])

    def test_bad_json_400(self):
        self.assertEqual(self.post("/preview", b"{nope"), 400)
        self.assertEqual(self.post("/save", b"[]"), 400)
        self.assertIsNone(self.tuner.preview())
        self.assertEqual(self.saved, [])

    def test_bad_look_400(self):
        bad = dict(self.LOOK, c1="zzzzzz")
        self.assertEqual(self.post("/preview", {"state": "sleep", "look": bad}), 400)
        self.assertEqual(self.post("/preview", {"state": "party", "look": self.LOOK}), 400)
        self.assertEqual(self.post("/save", {"looks": {"sleep": dict(self.LOOK, bri=300)}}), 400)
        self.assertIsNone(self.tuner.preview())
        self.assertEqual(self.saved, [])

    def test_binds_localhost(self):
        self.assertTrue(self.tuner.url.startswith("http://127.0.0.1:"))

    def test_second_start_on_same_port_fails(self):
        port = int(self.tuner.url.rsplit(":", 1)[1])
        other = Tuner(self.tuner.html_path, dict, print)
        self.assertFalse(other.start(port))


if __name__ == "__main__":
    unittest.main()
