#!/usr/bin/env python3
"""stl_same.py <tests dir> <a.stl> <b.stl>: print "same" if both STLs have the
same shape, else "diff". Compares volume, surface area, bounding box and
centroid, not triangles: the manifold backend's triangulation can vary
between runs of the same model."""
import sys

sys.path.insert(0, sys.argv[1])
from stl_bbox import vertices


def fingerprint(path):
    vs = list(vertices(path))
    vol = area = 0.0
    c = [0.0, 0.0, 0.0]
    for i in range(0, len(vs), 3):
        a, b, d = vs[i:i + 3]
        v6 = (a[0] * (b[1] * d[2] - b[2] * d[1])
              - a[1] * (b[0] * d[2] - b[2] * d[0])
              + a[2] * (b[0] * d[1] - b[1] * d[0]))
        vol += v6 / 6
        for k in range(3):
            c[k] += v6 / 6 * (a[k] + b[k] + d[k]) / 4
        u = [b[k] - a[k] for k in range(3)]
        w = [d[k] - a[k] for k in range(3)]
        x = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        area += (x[0] ** 2 + x[1] ** 2 + x[2] ** 2) ** 0.5 / 2
    lo = [min(v[k] for v in vs) for k in range(3)]
    hi = [max(v[k] for v in vs) for k in range(3)]
    return [vol, area] + lo + hi + [ck / vol for ck in c]


a, b = fingerprint(sys.argv[2]), fingerprint(sys.argv[3])
# 1e-6 relative on volume/area (catches a 0.03 mm fit change on the shell;
# triangulation noise is ~1e-8); 0.001 mm on box and centroid.
tol = [abs(a[0]) * 1e-6, abs(a[1]) * 1e-6] + [0.001] * 9
print("same" if all(abs(x - y) <= t for x, y, t in zip(a, b, tol)) else "diff")
