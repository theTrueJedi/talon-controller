# Housing: plate lip, C3 fixes, port, PDF guide — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the 2026-11-18 amendment (plate lip, two-tooth clip, board 0.4 mm inward, plug-sized notch with a plate filler), re-export STLs, then produce a printable PDF print-and-assembly guide with line diagrams.

**Architecture:** Parametric OpenSCAD in `print/` (params → checks → parts). Every change is a parameter plus geometry plus a `print/tests/run.sh` case. The guide is HTML with SVG/PNG figures generated from the model, printed to PDF by headless Chrome.

**Tech Stack:** OpenSCAD (manifold backend), bash test harness, Python 3 + PIL, headless Google Chrome `--print-to-pdf`.

**Spec:** `docs/superpowers/specs/2026-11-16-talon-housing-design.md`, section "Amendment 2026-11-18".

## Global Constraints

- `lip_fit = 0.1` per side; lip 1.2 thick (`lip_t`), 2 tall (`lip_h`), 45° lead-in chamfer (`lip_chamfer = 0.6`) on its outer top edge.
- `c3_slot_clr = 0.4`: the board edge sits `c3_wall_slot - c3_slot_clr` = 0.6 mm in the 1 mm slot.
- `usb_plug = [12.12, 6.6]` (Evan's larger cable) is recorded; `usb_plug_hole` stays [12.5, 7.5] so the printed `shell_v6` is unchanged. Assert the plug fits the hole.
- **The shell must not change:** `run.sh export` must report SAME for shell.
- Clip: two teeth, antenna `c3_ant_w = 6.4` (measured ~6), `c3_ant_clr = 0.5`, tooth width `c3_tooth_w = 2`; replaces `c3_clip_w`.
- New STLs as `part_vN.stl` via `bash print/tests/run.sh export`; never `git add print` wholesale (add the new STLs by name).
- Commits: simple `-m`, push after every commit.

## Review Focus

1. Lip vs the shell's front 45° ramp: the front lip must sit behind the ramp foot, not inside the wall — interference check covers it (Task 3).
2. Lip vs corner bosses and the back-wall C3 cuts (slot, notch, header recess) — interference + clearance asserts (Task 3).
3. Filler vs the solder-tail grooves and notch sides — assert filler half-width ≤ groove-free middle and ≤ notch half-width − `c3_fit` (Task 3).
4. Teeth vs antenna and corner holes — asserts, with a failing-param test each (Task 2).
5. Moving the board inward changes `c3_reach`/`rear_d`: the base-extra and c3-stop tests must still pass (Task 1).

---

### Task 1: Board 0.4 mm inward; plug recorded (shell unchanged)

**Files:** `print/lib/params.scad`, `print/lib/checks.scad`, `print/parts/shell.scad` (`c3_cuts`, `c3_board_cuts`), `print/tests/run.sh`

**Produces:** `c3_slot_clr`, `usb_plug`; `c3_edge_y = box_d - wall + c3_wall_slot - c3_slot_clr`.

- [ ] Test: `expect_fail checks-fail-slot-clr "C3 slot clearance" -D c3_slot_clr=1` (engagement must stay ≥ 0.4), `expect_fail checks-fail-plug "USB plug wider than its hole" -D 'usb_plug=[13, 6.6]'`, and a check that the shell echo `c3_slot_clr = 0.4` renders.
- [ ] Run → fails (param unknown / assert missing).
- [ ] Implement: params as above; `c3_reach` adds `c3_slot_clr`; slot and recess depth = `c3_wall_slot + eps` measured from the inner face (not from `c3_edge_y`); assert `c3_wall_slot - c3_slot_clr >= 0.4` ("C3 slot clearance leaves too little engagement"); stop-gap assert compares against the engagement, not `c3_wall_slot`. Update `[0, 7]` interference comment (board no longer touches the slot end).
- [ ] `bash print/tests/run.sh` → all PASS.
- [ ] Commit "Housing: C3 0.4 mm inward (c3_slot_clr); Evan's plug recorded".

### Task 2: Two-tooth clip

**Files:** `print/lib/params.scad`, `print/lib/checks.scad`, `print/parts/shell.scad` (`c3_clip`), `print/tests/run.sh`

**Produces:** `c3_ant_w`, `c3_ant_clr`, `c3_tooth_w`; `c3_tooth_x0 = c3_ant_w / 2 + c3_ant_clr` (inner edge of each tooth); `c3_clip_w` removed.

- [ ] Tests: `expect_fail checks-fail-antenna "C3 clip tooth over the antenna" -D c3_ant_clr=-1`; existing `checks-fail-corner` still fails with `-D c3_hole_end=0.1`; add `checks-fail-tooth-corner` with `-D c3_tooth_w=3.5`; `c3-clip-layout` still one body.
- [ ] Run → fail.
- [ ] Implement: two tongue cubes at x ∈ ±[c3_tooth_x0, c3_tooth_x0 + c3_tooth_w]; corner-hole check iterates both tooth rects; groove-middle assert uses the outer tooth edge; antenna assert `c3_tooth_x0 >= c3_ant_w / 2 + 0.1`-style (fails if a tooth overlaps `±c3_ant_w/2`).
- [ ] Tests PASS. Commit "Housing: C3 clip with two teeth beside the antenna".

### Task 3: Plate lip and port filler

**Files:** `print/lib/params.scad`, `print/lib/checks.scad`, `print/parts/bottom.scad`, `print/talon-housing.scad` (a `bottom_probe` part), `print/tests/run.sh`

**Consumes:** Task 1's `c3_edge_y`, `usb_plug_hole`.
**Produces:** `module plate_lip()`, `module port_filler()` (both called from `bottom()`); `lip_fit`, `lip_t`, `lip_h`, `lip_chamfer`.

Geometry (box frame, plate top z = 0):
- Side lips: outer face at x = ±(box_w/2 − wall − lip_fit), y from the front ramp foot (`wall + shell_z1`) to the rear boss minus `boss_d/2 + clr`.
- Front lip: across between the side lips, its outer face following the ramp offset `lip_fit` (a 45° face, so the whole face seats).
- Back lip: outer face at y = box_d − wall − lip_fit, x from the rear-left boss + `boss_d/2 + clr` to `c3_hdr_recess_x[0] − clr`.
- Profile: `lip_t` × `lip_h`, outer top edge chamfered `lip_chamfer` at 45°.
- Filler: x = c3_x ± (c3[1]/2 − c3_groove[0]), y from `c3_cradle_y1 − eps` to `box_d − c3_fit`, z 0..`c3_z0`.

- [ ] Tests: `expect_solid bottom-probe-lip` (probe strip just inside the left wall at mid-depth, z 0.5..1.5), `expect_solid bottom-probe-filler` (inside the notch below the board); interference default still empty; `interference-detects-lip_fit` with `-D lip_fit=-0.3` caught; `expect_fail checks-fail-filler "port filler" -D 'usb_plug_hole=[12, 7.5]'`; `bottom-layout` still 5 bodies, same bbox.
- [ ] Run → fail.
- [ ] Implement, plus asserts: `lip_fit > 0`; `lip_h < boss_floor + eps` not needed (lips stop short of bosses) — instead assert lip top ≤ `ky_low_z − clr`; filler half-width ≤ `usb_plug_hole[0]/2 − c3_fit` ("port filler rubs the notch sides").
- [ ] Tests PASS. Commit "Housing: plate lip (lip_fit 0.1) and port filler under the C3".

### Task 4: Export and docs

**Files:** `print/stl/*_vN.stl` (new only), `print/README.md`, `CLAUDE.md` (Status)

- [ ] `bash print/tests/run.sh` all PASS, then `bash print/tests/run.sh export` → NEW for bottom and c3_clip only; SAME for shell.
- [ ] README: new checkpoint for the lip fit (`lip_fit`), clip teeth, filler; checkpoint (g) marked measured; part versions.
- [ ] `git add` the new STLs by name + docs; commit "Export bottom/shell/c3_clip; README checkpoints"; push.

### Task 5: PDF print-and-assembly guide

**Files:** `print/guide/` (`build.sh`, `figures.scad` or `-D` view params, `guide.html`, generated `talon-housing-guide.pdf`)

- [ ] Figures from the model: plan/side outlines via OpenSCAD `projection()` → SVG (true line art: plate with lip and cradle, clip with teeth, back wall with notch); exploded isometric assembly → PNG, converted to line art with PIL (edge filter, threshold, white background).
- [ ] `guide.html`: parts list and bought parts; per-part print settings and bed orientation (from README); the weight pause (height from the `weight_pause_z` echo); painted support on the shell's front rim; wiring summary; assembly steps in README order with a figure each; fit checkpoints and what to change.
- [ ] `build.sh` renders figures, then `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --print-to-pdf=... guide.html`. Verify: PDF exists, page count > 1, read pages back to check figures render.
- [ ] Commit the source and the PDF; push; `open` the PDF for Evan.
