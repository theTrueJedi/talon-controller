# Talon Controller Housing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A parametric OpenSCAD model of the controller housing: shell, hood diffuser, cap, bottom plate, feet, nut driver, and test coupons. It exports print-ready STLs.

**Architecture:** One entry file with a `part` switch. It includes a single
parameters file (every measurement and clearance) and one file per part.
Geometry is built in a local **face frame**, then the shell places it on the
30° slope. Tests have three layers:
- `assert()` checks on the parameter math (the stack, clearances)
- CLI renders of every part, with bounding-box checks
- an interference render of the assembly that must come out empty

**Tech Stack:** OpenSCAD `openscad@snapshot` (Homebrew cask 2026.10.11, free/GPL; the stable 2021.01 cask is disabled by Homebrew), `--backend=manifold`; bash; Python 3 stdlib for STL bounding boxes; Bambu Studio for slicing (Evan).

**Spec:** `docs/superpowers/specs/2026-11-16-talon-housing-design.md`. Measurements: `docs/housing-measurements.md`.

## Global Constraints

- All dimensions are mm and are named parameters in `print/lib/params.scad`. No magic numbers in part files.
- **Face frame:** origin at the shaft axis on the face's top plane. +Z runs along the shaft, out of the box. +Y points up-slope, toward the back. +X points to the right as seen from the front.
- Slope 30°. Face about 72 along the slope. Minimum wall 2. Inside clearance ≥ 1 around every part.
- No visible fasteners on the face. M3 + captive hex nuts for the bottom plate. No M2 except the optional hood fallback (`hood_screws = false` by default).
- The ring centers on the shaft. The KY-040 header edge points +Y (toward the back).
- The diffuser hood underside is one flat plane, sitting on the face top (z = 0).
- Materials: shell/cap/bottom opaque; hood translucent PETG; feet TPU. Each part is exported flat on its print face.
- The weight pocket is 19.65 × 22 × 5.8, with no added clearance (the adhesive backing is already allowed for).

## Review Focus

1. **Parameter changes that silently break the stack** (e.g. Evan raises `glow_gap` to 12). The checks must fail loudly with a message naming the limit, not render a cap with no overhang. → Task 1 negative tests.
2. **D-bore orientation and fit on the real shaft.** The shaft's D size is assumed (Ø6, flat 4.5). The fit coupon must print the bore so Evan can test it before the full cap. → Task 4.
3. **Pressing the cable into USB-C pushes the C3-Zero inward.** The cradle's front stop must sit in the path of that push. → Task 5 bbox/position test.
4. **The hood tab/notch key collides with the ring wire slot.** Notch and slot angles must differ. → Task 2 assert.
5. **The KY-040 PCB or the C3-Zero hits a shell wall, a boss or the bottom plate.** → Task 6 interference render.

---

### Task 0: Tooling (needs Evan's OK to install)

**Files:** none.

- [ ] **Step 1:** `brew install --cask openscad@snapshot`. Then: `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD --version` prints 2026.x. Alias it as `SCAD` in `print/tests/run.sh`, resolving `openscad` on PATH first, then the app path.

### Task 1: Parameters, stack checks, test harness

**Files:**
- Create: `print/lib/params.scad`: every value below.
- Create: `print/lib/checks.scad`: `assert()`s over params.
- Create: `print/tests/run.sh`, `print/tests/stl_bbox.py`
- Create: `print/talon-housing.scad`: `include <lib/params.scad>; include <lib/checks.scad>;` plus the `part` switch (`"checks"` renders a 1 mm cube only, so the export succeeds).

**Interfaces:**
- Produces: the parameter names below, plus derived values: `body_top_z = -face_t`, `collar_top_z`, `shaft_top_z`, `ring_top_z = ring_t`, `hood_under_z = ring_top_z + glow_gap`, `hood_top_z`, `cap_under_z = hood_top_z + cap_float`, `cap_top_z = shaft_top_z + cap_over_shaft`, `nut_top_z = floor_t + washer_t + nut_t`, `nut_corner = nut_af / cos(30)`, `max_glow_gap`.
- `stl_bbox.py <file.stl>` prints `x y z` sizes with 2 decimals.
- `run.sh` runs all cases. It exits non-zero on the first failure and prints `PASS <case>` or `FAIL <case>`.

Parameter values (from the spec and the measurements file):
- **Ring:** `ring_od=50 ring_id=37 ring_t=3.1`
- **KY-040 board:**
  - `ky_pcb=[26,19,1.5]`
  - shaft position: `ky_shaft_from_header_edge=14.5 ky_shaft_from_hole_edge=9`
  - holes: `ky_hole_d=3 ky_hole_x_from_header=[4.5,21.5] ky_hole_from_long_edge=2.5`
- **Encoder:** `body=[12,12,6.5] collar_d=7 collar_h=7 shaft_gap=0.5 shaft_round_h=5 shaft_d_h=7 shaft_d=6 shaft_flat=4.5`
- **Nut and washer:** `nut_af=10 nut_t=2 washer_od=11.5 washer_t=0.5`
- **C3-Zero:** `c3=[24,18.05,1.0] usb_port=[8.85,3.15] usb_plug_hole=[12.5,7.5]`
- **Weights:** `weight=[19.65,22,5.8] weight_count=4`
- **Face and hood:** `face_t=1.5 floor_t=1.5 hood_id=52 hood_wall=1.6 hood_top_t=2 glow_gap=8 well_id=16 collar_hole_d=7.4`
- **Cap:** `cap_d=28 cap_float=1.5 cap_over_shaft=1.5 stem_od=15`
- **Fits and pins:** `pin_d=2.6 clr=1 fit=0.2`
- **Box:** `slope=30 face_len=72 wall=2`
- **Options:** `hood_screws=false halo_block=false key_tab_angles=[90,270] wire_slot_angle=0` (degrees about +Z; 0 = +Y)

- [ ] **Step 1: Write the checks as `assert(cond, "message")` in `checks.scad`** (written first; they fail until the params exist):
  - collar spare `collar_h - (face_t+floor_t+washer_t+nut_t) >= 1.0`, message "collar thread: nut has <1mm engagement"
  - `hood_top_z <= cap_top_z - 3.5 - cap_float`, message "glow_gap too large: max is <max_glow_gap>"
  - `cap_d <= 32`, message "cap covers LEDs"
  - `well_id >= nut_corner + 3`, message "well too narrow for nut driver"
  - `stem_od <= well_id - 1`
  - `hood_id >= ring_od + 2`
  - for every key tab angle `a`, `abs(a - wire_slot_angle) mod 360 >= 30`, message "key tab on wire slot"
  - far KY hole center (header-side hole, 10 from the shaft) to the nearest body corner `>= pin_d/2 + 0.5`
- [ ] **Step 2:** Run `print/tests/run.sh`. Expect FAIL: undefined variables/asserts.
- [ ] **Step 3:** Write `params.scad` with the values above and the derived values.
- [ ] **Step 4:** Add cases to `run.sh`:
  - `checks-pass`: `-D 'part="checks"'` exits 0.
  - `checks-fail-glow`: `-D glow_gap=12` exits non-zero, and stderr contains "glow_gap too large".
  - `checks-fail-cap`: `-D cap_d=34` exits non-zero.

  Run it. Expect all PASS.
- [ ] **Step 5:** Commit `print/` ("Housing: params, stack checks, test harness").

### Task 2: Face center and hood

**Files:**
- Create: `print/parts/face.scad`: `module face_center(r)`. A face-plate disc of radius `r` and thickness `face_t` (z −face_t…0), with:
  - the collar hole
  - the anti-rotation pin hanging into the far KY hole (length = `body[2]`, so it doesn't reach the PCB underside)
  - the hood seat lip (outside the hood OD, height 1, width 1.6) with key notches at `key_tab_angles`
  - a ring wire slot (8×3) through the face under the ring band at `wire_slot_angle`
  - when `hood_screws` is set: M2 clearance holes on the hood wall circle
- Create: `print/parts/hood.scad`: `module hood()`. An upside-down-U annulus:
  - outer wall ID `hood_id`, wall `hood_wall`, from z 0 to `hood_top_z`
  - top thickness `hood_top_t`
  - inner wall from the well ID `well_id` outward 1.6, down to z 0
  - well floor `floor_t` with `collar_hole_d`
  - key tabs (2×2×1 below z 0 at `key_tab_angles`)
  - optional M2 bosses
  - optional opaque `halo_block` sleeve as a separate part
- Modify: `print/talon-housing.scad`: `part="hood"` (printed top-down: flip so the top annulus is on the bed).

**Interfaces:** Produces `face_center(r)`, `hood()`, `hood_od = hood_id + 2*hood_wall`.

- [ ] **Step 1:** Add `run.sh` case `hood-bbox`. Render `part="hood"`, then `stl_bbox.py`. Expect x = y = 55.2 ± 0.1 and z = `hood_top_z` + 1 (the tabs) ± 0.1. The expected z comes from an echo of `hood_top_z` in the render output.
- [ ] **Step 2:** Run it. Expect FAIL (unknown part).
- [ ] **Step 3:** Implement `face.scad` and `hood.scad`.
- [ ] **Step 4:** Run. Expect PASS, plus `checks-*` still passing.
- [ ] **Step 5:** Commit.

### Task 3: Cap and nut driver

**Files:**
- Create: `print/parts/cap.scad`: `module cap()`.
  - Disc Ø`cap_d` from `cap_under_z` to `cap_top_z`, with a small edge chamfer and a knurl option.
  - Stem OD `stem_od` from `nut_top_z + 1` up to `cap_under_z`.
  - Bore: a D profile (Ø`shaft_d`+`fit`, flat at `shaft_flat`+`fit`) over the shaft's D section. A round `shaft_d+0.6` clearance below it. The bore is blind at the top.
  - Printed top-face down.
- Create: `print/parts/tools.scad`: `module nut_driver()`. A hex socket `nut_af+fit` across flats, 3 deep. OD ≤ `well_id - 1`. Shaft long enough to reach `nut_top_z` from 15 above the hood top. Knurled handle Ø20 × 20. A Ø`collar_d+0.6` through-bore, so it slides over the collar and shaft.
- Modify: the entry part switch: `"cap"`, `"nut_driver"`.

**Interfaces:** Produces `cap()`, `nut_driver()`.

- [ ] **Step 1:** Add `run.sh` cases:
  - `cap-bbox`: x = y = `cap_d` ± 0.1, z = `cap_top_z - (nut_top_z+1)` ± 0.1
  - `driver-bbox`: max x/y ≤ 20.1
- [ ] **Step 2:** Run. Expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expect PASS.
- [ ] **Step 5:** Commit.

### Task 4: Test coupons, then **Evan's print checkpoint**

**Files:**
- Modify: `print/parts/tools.scad`:
  - `module fit_coupon()`: `face_center(r = hood_od/2 + 4)` plus a 40° hood-seat arc segment with one key tab; also a cap-bore plug (the cap's bore inside a Ø12 × `shaft_d_h + 2` cylinder).
  - `module glow_coupon()`: a 60 × 14 strip of hood-top thickness, on legs giving gaps of 5 / 8 / 10 / 12 in four 15 mm steps, each labeled with embossed digits.
- Modify: the entry switch: `"fit_test"`, `"glow_test"`.
- Create: `print/README.md`:
  - how to render each part (`run.sh` plus one-line `openscad -D 'part="x"' -o` commands)
  - the material per part
  - print orientation
  - the checkpoint instructions below

- [ ] **Step 1:** Add `run.sh` cases `fit-renders` and `glow-renders` (exit 0, STL > 1 KB).
- [ ] **Step 2:** Run. Expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expect PASS.
- [ ] **Step 5:** Export `print/stl/fit_test.stl`, `glow_test.stl` and `nut_driver.stl`. Commit them with the source.
- [ ] **Step 6: CHECKPOINT (Evan, physical).** Print the fit coupon (opaque) and glow coupon (translucent PETG). Check:
  - (a) the collar passes the face and floor
  - (b) the nut + washer clamp the coupon stack with thread to spare
  - (c) twist and wiggle the hood segment: does the key hold?
  - (d) the bore plug slides onto the shaft's D without slop or forcing
  - (e) once the ring is lit, pick the glow gap that hides the dots

  Record the results in `docs/housing-measurements.md` and update params. Tasks 5–6 can proceed in parallel, but the final STLs wait for this.

### Task 5: Shell

**Files:**
- Create: `print/parts/shell.scad`: `module shell()`. The wedge, open at the bottom:
  - the sloped face (`face_len` along the slope, at `slope`), carrying `face_center` geometry at the shaft position (the face's center)
  - a flat-topped rear section
  - walls `wall`
  - fillets of 3
  - **C3-Zero cradle** on the inside of the back wall: board slot `c3 + fit`, USB port flush with the wall's outer face, a **front stop** across the board's inner short edge, two snap lips
  - USB plug hole `usb_plug_hole`, rounded r = 1.5, centered on the port
  - 4 corner bosses Ø8 with M3 clearance holes and hex-nut traps (5.7 across flats + `fit`, 2.6 deep) opening downward
  - a cable channel from the face slot to the cradle

  Front height and rear depth are the minimum that clears the KY-040 stack and the C3-Zero by `clr`. Both are computed as derived values and echoed.
- Modify: the entry switch: `"shell"`.

**Interfaces:**
- Consumes: `face_center(r)`.
- Produces: `shell()`, plus `box_footprint=[w,d]`, `boss_xy` (4 points), `c3_pose` (translate/rotate placing the C3-Zero board origin), `ky_pose`, `face_pose` (face frame → box frame).

- [ ] **Step 1:** Add `run.sh` case `shell-bbox`. The width echoed from `box_footprint` matches the STL ± 0.1. The width is ≥ `hood_od + 2*wall + 4`.
- [ ] **Step 2:** Add case `c3-stop`. The render echoes `c3_stop_gap`, the distance between the board's inner edge and the stop. Expect it ≤ 0.3 (Review Focus 3).
- [ ] **Step 3:** Run. Expect FAIL.
- [ ] **Step 4:** Implement.
- [ ] **Step 5:** Run. Expect PASS.
- [ ] **Step 6:** Commit.

### Task 6: Bottom plate, feet, assembly, interference, exports

**Files:**
- Create: `print/parts/bottom.scad`:
  - `module bottom()`: a plate the shell's footprint inset by `fit`, 3 thick plus pocket depth. Counterbored M3 holes at `boss_xy`. `weight_count` pockets of `weight` size on the inside face, front-biased. 4 feet recesses Ø12 × 1 on the outside.
  - `module foot()`: Ø12 × 3 TPU disc (fits a 1-deep recess).
- Create: `print/parts/assembly.scad`:
  - `module assembly()`: every part placed, plus ghost models of the ring, KY-040 (PCB, body, collar, shaft), C3-Zero, nut and washer, using `face_pose`, `ky_pose` and `c3_pose`.
  - `module interference()`: the union of `intersection()`s over every pair of solid parts and ghosts that must not touch.
- Modify: the entry switch: `"bottom"`, `"foot"`, `"assembly"`, `"interference"`.

- [ ] **Step 1:** Add `run.sh` cases:
  - `interference-empty`: the render of `part="interference"` reports an empty top-level object, matching "top level object is empty" in the output
  - `all-parts-render`: shell, hood, cap, bottom, foot, nut_driver, fit_test, glow_test all exit 0
- [ ] **Step 2:** Run. Expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expect PASS. Then sanity-test the interference case: run with `-D clr=-2` and expect it to go non-empty.
- [ ] **Step 5:** Export every part to `print/stl/<part>.stl` with a `run.sh export` subcommand. Commit.
- [ ] **Step 6:** Update the parent spec `docs/superpowers/specs/2026-11-12-talon-controller-design.md`:
  - wiring table → C3-Zero: ring DIN GPIO0; KY CLK/DT/SW GPIO3/4/5; shared GND; avoid GPIO2/8/9/10/18/19
  - Housing section → a pointer to the housing spec

  Update `CLAUDE.md` status. Commit and push.
