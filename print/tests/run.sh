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

# `run.sh export`: render every part; save it as print/stl/<part>_v<N+1>.stl only
# when its geometry differs from the newest <part>_v<N>.stl. Old revisions stay.
if [ "${1:-}" = export ]; then
    stl="$here/../stl"
    for p in shell hood cap bottom foot nut_driver fit_test frame_test glow_test halo c3_clip; do
        extra=(); [ "$p" = halo ] && extra=(-D halo_block=true)
        "$OPENSCAD" --backend=manifold --export-format binstl -o "$out/$p.stl" \
            -D "part=\"$p\"" ${extra[@]+"${extra[@]}"} "$src" >/dev/null 2>"$out/export.err" \
            || { echo "FAIL export $p"; tail -5 "$out/export.err"; exit 1; }
        n=0
        for f in "$stl/${p}"_v*.stl; do
            [ -e "$f" ] || continue
            v="${f##*_v}"; v="${v%.stl}"
            [ "$v" -gt "$n" ] && n="$v"
        done
        if [ "$n" -gt 0 ] && [ "$(PYTHONDONTWRITEBYTECODE=1 python3 "$here/stl_same.py" "$here" "$out/$p.stl" "$stl/${p}_v$n.stl")" = same ]; then
            echo "SAME   $p (stl/${p}_v$n.stl)"
        else
            cp "$out/$p.stl" "$stl/${p}_v$((n + 1)).stl"
            echo "NEW    $p -> stl/${p}_v$((n + 1)).stl"
        fi
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

# expect_empty <name> [args...]: renders clean (no ERROR/WARNING) to nothing.
expect_empty() {
    local name="$1"; shift
    render "$name" "$@"
    case "$err" in *ERROR*|*WARNING*) fail "$name" "render aborted or warned";; esac
    case "$err" in *"top level object is empty"*) ;; *) fail "$name" "not empty (rc $rc)";; esac
    pass "$name"
}
# expect_solid <name> [args...]: renders clean to something (a caught break).
expect_solid() {
    local name="$1"; shift
    render "$name" "$@"
    case "$err" in *ERROR*|*WARNING*|*"top level object is empty"*) fail "$name" "break not caught";; esac
    [ "$rc" -eq 0 ] || fail "$name" "exit $rc"
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
# press_travel is the measured shaft gap: one source, so raising shaft_gap trips it.
expect_fail checks-fail-stem  "stem-to-nut gap" -D shaft_gap=1.1
# Per-feature fits: each one reaches its own check.
expect_fail checks-fail-socket-fit "driver socket wall too thin" -D socket_fit=2
expect_fail checks-fail-c3-loose   "C3 front stop gap" -D c3_fit=0.5
expect_fail checks-fail-c3-tight   "C3 front stop gap" -D c3_fit=0
expect_fail checks-fail-nut-t      "M3 nut thicker than its slot" -D m3_nut_t=2.7

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

# Frame test: the fit coupon's centre disc alone (collar hole + body frame).
expect_ok   frame-renders -D 'part="frame_test"'
dims="$(echo "$err" | sed -n 's/^ECHO: frame_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail frame-layout "no frame_footprint echo"
stl_check "$out/frame-renders.stl" 1 $dims || fail frame-layout "dims=$dims"
pass frame-layout

expect_ok   glow-renders -D 'part="glow_test"'
expect_big  glow-renders
dims="$(echo "$err" | sed -n 's/^ECHO: glow_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail glow-layout "no glow_footprint echo"
# Four tiles, one per gap, face down; digits embossed on a leg, not loose islands.
stl_check "$out/glow-renders.stl" 4 $dims || fail glow-layout "dims=$dims"
pass glow-layout

# ---- Shell (Task 5) ----
# Taller base: base_extra adds exactly its height to box_h, and box_d stays put.
render base-zero -D 'part="shell"' -D base_extra=0
h0="$(echo "$err" | sed -n 's/^ECHO: box_h = \([0-9.]*\),.*/\1/p' | head -1)"
d0="$(echo "$err" | sed -n 's/^ECHO: box_footprint = \[.*, \(.*\)\]$/\1/p' | head -1)"
expect_ok   shell-render -D 'part="shell"'
expect_big  shell-render
h1="$(echo "$err" | sed -n 's/^ECHO: box_h = \([0-9.]*\),.*/\1/p' | head -1)"
d1="$(echo "$err" | sed -n 's/^ECHO: box_footprint = \[.*, \(.*\)\]$/\1/p' | head -1)"
python3 -c "import sys; h0,h1,d0,d1=map(float,sys.argv[1:]); assert abs(h1-h0-5)<0.01 and abs(d1-d0)<0.01" "$h0" "$h1" "$d0" "$d1" \
    || fail base-extra "box_h $h0 -> $h1, box_d $d0 -> $d1"
pass base-extra
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
# One body: bosses and channel ribs all fused to the walls.
stl_check "$out/shell-render.stl" 1 $(echo "$fp" | cut -d' ' -f1) $(echo "$hw" | cut -d' ' -f1) $(echo "$fp" | cut -d' ' -f2) \
    || fail shell-layout "footprint=$fp h=$hw"
pass shell-layout

# Review Focus 3: the C3-Zero front stop sits against the board's inner edge.
gap="$(echo "$err" | sed -n 's/^ECHO: c3_stop_gap = \([-0-9.e]*\)$/\1/p' | head -1)"
[ -n "$gap" ] || fail c3-stop "no c3_stop_gap echo"
python3 -c "import sys; g = float(sys.argv[1]); assert 0 <= g <= 0.3" "$gap" || fail c3-stop "gap $gap"
pass c3-stop
# Plate removal path: the back-wall board slot (with the header plug recess)
# and the USB notch open down to the rim. A thin box at the rim inside each cut
# must miss the shell; closing the cuts above the rim must make it hit.
for pr in c3_notch c3_slot; do
    expect_empty "shell-probe-$pr" -D 'part="shell_probe"' -D "probe=\"$pr\""
    expect_solid "shell-probe-$pr-detects" -D 'part="shell_probe"' -D "probe=\"$pr\"" -D c3_back_cuts_z0=1
done
# The C3 cradle lives on the bottom plate: nothing of the shell over its plan
# area, and the shell stays one body wherever the board sits (the default
# render is shell-layout above). Centred, the BR weight pocket moves off the
# TL one's row overlap.
expect_empty shell-no-cradle-probe -D 'part="shell_probe"' -D 'probe="c3_cradle"'
expect_solid shell-no-cradle-probe-detects -D 'part="shell_probe"' -D 'probe="c3_cradle"' -D 'c3_cradle_y1=72.3'
expect_ok   shell-no-cradle -D 'part="shell"' -D c3_x=0 -D 'weight_pockets=[[-22.85,3,0],[3.2,3,0],[-22.85,46,0],[3.2,46,0]]'
stl_check "$out/shell-no-cradle.stl" 1 $(echo "$fp" | cut -d' ' -f1) $(echo "$hw" | cut -d' ' -f1) $(echo "$fp" | cut -d' ' -f2) \
    || fail shell-no-cradle "c3_x=0: not one body"
expect_fail checks-fail-c3-boss "C3 cradle hits a rear boss" -D c3_x=16

expect_fail c3-wall-slot "C3 wall slot" -D 'part="shell"' -D c3_wall_slot=2
# Direct-soldered C3-Zero: solder-tail grooves under the pin rows, and a
# separate clip holding the inner short edge's middle (off the pin-row corners).
expect_fail checks-fail-groove "C3 solder groove cuts through the pedestal" -D 'c3_groove=[3, 4]'
expect_fail checks-fail-notch  "C3 clip notch cuts through the rail" -D c3_clip_engage=1.1
expect_fail checks-fail-engage "C3 clip barb engagement" -D c3_clip_engage=0.3
expect_fail checks-fail-corner "C3 clip within c3_corner_clr of a pin-row corner hole" -D c3_hole_end=0.1
expect_ok   c3-clip-render -D 'part="c3_clip"'
dims="$(echo "$err" | sed -n 's/^ECHO: c3_clip_bed = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail c3-clip-layout "no c3_clip_bed echo"
stl_check "$out/c3-clip-render.stl" 1 $dims || fail c3-clip-layout "dims=$dims"
pass c3-clip-layout
# The encoder body's square top locates in a frame under the face; nut slots need a detent.
expect_fail checks-fail-frame  "body frame reaches the KY-040 PCB" -D body_frame_h=7
expect_fail checks-fail-detent "nut detent" -D m3_detent=0

# ---- Bottom plate, feet, assembly, interference (Task 6) ----
for p in shell hood cap bottom foot nut_driver fit_test glow_test c3_clip; do
    render "all-$p" -D "part=\"$p\""
    [ "$rc" -eq 0 ] || fail all-parts-render "$p: exit $rc"
done
pass all-parts-render

expect_ok   bottom-render -D 'part="bottom"'
# ECHO: bottom_footprint = [w, d, t]
dims="$(echo "$err" | sed -n 's/^ECHO: bottom_footprint = \[\(.*\), \(.*\), \(.*\)\]$/\1 \2 \3/p' | head -1)"
[ -n "$dims" ] || fail bottom-layout "no bottom_footprint echo"
# Plate plus the C3 cradle on top (z = plate_t + c3_top_h). Each sealed weight
# pocket is a closed cavity, which the vertex-sharing count sees as its own body.
stl_check "$out/bottom-render.stl" 5 $dims || fail bottom-layout "dims=$dims"
pass bottom-layout
# Print pause height for inserting the weights: pocket tops, bottom_t + weight z.
pz="$(echo "$err" | sed -n 's/^ECHO: weight_pause_z = \([-0-9.e]*\)$/\1/p' | head -1)"
[ -n "$pz" ] || fail weight-pause "no weight_pause_z echo"
python3 -c "import sys; assert abs(float(sys.argv[1]) - 8.8) <= 0.01" "$pz" || fail weight-pause "got $pz"
pass weight-pause
expect_fail checks-fail-pocket-overlap "weight pockets overlap" -D 'weight_pockets=[[-22.85,3,0],[-22.85,3,0],[3.2,3,0],[-22.85,46,0]]'

expect_ok   assembly-render -D 'part="assembly"'

# Interference: every pair that must not touch, intersected and unioned.
# Empty at defaults; a deliberately broken clearance must show up.
# An aborted render (failed assert) also says "empty", so rule out ERROR first.
render interference-empty -D 'part="interference"'
case "$err" in *ERROR*) fail interference-empty "render aborted";; esac
case "$err" in *"top level object is empty"*) pass interference-empty;;
    *) fail interference-empty "parts or ghosts collide (rc $rc)";; esac
# Deliberate breaks: collar (7) through a 6.5 face/hood hole; cap bore tighter
# than the shaft; body frame smaller than the encoder body; C3 clip legs
# moved into the rails; C3 header plug wires too long (they reach the -X side
# wall); C3 centred (its plugs reach the rear-left boss and wall).
nocradle_w='weight_pockets=[[-22.85,3,0],[3.2,3,0],[-22.85,46,0],[3.2,46,0]]'
for brk in collar_hole_d=6.5 shaft_clr=-0.2 body_fit=-0.2 c3_clip_leg_x=10 plug_wire_room=40 "c3_x=0;$nocradle_w"; do
    name="interference-detects-${brk%%;*}"
    render "$name" -D 'part="interference"' -D "$brk"
    case "$err" in *ERROR*|*"top level object is empty"*) fail "$name" "collision not caught";; esac
    [ "$rc" -eq 0 ] || fail "$name" "exit $rc"
    pass "$name"
done
expect_fail checks-fail-c3-hdr "C3 header longer than the board" -D c3_hdr_n=10
expect_fail checks-fail-ky-hdr "KY-040 header wider than the board" -D ky_hdr_n=8
# 12 sits flush in the 10 mm plate; 16 sticks out.
expect_fail checks-fail-screw "M3 head" -D m3_screw_l=16
