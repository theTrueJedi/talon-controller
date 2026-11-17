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

expect_ok   hood-render -D 'part="hood"'
z="$(echo "$err" | sed -n 's/^ECHO: hood_top_z = //p' | head -1)"
[ -n "$z" ] || fail hood-bbox "no hood_top_z echo"
bbox="$(python3 "$here/stl_bbox.py" "$out/hood-render.stl")"
python3 - "$bbox" "$z" <<'PY' || fail hood-bbox "got '$bbox', hood_top_z=$z"
import sys
x, y, zz = map(float, sys.argv[1].split()); want = float(sys.argv[2]) + 1
assert abs(x - 55.2) <= 0.1 and abs(y - 55.2) <= 0.1 and abs(zz - want) <= 0.1
PY
pass hood-bbox

expect_ok   face-render        -D 'part="face"'
expect_ok   face-screws-render -D 'part="face"' -D hood_screws=true
expect_ok   hood-screws-render -D 'part="hood"' -D hood_screws=true
expect_ok   halo-render        -D 'part="halo"' -D halo_block=true
expect_fail halo-off           "part halo needs" -D 'part="halo"'
