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
| `stl/`                 | Ready-to-slice STLs, one per part (binary STL)       |
| `tests/run.sh`         | Renders everything and checks the results            |

## How to render

Run the full test pass (renders every part, prints PASS/FAIL per check):

    bash print/tests/run.sh

Render one part to an STL:

    /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD --backend=manifold -D 'part="fit_test"' -o out.stl print/talon-housing.scad

Swap `fit_test` for any part name below. Add more `-D` options to try a
change without editing the file, e.g. `-D glow_gap=9`.

Re-export every STL in `stl/` after changing a number:

    bash print/tests/run.sh export

Two more `part=` values are for checking, not printing: `assembly` shows
every part in place with stand-ins for the bought parts (ring, knob board,
C3-Zero, nut, washer, screws, weights), and `interference` shows any
place two of them overlap. `interference` must come out empty; the test
run checks that.

## Parts, material, and how each lies on the bed

The STLs already come out in the orientation listed. Import into Bambu
Studio and do not rotate them. None of these should need supports.

| Part (`part=`) | Material           | Qty | Orientation on the bed                 | Supports |
|----------------|--------------------|-----|----------------------------------------|----------|
| `fit_test`     | opaque PLA or PETG | 1   | five pieces side by side, see below    | none     |
| `glow_test`    | translucent PETG   | 1   | standing on its legs, steps up         | none     |
| `nut_driver`   | opaque PLA or PETG | 1   | handle down, socket up                 | none     |
| `shell`        | opaque PLA or PETG | 1   | on its back wall, open bottom sideways | none     |
| `hood`         | translucent PETG   | 1   | upside down: top face on the bed       | none     |
| `cap`          | opaque PLA or PETG | 1   | upside down: top face on the bed       | none     |
| `bottom`       | opaque PLA or PETG | 1   | outside face down, pockets up          | none     |
| `foot`         | TPU                | 4   | flat                                   | none     |
| `halo`         | opaque PLA or PETG | 1   | either end down (only with `halo_block=true`) | none |

"None" means the part was shaped to print without supports: the shell's
inside front is a 45 degree ramp and its front screw posts are teardrops;
the bottom plate's screw counterbores are short bridges. Still glance at
Bambu Studio's overhang preview before printing the shell.

The hood is the only part the light shines through, so it is the only big
part in translucent PETG. Everything else is opaque so light does not leak.

The USB-C unplug pull is taken by the back wall's slot at the board's corners, so unplug by the plug body, not the cable.

## Bought parts for the box

- **4x M3 x 10 socket-head screws** (from the M3 kit) and **4x M3 hex nuts**.
  The screws come up through the bottom plate into nuts held in the shell's
  corner posts. The counterbores are sized for 10 mm: a 12 mm screw will not
  fit (the model refuses it), and an 8 mm one needs `m3_screw_l = 8` and a
  re-export.
- **4x weights**, 19.65 x 22 x 5.8 mm with their sticky backing. The pockets
  are exactly that size, no extra room.

## Assembly order

1. **Solder** header pins on the C3-Zero (only the holes in use) and the
   ring's wires. Wire map: `docs/superpowers/specs/2026-11-12-talon-controller-design.md`,
   "Hardware wiring".
2. **Ring.** Feed the ring's wires down the slot in the face and lay the
   ring flat on the face. It goes first: the hood covers it, and the nut in
   step 3 clamps the hood down.
3. **Hood and knob board.** Set the hood over the ring, its tabs in the
   lip's notches. From inside the shell, push the encoder's threaded collar
   up through the face and the hood's well floor; the little pin on the
   face's underside drops into the board's far mounting hole. Add the metal
   washer and the nut inside the well and snug it with the nut driver. Do
   not crank it.
4. **C3-Zero.** Tilt the board, slide its USB end into the slot in the back
   wall, and press the other end down past the two snap lips.
5. **Wires.** Run the ring wires along the channel under the face and top
   and down the back wall; plug the jumpers onto the C3-Zero.
6. **Push the cap** onto the shaft (flat side matches).
7. **Bottom plate.** Stick the weights in their pockets. Slide an M3 nut
   into each corner post's side slot until it clicks past the bumps. Set the
   plate on, then drive the four screws up from below. Snug, not tight.
8. **Feet.** Glue a TPU foot into each round recess on the underside.

## Test coupons (print these first)

Two small, cheap prints that test the fits that are hard to get right on
paper, before you spend hours on the full housing.

**Fit coupon** (`stl/fit_test.stl`, opaque), five pieces in a row. The real
face is split in two here so each half prints flat with no supports:

1. **Lip ring**: the outer part of the face, with the raised seat lip and
   the key notches the hood locks into.
2. **Face disc**: the centre of the face the knob comes through. It prints
   upside down (the top face on the bed), so the little anti-rotation pin
   points up. Flip it over to use it: the pin goes down into the knob
   board's mounting hole.
3. **Floor washer**: a flat ring the same thickness as the hood's well
   floor. In the real build, the hood floor sits on the face and the nut
   clamps both. This washer stands in for it.
4. **Bore plug**: a short cylinder with the knob cap's D-shaped hole in it,
   open side up.
5. **Hood segment**: a 40-degree slice of the hood wall with one key tab,
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
the lip ring's lip. Twist and wiggle it.
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

**(f) The pin drops into the knob board's hole.** With the face disc on
the collar (pin side down), the pin drops into the far mounting hole of the
KY-040 board (the hole farther from the knob) and the disc sits flat.
- Pin misses the hole: adjust `ky_hole_x_from_header` (now 4.5 and 21.5;
  your caliper read 4.5 to 4.8 for the far hole, so try 4.7 first).

Once a-f pass, re-run `bash print/tests/run.sh` and print the real parts.
