# Talon controller housing (print files)

Everything here is generated from one OpenSCAD model. Change a number in
`lib/params.scad`, re-render, and every part follows. The model refuses to
render (and says why) if a change would make parts collide or stop fitting.

## Files

| Path                   | What it is                                           |
|------------------------|------------------------------------------------------|
| `talon-housing.scad`   | Entry point; pick a part with `part="..."`           |
| `lib/params.scad`      | Every dimension, with a comment saying what it is    |
| `lib/checks.scad`      | Fit and collision checks that stop a bad render      |
| `parts/*.scad`         | The parts themselves                                 |
| `stl/`                 | Ready-to-slice STLs (test coupons and nut driver)    |
| `tests/run.sh`         | Renders everything and checks the results            |

## How to render

Run the full test pass (renders every part, prints PASS/FAIL per check):

    bash print/tests/run.sh

Render one part to an STL:

    /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD --backend=manifold -D 'part="fit_test"' -o out.stl print/talon-housing.scad

Swap `fit_test` for any part name below. Add more `-D` options to try a
change without editing the file, e.g. `-D glow_gap=9`.

## Parts, material, and how each lies on the bed

The STLs already come out in the orientation listed. Import into Bambu
Studio and do not rotate them. None of these should need supports.

| Part (`part=`) | Material                 | Orientation on the bed                        |
|----------------|--------------------------|-----------------------------------------------|
| `fit_test`     | opaque PLA or PETG       | four pieces side by side, see below           |
| `glow_test`    | translucent PETG         | standing on its legs, steps up                |
| `nut_driver`   | opaque PLA or PETG       | handle down, socket up                        |
| `hood`         | translucent PETG         | upside down: top face on the bed              |
| `cap`          | opaque PLA or PETG       | upside down: top face on the bed              |
| `halo`         | opaque PLA or PETG       | either end down (only with `halo_block=true`) |
| shell, bottom  | opaque PLA or PETG       | (later task)                                  |
| feet           | TPU                      | (later task)                                  |

The hood is the only part the light shines through, so it is the only big
part in translucent PETG. Everything else is opaque so light does not leak.

## Test coupons (print these first)

Two small, cheap prints that test the fits that are hard to get right on
paper, before you spend hours on the full housing.

**Fit coupon** (`stl/fit_test.stl`, opaque), four pieces in a row:

1. **Face disc**: the round face plate the knob comes through, with the
   seat lip and key notches for the hood. The little anti-rotation pin under
   the real face is left off so the disc can lie flat.
2. **Floor washer**: a flat ring the same thickness as the hood's well
   floor. In the real build, the hood floor sits on the face and the nut
   clamps both. This washer stands in for it.
3. **Bore plug**: a short cylinder with the knob cap's D-shaped hole in it,
   open side up.
4. **Hood segment**: a 40-degree slice of the hood wall with one key tab,
   printed upside down like the real hood.

**Glow coupon** (`stl/glow_test.stl`, translucent PETG): a strip in four
steps. Each step sits 5, 8, 10 or 12 mm above the ring's LEDs (the number
is on the side). Its legs straddle the ring and stand on the desk, so set
the ring flat on the desk and put the strip over it.

## CHECKPOINT: what to check, and what to change if it fails

Write what you find in `docs/housing-measurements.md`. Then change the
listed number in `lib/params.scad`.

**(a) The encoder's threaded collar goes through the face disc and the floor
washer.** Push the encoder up from underside through the disc, then the
washer on top.
- Too tight: raise `collar_hole_d` (now 7.4) by 0.2 at a time.
- Very loose: lower it by 0.2.

**(b) Nut + washer clamp the stack with thread to spare.** Stack: face disc,
floor washer, the metal washer, the nut. The nut must catch the thread fully
and have a little thread showing above it.
- Nut barely catches, or not at all: lower `face_t` or `floor_t` (both 1.5
  now; do not go under 1.2). The model refuses below 1 mm of spare thread.
- Snug the nut until the stack stops moving. Do not crank it: the plastic
  will crush and crack. A drop of **blue (removable)** threadlocker is
  optional if it works loose. Never red; red is permanent.

**(c) The hood key holds.** Drop the hood segment's tab into a notch in
the face disc's lip. Twist and wiggle it.
- Tab will not go in: raise `fit` (now 0.2) to 0.3. This widens the notch
  and gap around the hood wall.
- Sloppy, twists noticeably: lower `fit` to 0.1, or raise `key_tab_w`
  (now 2).
- Snapped off easily: raise `key_tab_w` to 3.

**(d) The bore plug slides onto the knob shaft's flat (D) end without slop
or forcing.**
- Will not go on, or needs force: raise `fit` by 0.1, or raise
  `shaft_flat` by 0.1 if only the flat side binds.
- Wobbles or turns on the shaft: lower `fit` by 0.1. Note `fit` also sets
  the hood fits in (c); change them together, and re-check (c) if you move it.

**(e) Pick the glow gap that hides the LED dots.** Light the ring, lay the
glow strip over it, and look straight down at each step. Pick the lowest
step where you see one even glow instead of separate dots.
- Set `glow_gap` to that number (now 8).
- The cap above limits how tall the hood can be. Right now the maximum is
  9.4. If you pick 10 or 12, the render will stop with "glow_gap too large".
  Tell Claude, and we will raise the knob cap (`cap_over_shaft`) or slim
  the cap float to make room.

Once a-e pass, re-run `bash print/tests/run.sh` and print the real parts.
