# Housing: C3 on the plate, taller base, heavy knurled knob — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the ESP32-C3-Zero cradle from the shell onto the bottom plate (board off-centre, header plugs pointing sideways), raise the box 5 mm, and replace the knob with a 29 mm solid diamond-knurled cap with a 14 mm disc.

**Architecture:** Parametric OpenSCAD in `print/`. Every dimension lives in `print/lib/params.scad`; `print/lib/checks.scad` asserts; parts in `print/parts/*.scad`; `print/talon-housing.scad` picks a part. Tests are `bash print/tests/run.sh` (PASS/FAIL lines, exits non-zero on first FAIL). Bought parts are ghosts in `print/parts/assembly.scad`; `part="interference"` must render empty.

**Tech Stack:** OpenSCAD (manifold backend), bash, Python 3 (stdlib only).

**Spec:** `docs/superpowers/specs/2026-11-16-talon-housing-design.md`, section "Amendment 2026-11-17 (first test prints)".

## Global Constraints

- Box frame: x = 0 on the shaft axis, +X right; y = 0 front outer face, +Y back; z = 0 shell rim = plate top. Face frame is in `face_pose()`.
- Every part prints with no supports, in the orientation its `part=` branch emits.
- Export only with `bash print/tests/run.sh export` (writes `print/stl/<part>_vN.stl`, bumps N only on a shape change, keeps old files). Never `git add print` wholesale: `print/stl/*.3mf` are Evan's and untracked. Stage explicit paths.
- Commits: `git commit -m "..."` (no heredoc), then `git push origin main`. End each message with the two attribution `-m` lines used in this repo's recent commits.
- C3-Zero wired row, from the USB end (measured): 5V, GND, 3V3, GPIO0, 1, 2, 3, 4, 5. Seen from above with the port toward +Y, this row is the board's **-X** long edge.
- New values from the spec: `base_extra = 5`; `cap_d = 29`; `cap_disc_t = 14`; knob solid, no weight insert.

## Review Focus

1. **Plate removal path:** with the C3 on the plate, the board, its port and the header plugs must slide straight down out of the shell. Every back-wall cut they pass through must be open to z = 0. Task 2 and Task 3 each assert this.
2. **Header plugs vs the clip, rails and back wall:** the 5V plug overhangs the board's port end by ~0.67 mm into the wall. The pin-5 plug sits ~0.35 mm from the clip legs. Task 3's interference test covers this.
3. **Weight pockets after the shift:** four pockets must not overlap each other, the cradle, or a counterbore. Task 2 adds the pocket-pocket check.
4. **Glow gap no longer capped by the cap:** with a fixed disc thickness, the cap top rides on the hood. `glow_gap=12` must render, and the cap's bore must still reach the shaft. Task 4 asserts this.
5. **Shell print without the cradle:** the shell keeps no C3 parts. A stale `c3_cradle()` call in `shell()` would leave floating rails. Task 2 checks that the shell has one body and that the cradle volume is gone.

---

### Task 1: Taller base (`base_extra`)

**Files:** Modify `print/lib/params.scad` (front_h), `print/talon-housing.scad` (shell echo), `print/tests/run.sh`, `print/README.md` (nothing else mentions it).

**Interfaces:** Produces `base_extra` (mm). `front_h = max(front_h_ky, front_h_boss) + base_extra`.

- [ ] **Step 1: Failing test.** In `run.sh`, after `shell-render`, add `base-extra`. Render the shell twice, with `-D base_extra=0` and the default. Parse `box_h` from the echo `ECHO: box_h = ...`. Assert the default is exactly 5.0 (±0.01) taller.
- [ ] **Step 2:** Run `bash print/tests/run.sh`. Expected: FAIL base-extra (unknown variable / no difference).
- [ ] **Step 3:** Add `base_extra = 5;  // added height on the straight lower walls (Evan, 2026-11-17)` near `top_flat_min`, and add it into `front_h`. `box_d` must not change: `rear_d` stays `top_flat_min`-bound. Confirm via the shell echo.
- [ ] **Step 4:** Run the suite. Expected: all PASS, including `interference-empty`.
- [ ] **Step 5:** Commit `params.scad`, `run.sh`: "Housing: base_extra 5 mm (taller lower walls)".

### Task 2: C3 cradle on the bottom plate, off-centre; weight pockets re-laid

**Files:** Modify:
- `print/lib/params.scad`: `c3_x`, the weight layout, the C3 comment block
- `print/parts/shell.scad`: move `c3_cradle`, `c3_clip`, the cradle part of `c3_cuts`; rework the back-wall cuts
- `print/parts/bottom.scad`: union the cradle, pockets from the list
- `print/lib/checks.scad`
- `print/parts/assembly.scad`: `c3_pose`, contacts
- `print/talon-housing.scad`: bottom/c3_clip echoes
- `print/tests/run.sh`

**Interfaces:**
- Produces `c3_x = 11.5`, the board's centre x in the box frame. The cradle, clip, wall slot, port notch and `c3_pose()` all shift by it.
- Produces `weight_pockets`, a list of `[x0, y0, rot]` (rot 0: `weight[0]` along X; rot 90: swapped).
- Produces `function weight_rect(i)` returning `[[x0, y0], [x1, y1]]`. Every user of `weight_xy`/`weight_row_x` switches to it (bottom pockets, `weights_ghost`, checks), and `weight_xy`/`weight_row_x` are deleted.
- `c3_cradle()` and `c3_clip()` keep their names. They are now called from `bottom()` (cradle) and placed at `c3_x`.

- [ ] **Step 1: Failing tests** in `run.sh`:
  - `shell-no-cradle`: the shell renders with `-D c3_x=0` and default. Assert both STLs have 1 body (`stl_check` counts bodies).
  - `bottom-layout` update: bbox z = `plate_t + c3_top_h`, from a new echo `bottom_footprint = [w, d, plate_t + c3_top_h]`.
  - `c3-notch-open`: a new echo `c3_back_cuts_z0 = <min z of the wall slot and port cut>`; assert it is ≤ 0.
  - `expect_fail checks-fail-pocket-overlap "weight pockets overlap" -D 'weight_pockets=[[-20.65,3,0],[-20.65,3,0],[1,3,0],[-22.8,27,90]]'`.
  - `expect_fail checks-fail-c3-boss "C3 cradle hits a rear boss" -D c3_x=16`.
- [ ] **Step 2:** Run the suite. Expected: FAIL at the first new test.
- [ ] **Step 3: Implement.**
  - `c3_x = 11.5; // board centre x: off-centre so the header plugs point toward -X (box middle)`.
  - Move `c3_cradle()` out of `shell()` into `bottom()`'s union, translated by `[c3_x, 0, 0]`. The cradle already spans z 0..`c3_top_h`, which is the plate top. Move the solder-tail grooves and clip notches with it (they cut the cradle, so they are subtracted inside the cradle module, not from the plate pockets).
  - `c3_pose()` and the `c3_clip` assembly item shift by `c3_x`. The `c3_clip` *part* export subtracts `c3_x`, so `c3_clip_v1.stl` comes out SAME.
  - Back wall (still in `shell.scad` `c3_cuts`, shifted by `c3_x`):
    - The board-edge slot runs from z = -eps up to `c3_z0 + c3[2] + c3_fit`.
    - The USB plug hole becomes a notch: the same width and rounded top corners, open down to z = -eps.
  - Weight pockets: `weight_pockets = [[-20.65, 3, 0], [1, 3, 0], [-22.8, 27, 90], [-22.8, 48.65, 90]];` with the comment "front pair as before; the other two in a column on the -X side, clear of the C3 cradle". These values were checked by hand against the cradle (gap ≥ clr), the rear-left counterbore (5.1 ≥ 5.05) and the plate edge.
  - `checks.scad`:
    - `c3_cradle_rect` shifts by `c3_x`.
    - Add a pocket-pocket check: `rects_gap ≥ weight_gap`, message "weight pockets overlap".
    - Add a cradle-to-rear-boss check: plan gap from the cradle rect (rails at `c3_x ± c3_cradle_hw`) to each rear `boss_xy` ≥ `boss_d / 2 + clr`, message "C3 cradle hits a rear boss".
  - `assembly.scad` contacts: replace `[0, 7, ...]` with `[1, 7, [0, 0, eps]]` (board on the plate's pedestal) and `[0, 7, [0, -eps, 0]]` (port edge at the wall-slot end). Replace `[0, 12, ...]` with `[1, 12, [0, eps, eps]]`. Update the item comment "shell rim, bosses, cradle on the plate top".
  - Update the C3 comment block in `params.scad` and `shell.scad`: cradle on the plate, fitted before the plate goes on, slides up through the open back-wall notches.
- [ ] **Step 4:** Run the suite. Expected: all PASS, including `interference-empty` and the 4 `interference-detects-*`. The `c3_clip_leg_x=10` detect must still be caught. The legs move inside the rails whatever `c3_x` is. If it isn't caught, the clip is not shifted with the cradle.
- [ ] **Step 5:** Commit: "Housing: C3 cradle and clip on the bottom plate, off-centre (c3_x 11.5); back-wall slot and USB notch open at the rim; weight pockets as a list".

### Task 3: Header and plug stand-ins (C3 + KY-040), back-wall plug recess

**Files:** Modify `print/lib/params.scad`, `print/parts/assembly.scad`, `print/parts/shell.scad` (`c3_cuts`), `print/lib/checks.scad`, `print/tests/run.sh`.

**Interfaces:**
- Consumes `c3_x`, `c3_pose()`, `ky_pose()` from Task 2 and the existing code.
- Produces these params, typical values until Evan measures (spec, "Open"):

  ```
  hdr_pitch = 2.54;
  hdr_body_h = 2.5;    // plastic height on the board
  hdr_leg_z = 2.5;     // right-angle leg height above the board top
  hdr_leg_out = 6;     // leg past the plastic
  plug = [2.54, 2.54, 14];   // F jumper housing [w, h, length]
  plug_wire_room = 5;  // wire past the housing before it bends
  c3_hdr_n = 9;
  ky_hdr_n = 5;
  ```

- Produces ghost items 13 (`c3_hdr_ghost`: plastic, plus one envelope box for the mated plugs and wire room) and 14 (`ky_hdr_ghost`). `item_n = 15`.

- [ ] **Step 1: Failing tests.** Add to the `interference-detects-*` loop:
  - `plug_wire_room=40`: the C3 envelope reaches the -X side wall, and the KY envelope reaches the back.
  - `c3_x=0`: centred, the C3 envelope reaches the rear-left boss and wall.

  Both must be caught (the render is not empty).
- [ ] **Step 2:** Run. Expected: FAIL (unknown variable / not caught).
- [ ] **Step 3: Implement.**
  - **C3 ghost (box frame, via `c3_pose()`):**
    - Pin i at board-local y = `c3_hole_end + i * hdr_pitch` from the port edge, x on the -X row (`c3_hole_edge` in from that edge).
    - Plastic: `[hdr_pitch, c3_hdr_n * hdr_pitch, hdr_body_h]` centred on the row, on the board top.
    - Envelope: from the board's -X edge outward by `hdr_leg_out + plug[2] + plug_wire_room`, spanning all 9 pitches in Y, z = board top + `hdr_leg_z ± plug[1] / 2`.
  - **KY ghost (KY frame, via `ky_pose()`):** an envelope from the PCB's header edge (y = `ky_shaft_from_header_edge`) out +Y by `hdr_leg_out + plug[2] + plug_wire_room`, `ky_hdr_n * hdr_pitch` wide centred on the PCB width, z = PCB mid-plane ± `(hdr_leg_z + plug[1] / 2)`. Set `ky_wire_room = hdr_leg_out + plug[2] + plug_wire_room` so `ky_y_range` and its checks see the same envelope.
  - **Back wall:** the 5V plug overhangs the port edge into the wall by `plug[1]/2 - c3_hole_end + c3_wall_slot`. Widen the open-bottom board-edge slot in `c3_cuts` toward -X to cover the envelope's X span, up to the envelope's top z, same depth `c3_wall_slot`. Echo `c3_back_cuts_z0` must stay ≤ 0.
  - **Clip and rails:** if `interference-empty` flags the -X rail or the clip leg against the plug envelope, lower that rail's top to board top (`c3_z0 + c3[2]`) from the stop face back, and keep its notch for the barb. Otherwise leave them. Write which case happened in the commit message.
  - Contacts: `[7, 13, [0, 0, eps]]` (header plastic on the board), `[6, 14, ...]` along the header edge (choose the normal: +Y in the KY frame → `ky_pose` rotation of `[0, eps, 0]`).
- [ ] **Step 4:** Run the suite. Expected: all PASS; `interference-empty` passes with items 13 and 14 included.
- [ ] **Step 5:** Commit: "Housing: header/plug stand-ins for C3 and KY-040; back-wall plug recess open at the rim".

### Task 4: Knob — 29 mm, 14 mm disc, diamond knurl

**Files:** Modify:
- `print/lib/params.scad`: cap block, `max_glow_gap`
- `print/parts/cap.scad`
- `print/lib/checks.scad`
- `print/tests/run.sh`: cap tests, `checks-fail-glow`

**Interfaces:**
- Produces `cap_disc_t = 14`, and `cap_top_z = cap_under_z + cap_disc_t`. This replaces `cap_over_shaft`; delete it.
- Produces `module diamond_knurled(d, h)` (children: the disc). `knurled()` stays for the nut driver's handle.
- Produces params `dknurl_n = 40` (pyramids round), `dknurl_depth = 0.7`, `dknurl_angle = 45` (helix angle from vertical).
- `cap_knurl` default becomes `true` and selects the diamond knurl.

- [ ] **Step 1: Failing tests.**
  - `cap-bbox`: the expected dims come from the echo, so add a fixed assert that the echo says `cap_d = 29` and that `cap_top_z - cap_under_z` echoes 14 (new echo `cap_disc = ...`).
  - Replace `expect_fail checks-fail-glow "glow_gap too large" -D glow_gap=12` with `expect_ok glow-gap-12 -D 'part="cap"' -D glow_gap=12`.
  - Add `expect_fail checks-fail-roof "cap roof over bore too thin" -D cap_disc_t=2`.
  - `cap-knurl-render`: render `-D cap_knurl=true`, then assert the STL bbox X/Y is 29.0 ±0.1. Peaks reach `cap_d`; valleys are `dknurl_depth` in.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - `cap_d = 29`, `cap_disc_t = 14`.
  - `max_glow_gap` and its assert in `checks.scad` are removed. The cap no longer limits the hood height: the disc rides `cap_float` above the hood, and the D-bore still ends at `shaft_top_z + bore_fit`. The roof becomes `cap_top_z - cap_bore_top_z`, so the existing `cap_roof_min` assert guards it.
  - `diamond_knurled(d, h)`: the intersection of the child with two opposite-handed `linear_extrude(height = h, twist = ±tw, slices = ...)` of a `dknurl_n`-tooth star (outer radius d/2, inner d/2 - dknurl_depth), where `tw = 360 * h * tan(dknurl_angle) / (PI * d)`. Keep the existing top/bottom chamfers by intersecting with `chamfered_disc()`.
  - The cap prints as now (top face on the bed). The knurl is on the vertical side only, so it needs no supports.
- [ ] **Step 4:** Run the suite. Expected: all PASS; `interference-empty` passes (the taller cap clears everything).
- [ ] **Step 5:** Commit: "Knob: 29 mm solid cap, 14 mm disc, diamond knurl; cap no longer caps the glow gap".

### Task 5: Docs, STL export, status

**Files:** Modify `print/README.md`, `CLAUDE.md` (Status), `print/tests/run.sh` (the all-parts list at the "Bottom plate, feet..." loop lacks `frame_test`: add it). Write `print/stl/*_vN.stl` via export.

- [ ] **Step 1:** Add `frame_test` to the all-parts-render loop. Run the suite: all PASS.
- [ ] **Step 2: README.**
  - Parts table: `bottom` now carries the C3 cradle, prints outside face down, cradle up. `cap` says 100% infill.
  - Replace "## Wiring (direct solder, no headers or jumpers)" with header + F-F jumpers. Cover:
    - the 9-pin right-angle strip on the wired row, legs pointing off the board toward the box middle; bend to 90° first if they are 45°;
    - knob board: stock header + F-F jumpers, no solder;
    - ring: jumpers cut in half, cut ends soldered to the pads;
    - keep the pin table.
  - Assembly order: the C3 + clip go on the plate; plug the jumpers in; leave slack so the plate can come away; the plate goes on last.
  - Checkpoint (e): remove the "max 9.4 / glow_gap too large" text. Any step 5–12 is fine now.
  - `cap_over_shaft` references → `cap_disc_t`.
- [ ] **Step 3: CLAUDE.md Status:** today's state in 4–6 lines. Housing amended (C3 on plate, base +5, knob 29/14 knurled); next is Evan measuring the header/jumper sizes, then printing `bottom`, `shell`, `cap`.
- [ ] **Step 4:** `bash print/tests/run.sh export`. Expected:
  - NEW for shell, bottom, cap;
  - SAME for c3_clip, hood, foot, nut_driver, fit_test, frame_test, glow_test, halo.

  If `c3_clip` comes out NEW, the part export did not subtract `c3_x`: fix it.
- [ ] **Step 5:** Commit README, CLAUDE.md, run.sh and the new STL files by explicit path: "Docs + STLs: C3 on plate, header wiring, knurled knob".
