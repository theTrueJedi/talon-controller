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
| `glow_test`    | translucent PETG   | 1   | four tiles, face down, legs up         | none     |
| `nut_driver`   | opaque PLA or PETG | 1   | handle down, socket up                 | none     |
| `shell`        | opaque PLA or PETG | 1   | on its back wall, open bottom sideways | none     |
| `c3_clip`      | **PETG** (PLA may crack at the snap) | 1 | on its front face | none |
| `hood`         | translucent PETG   | 1   | upside down: top face on the bed       | none     |
| `cap`          | opaque PLA or PETG | 1   | upside down: top face on the bed       | none     |
| `bottom`       | opaque PLA or PETG | 1   | outside face down, pockets up          | none     |
| `foot`         | TPU                | 4   | flat                                   | none     |
| `halo`         | opaque PLA or PETG | 1   | either end down (only with `halo_block=true`) | none |

"None" means the part was shaped to print without supports: the shell's
inside front is a 45 degree ramp and its front screw posts are teardrops;
the square frame under the face (it holds the knob's body) is only 1 mm
deep; the bottom plate's screw counterbores are short bridges. Still glance
at Bambu Studio's overhang preview before printing the shell.

The hood is the only part the light shines through, so it is the only big
part in translucent PETG. Everything else is opaque so light does not leak.

The C3-Zero's USB-C port sits 1 mm inside the back wall on purpose: the
board's edge sits in a slot in the wall, and that slot holds the board. So
the plug's plastic body has to fit INTO the wall's hole for the plug to
seat (checkpoint g). The unplug pull is taken by that slot, so unplug by
the plug body, not the cable.

## Bought parts for the box

- **4x M3 x 10 socket-head screws** (from the M3 kit) and **4x M3 hex nuts**.
  The screws come up through the bottom plate into nuts held in the shell's
  corner posts. Their heads end up about 0.8 mm below the plate's underside
  (recessed, not flush). The counterbores are sized for 10 mm: a 12 mm
  screw will not fit (the model refuses it), and an 8 mm one needs
  `m3_screw_l = 8` and a re-export.
- **4x weights**, 19.65 x 22 x 5.8 mm with their sticky backing. The pockets
  are exactly that size, no extra room. The front pair sits partly under
  the shell's inside front ramp; the ramp resting on them is intended.
- **Thin double-sided tape** (or a hot-glue gun) for the ring.

## Wiring (direct solder, no headers or jumpers)

Every wire is soldered straight into its hole: no header pins on the
C3-Zero, no jumper wires.

- **KY-040 knob board:** clip its right-angle pins to short stubs and
  solder a wire to each stub.
- **Ring:** solder three wires to the ring's pads (5V, GND, DIN).
- **C3-Zero:** solder the wire ends straight into the board's holes. All of
  them go on one pin row (5V, GND, 3V3, GPIO0 to GPIO5):

| Wire           | C3-Zero hole |
|----------------|--------------|
| Ring DIN       | GPIO0        |
| Ring 5V        | 5V           |
| Ring GND       | GND          |
| KY-040 GND     | GND (the same hole: twist it with the ring GND first) |
| KY-040 +       | 3V3          |
| KY-040 CLK     | GPIO3        |
| KY-040 DT      | GPIO4        |
| KY-040 SW      | GPIO5        |

Optional: a 330 Ω resistor soldered inline in the ring's DIN wire protects
the first LED; with a short DIN wire it can be skipped.

The C3-Zero has a single GND hole, so twist the ring's and the knob's GND
wires together and solder them into it as one. Check the hole labels
against Waveshare's pinout image before soldering. Full design and pin
notes: `docs/superpowers/specs/2026-11-12-talon-controller-design.md`,
"Hardware wiring".

The shell's cradle has grooves under both pin rows, so the solder tails
on the board's underside do not lift it.

## Assembly order

Work with the shell upside down (open bottom up). The cap goes on last, so
the box never rests on it.

1. **Knob board wires.** Clip the KY-040's pins to stubs and solder its five
   wires (see Wiring).
2. **Ring.** Solder the ring's three wires to its pads. Thread their free
   ends down through the slot in the face, then lay the ring flat on the
   face. Turn the ring to its 12 o'clock position and fix it to the face
   with two small pieces of thin double-sided tape (or a dab of hot glue):
   the firmware's 12 o'clock LED assumes the ring never turns. The ring
   goes before the hood: the hood covers it, and the nut in step 3 clamps
   the hood down.
3. **Hood and knob board.** Set the hood over the ring, its tabs in the
   lip's notches. From inside the shell, push the encoder's threaded collar
   up through the face and the hood's well floor; the encoder body's square
   top drops into the square frame on the face's underside, which stops it
   turning. Add the metal washer and the nut inside the well and snug it
   with the nut driver. Do not crank it.
4. **Route the ring wires** along the channel under the face and top and
   down the back wall.
5. **Solder the C3-Zero.** With the board outside the box, solder every
   wire straight into its hole (see Wiring). The ring wires must already be
   through the face slot (step 2): once they are soldered to the C3-Zero,
   they cannot be threaded any more.
6. **C3-Zero into the cradle.** Tilt the board, slide its USB end into the
   slot in the back wall, and lay the other end down on the pedestal. Press
   the small clip down over the two side rails at the board's inner end
   until both legs click; only its narrow tongue reaches over the board, at
   the middle of the inner edge, clear of the corner holes. To remove: spread the clip's legs and lift it off.
7. **Bottom plate.** Stick the weights in their pockets. Slide an M3 nut
   into each corner post's side slot until it clicks past the bumps. Set the
   plate on, then drive the four screws up from below. Snug, not tight.
8. **Feet.** Glue a TPU foot into each round recess on the underside.
9. **Cap, last.** Turn the box onto its feet and push the cap onto the
   shaft (flat side matches).

## Test coupons (print these first)

Two small, cheap prints that test the fits that are hard to get right on
paper, before you spend hours on the full housing.

**Fit coupon** (`stl/fit_test.stl`, opaque), five pieces in a row. The real
face is split in two here so each half prints flat with no supports:

1. **Lip ring**: the outer part of the face, with the raised seat lip and
   the key notches the hood locks into.
2. **Face disc**: the centre of the face the knob comes through. It prints
   upside down (the top face on the bed), so the small square frame points
   up. Flip it over to use it: the encoder body's square top sits in the
   frame.
3. **Floor washer**: a flat ring the same thickness as the hood's well
   floor. In the real build, the hood floor sits on the face and the nut
   clamps both. This washer stands in for it.
4. **Bore plug**: a short cylinder with the knob cap's D-shaped hole in it,
   open side up.
5. **Hood segment**: a 40-degree slice of the hood wall with one key tab,
   printed upside down like the real hood.

**Glow coupon** (`stl/glow_test.stl`, translucent PETG): four small tiles.
Each tile is a face with two legs and holds its face 5, 8, 10 or 12 mm
above the ring's LEDs (the number is on a leg). They print face down, like
the hood, so the face you look at gets the same bed finish the hood will.
To test: flip a tile over, set the ring flat on the desk, and stand the
tile over the ring with its legs on either side of the LED band.

**Which plate for translucent PETG** (glow tiles and hood). The plate sets
the look of the face you see:
- **Textured PEI** (no glue): a frosted face that spreads light. This is
  probably the best diffuser.
- **Smooth PEI** or **Engineering plate**: **use glue stick**. Bambu
  lists glue for PETG on both, and without it PETG can rip the coating.
  You get a glossier face that is clearer, so the LED dots show more.
- Avoid the Cool Plate for PETG.
- Let the plate cool fully before you pop the parts off.
- Worth doing: print the tiles once per plate, then compare them in
  checkpoint (e).

## CHECKPOINT: what to check, and what to change if it fails

Write what you find in `docs/housing-measurements.md`. Then change the
listed number in `lib/params.scad`. Each fit has its own number, so
changing one never moves another.

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
- Tab will not go in: raise `key_fit` (now 0.2) to 0.3. This widens the
  notch and the gap around the hood wall.
- Sloppy, twists noticeably: lower `key_fit` to 0.1, or raise `key_tab_w`
  (now 2).
- Snapped off easily: raise `key_tab_w` to 3.

**(d) The bore plug slides onto the knob shaft's flat (D) end without slop
or forcing.**
- Will not go on, or needs force: raise `bore_fit` (now 0.2) by 0.1, or
  raise `shaft_flat` by 0.1 if only the flat side binds.
- Wobbles or turns on the shaft: lower `bore_fit` by 0.1.

**(e) Pick the glow gap that hides the LED dots.** Light the ring, lay the
glow strip over it, and look straight down at each step. Pick the lowest
step where you see one even glow instead of separate dots. If you printed
tiles on more than one plate, also note which finish hides the dots best
and print the hood on that plate.
- Set `glow_gap` to that number (now 8).
- The cap above limits how tall the hood can be. Right now the maximum is
  9.4. If you pick 10 or 12, the render will stop with "glow_gap too large".
  Tell Claude, and we will raise the knob cap (`cap_over_shaft`) or slim
  the cap float to make room.

**(f) The encoder body sits in the frame.** With the face disc on the
collar (frame side down), the encoder body's square top drops into the
frame with no wobble, and the disc sits flat on the body.
- Will not go in, or the disc rocks: raise `body_fit` (now 0.2) by 0.1.
- Goes in but the body turns or wobbles: lower `body_fit` by 0.1.

**(g) Measure your USB-C plug.** With calipers, measure your USB-C cable's
plug body (the plastic overmold behind the metal tip): width x height. Set
`usb_plug_hole` to that plus 0.5 each way (now 12.5 x 7.5) before printing
the shell. The port sits 1 mm inside the back wall, so the overmold has to
fit into the hole for the plug to seat.

**Other fits** (no coupon; change only if the real part fails):

| Number       | What it sets (all now 0.2)                         |
|--------------|----------------------------------------------------|
| `c3_fit`     | C3-Zero slot: board play to the front stop, width, height |
| `m3_nut_fit` | M3 nut slots in the corner posts                   |
| `plate_fit`  | bottom plate's gap inside the shell outline        |
| `foot_fit`   | TPU foot recesses                                  |
| `socket_fit` | nut driver's hex socket                            |
| `halo_fit`   | halo sleeve over the well wall (`halo_block` only) |

Once a-g pass, re-run `bash print/tests/run.sh` and print the real parts.
