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

# `run.sh export`: write every part to print/stl/<part>.stl (binary STL) and stop.
if [ "${1:-}" = export ]; then
    for p in shell hood cap bottom foot nut_driver fit_test glow_test halo; do
        extra=(); [ "$p" = halo ] && extra=(-D halo_block=true)
        "$OPENSCAD" --backend=manifold --export-format binstl -o "$here/../stl/$p.stl" \
            -D "part=\"$p\"" ${extra[@]+"${extra[@]}"} "$src" >/dev/null 2>"$out/export.err" \
            || { echo "FAIL export $p"; tail -5 "$out/export.err"; exit 1; }
        echo "EXPORT $p -> stl/$p.stl ($(wc -c < "$here/../stl/$p.stl" | tr -d ' ') bytes)"
    done
    exit 0
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
# Lip ring, face disc (pin up), well-floor washer, bore plug, hood segment.
stl_check "$out/fit-renders.stl" 5 $dims || fail fit-layout "dims=$dims"
pass fit-layout

expect_ok   glow-renders -D 'part="glow_test"'
expect_big  glow-renders
dims="$(echo "$err" | sed -n 's/^ECHO: glow_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail glow-layout "no glow_footprint echo"
# One body: digits are embossed onto the strip, not loose islands.
stl_check "$out/glow-renders.stl" 1 $dims || fail glow-layout "dims=$dims"
pass glow-layout

# ---- Shell (Task 5) ----
expect_ok   shell-render -D 'part="shell"'
expect_big  shell-render
# ECHO: box_footprint = [w, d]  /  ECHO: box_h = h, hood_od = o, wall = t
fp="$(echo "$err" | sed -n 's/^ECHO: box_footprint = \[\(.*\), \(.*\)\]$/\1 \2/p' | head -1)"
hw="$(echo "$err" | sed -n 's/^ECHO: box_h = \([0-9.]*\), hood_od = \([0-9.]*\), wall = \([0-9.]*\)$/\1 \2 \3/p' | head -1)"
[ -n "$fp" ] && [ -n "$hw" ] || fail shell-bbox "no box_footprint / box_h echo"
bbox="$(python3 "$here/stl_bbox.py" "$out/shell-render.stl")"
# Printed on its back wall: STL x = box width, y = box height, z = box depth.
python3 - "$bbox" "$fp" "$hw" <<'PY' || fail shell-bbox "got '$bbox', footprint=$fp, h/od/wall=$hw"
import sys
x, y, z = map(float, sys.argv[1].split())
w, d = map(float, sys.argv[2].split())
h, od, wall = map(float, sys.argv[3].split())
assert abs(x - w) <= 0.1 and abs(y - h) <= 0.1 and abs(z - d) <= 0.1
assert w >= od + 2 * wall + 4
PY
pass shell-bbox
# One body: bosses, cradle and channel ribs all fused to the walls.
stl_check "$out/shell-render.stl" 1 $(echo "$fp" | cut -d' ' -f1) $(echo "$hw" | cut -d' ' -f1) $(echo "$fp" | cut -d' ' -f2) \
    || fail shell-layout "footprint=$fp h=$hw"
pass shell-layout

# Review Focus 3: the C3-Zero front stop sits against the board's inner edge.
gap="$(echo "$err" | sed -n 's/^ECHO: c3_stop_gap = \([-0-9.e]*\)$/\1/p' | head -1)"
[ -n "$gap" ] || fail c3-stop "no c3_stop_gap echo"
python3 -c "import sys; g = float(sys.argv[1]); assert 0 <= g <= 0.3" "$gap" || fail c3-stop "gap $gap"
pass c3-stop
expect_fail c3-wall-slot "C3 wall slot" -D 'part="shell"' -D c3_wall_slot=2
# Fix round 1: the pin must reach through the KY-040 PCB; nut slots need a detent.
expect_fail checks-fail-pin    "pin stops short of the KY-040 PCB bottom" -D pin_through=0
expect_fail checks-fail-detent "nut detent" -D m3_detent=0

# ---- Bottom plate, feet, assembly, interference (Task 6) ----
for p in shell hood cap bottom foot nut_driver fit_test glow_test; do
    render "all-$p" -D "part=\"$p\""
    [ "$rc" -eq 0 ] || fail all-parts-render "$p: exit $rc"
done
pass all-parts-render

expect_ok   bottom-render -D 'part="bottom"'
# ECHO: bottom_footprint = [w, d, t]
dims="$(echo "$err" | sed -n 's/^ECHO: bottom_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail bottom-layout "no bottom_footprint echo"
stl_check "$out/bottom-render.stl" 1 $dims || fail bottom-layout "dims=$dims"
pass bottom-layout

expect_ok   assembly-render -D 'part="assembly"'

# Interference: every pair that must not touch, intersected and unioned.
# Empty at defaults; a deliberately broken clearance must show up.
# An aborted render (failed assert) also says "empty", so rule out ERROR first.
render interference-empty -D 'part="interference"'
case "$err" in *ERROR*) fail interference-empty "render aborted";; esac
case "$err" in *"top level object is empty"*) pass interference-empty;;
    *) fail interference-empty "parts or ghosts collide (rc $rc)";; esac
# Deliberate breaks: collar (7) through a 6.5 face/hood hole; cap bore tighter than the shaft.
for brk in collar_hole_d=6.5 shaft_clr=-0.2; do
    render "interference-detects-$brk" -D 'part="interference"' -D "$brk"
    case "$err" in *ERROR*|*"top level object is empty"*) fail "interference-detects-$brk" "collision not caught";; esac
    [ "$rc" -eq 0 ] || fail "interference-detects-$brk" "exit $rc"
    pass "interference-detects-$brk"
done
expect_fail checks-fail-screw "M3 head" -D m3_screw_l=12
