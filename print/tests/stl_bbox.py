#!/usr/bin/env python3
"""Print the x y z bounding-box sizes of an STL (ASCII or binary), 2 decimals."""
import struct
import sys


def vertices(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:5] == b"solid" and b"facet" in data[:1024]:
        for line in data.decode("ascii", "replace").splitlines():
            parts = line.split()
            if parts and parts[0] == "vertex":
                yield tuple(float(v) for v in parts[1:4])
        return
    (count,) = struct.unpack_from("<I", data, 80)
    for i in range(count):
        base = 84 + i * 50 + 12
        for k in range(3):
            yield struct.unpack_from("<3f", data, base + 12 * k)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: stl_bbox.py <file.stl>")
    vs = list(vertices(sys.argv[1]))
    if not vs:
        sys.exit("no vertices in " + sys.argv[1])
    sizes = [max(v[i] for v in vs) - min(v[i] for v in vs) for i in range(3)]
    print(" ".join(f"{s:.2f}" for s in sizes))


if __name__ == "__main__":
    main()
