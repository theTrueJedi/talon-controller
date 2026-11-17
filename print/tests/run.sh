#!/usr/bin/env bash
# Housing test harness. Prints PASS/FAIL per case; exits non-zero on first FAIL.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/../talon-housing.scad"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

if command -v openscad >/dev/null 2>&1; then
    OPENSCAD=openscad
else
    OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
fi

# render <name> [openscad -D args...]: sets $rc, $err; STL at $out/<name>.stl
render() {
    local name="$1"; shift
    "$OPENSCAD" --backend=manifold -o "$out/$name.stl" "$@" "$src" \
        >/dev/null 2>"$out/$name.err"
    rc=$?
    err="$(cat "$out/$name.err")"
}

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; [ -n "${err:-}" ] && echo "$err" | tail -5; exit 1; }

# expect_ok <name> [args...]
expect_ok() {
    local name="$1"; shift
    render "$name" "$@"
    [ "$rc" -eq 0 ] || fail "$name" "exit $rc, expected 0"
    pass "$name"
}

# expect_fail <name> <stderr substring> [args...]
expect_fail() {
    local name="$1" msg="$2"; shift 2
    render "$name" "$@"
    [ "$rc" -ne 0 ] || fail "$name" "exit 0, expected non-zero"
    case "$err" in *"$msg"*) ;; *) fail "$name" "stderr lacks '$msg'";; esac
    pass "$name"
}

expect_ok   checks-pass -D 'part="checks"'
bbox="$(python3 "$here/stl_bbox.py" "$out/checks-pass.stl")"
[ "$bbox" = "1.00 1.00 1.00" ] || fail checks-bbox "got '$bbox'"
pass checks-bbox

expect_fail checks-fail-glow "glow_gap too large" -D glow_gap=12
expect_fail checks-fail-cap  "cap covers LEDs"    -D cap_d=34
expect_fail checks-fail-tab  "key tab on wire slot" -D 'key_tab_angles=[350]'
expect_fail checks-fail-float "cap_float gap" -D cap_float=0.4
expect_fail checks-fail-cbore "collar counterbore gap" -D collar_clr_h=-0.1
expect_fail checks-fail-stem  "stem-to-nut gap" -D press_travel=1.1

expect_ok   hood-render -D 'part="hood"'
# ECHO: hood_top_z = 13.1, hood_od = 55.2, key_tab_len = 1.6
dims="$(echo "$err" | sed -n 's/^ECHO: hood_top_z = \([0-9.]*\), hood_od = \([0-9.]*\), key_tab_len = \([0-9.]*\)$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail hood-bbox "no hood dims echo"
bbox="$(python3 "$here/stl_bbox.py" "$out/hood-render.stl")"
# Default key tabs sit at 90/270 (both on the X axis): they widen x only.
python3 - "$bbox" "$dims" <<'PY' || fail hood-bbox "got '$bbox', dims=$dims"
import sys
x, y, z = map(float, sys.argv[1].split())
top, od, tab = map(float, sys.argv[2].split())
assert abs(x - (od + 2 * tab)) <= 0.1 and abs(y - od) <= 0.1 and abs(z - top) <= 0.1
PY
pass hood-bbox

expect_ok   face-render        -D 'part="face"'
expect_ok   face-screws-render -D 'part="face"' -D hood_screws=true
expect_ok   hood-screws-render -D 'part="hood"' -D hood_screws=true
expect_ok   halo-render        -D 'part="halo"' -D halo_block=true
expect_fail halo-off           "part halo needs" -D 'part="halo"'

expect_ok   cap-render -D 'part="cap"'
# ECHO: cap_d = 28, cap_h = 14.5
dims="$(echo "$err" | sed -n 's/^ECHO: cap_d = \([0-9.]*\), cap_h = \([0-9.]*\)$/\1 \2/p' | head -1)"
[ -n "$dims" ] || fail cap-bbox "no cap dims echo"
bbox="$(python3 "$here/stl_bbox.py" "$out/cap-render.stl")"
python3 - "$bbox" "$dims" <<'PY' || fail cap-bbox "got '$bbox', dims=$dims"
import sys
x, y, z = map(float, sys.argv[1].split())
d, h = map(float, sys.argv[2].split())
assert abs(x - d) <= 0.1 and abs(y - d) <= 0.1 and abs(z - h) <= 0.1
PY
pass cap-bbox
expect_ok   cap-knurl-render -D 'part="cap"' -D cap_knurl=true

expect_ok   driver-render -D 'part="nut_driver"'
bbox="$(python3 "$here/stl_bbox.py" "$out/driver-render.stl")"
python3 - "$bbox" <<'PY' || fail driver-bbox "got '$bbox'"
import sys
x, y, z = map(float, sys.argv[1].split())
assert x <= 20.1 and y <= 20.1
PY
pass driver-bbox

# STL must be non-trivial (> 1 KB).
expect_big() {
    local size; size=$(wc -c < "$out/$1.stl")
    [ "$size" -gt 1024 ] || fail "$1-size" "STL only $size bytes"
    pass "$1-size"
}

# stl_check <stl> <bodies> <x> <y> <z>: on the bed (min z = 0), the given
# number of separate bodies, and bbox within 0.1 of x y z.
stl_check() {
    PYTHONDONTWRITEBYTECODE=1 python3 - "$here" "$@" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from stl_bbox import vertices
path, bodies = sys.argv[2], int(sys.argv[3])
want = list(map(float, sys.argv[4:7]))
vs = list(vertices(path))
assert abs(min(v[2] for v in vs)) <= 0.01, "not on the bed"
size = [max(v[i] for v in vs) - min(v[i] for v in vs) for i in range(3)]
assert all(abs(s - w) <= 0.1 for s, w in zip(size, want)), f"bbox {size} != {want}"
# Count bodies: triangles sharing a vertex belong to the same body.
parent = {}
def find(a):
    while parent.setdefault(a, a) != a:
        parent[a] = parent[parent[a]]; a = parent[a]
    return a
key = lambda v: tuple(round(c, 4) for c in v)
for i in range(0, len(vs), 3):
    a, b, c = (find(key(v)) for v in vs[i:i + 3])
    parent[b] = a; parent[find(c)] = a
n = len({find(k) for k in list(parent)})
assert n == bodies, f"{n} bodies, expected {bodies}"
PY
}

expect_ok   fit-renders -D 'part="fit_test"'
expect_big  fit-renders
# ECHO: fit_footprint = [x, y, z]
dims="$(echo "$err" | sed -n 's/^ECHO: fit_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail fit-layout "no fit_footprint echo"
# Face disc, well-floor washer, bore plug, hood segment.
stl_check "$out/fit-renders.stl" 4 $dims || fail fit-layout "dims=$dims"
pass fit-layout

expect_ok   glow-renders -D 'part="glow_test"'
expect_big  glow-renders
dims="$(echo "$err" | sed -n 's/^ECHO: glow_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail glow-layout "no glow_footprint echo"
# One body: digits are embossed onto the strip, not loose islands.
stl_check "$out/glow-renders.stl" 1 $dims || fail glow-layout "dims=$dims"
pass glow-layout
