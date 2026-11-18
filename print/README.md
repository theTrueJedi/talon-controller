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
| `stl/`                 | Ready-to-slice STLs, `<part>_vN.stl`; print the highest N |
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

Each part is saved as `stl/<part>_vN.stl`. A part gets a new number only
when its shape changed; old versions stay, so you can tell which file a
print came from. Always print the highest number.

Two more `part=` values are for checking, not printing: `assembly` shows
every part in place with stand-ins for the bought parts (ring, knob board
with its clipped stubs and solder joints, C3-Zero with its header and
jumper plugs, nut, washer, screws, weights), and `interference` shows any
place two of them overlap. `interference` must come out empty; the test
run checks that.

## Parts, material, and how each lies on the bed

The STLs already come out in the orientation listed. Import into Bambu
Studio and do not rotate them. Only the shell needs support, and only on one edge.

| Part (`part=`) | Material           | Qty | Orientation on the bed                 | Supports |
|----------------|--------------------|-----|----------------------------------------|----------|
| `fit_test`     | opaque PLA or PETG | 1   | five pieces side by side, see below    | none     |
| `frame_test`   | opaque PLA or PETG | 1   | face down, square frame up             | none     |
| `glow_test`    | translucent PETG   | 1   | four tiles, face down, legs up         | none     |
| `nut_driver`   | opaque PLA or PETG | 1   | handle down, socket up                 | none     |
| `shell`        | opaque PLA or PETG | 1   | on its back wall, open bottom sideways | **paint** front rim edge only |
| `c3_clip`      | **PETG** (PLA may crack at the snap) | 1 | on its front face | none |
| `hood`         | translucent PETG   | 1   | upside down: top face on the bed       | none     |
| `cap`          | opaque PLA or PETG, **100% infill** | 1 | upside down: top face on the bed | none |
| `bottom`       | opaque PLA or PETG | 1   | outside face down, C3 cradle and lip on top; **pause for the weights** (below) | none |
| `halo`         | opaque PLA or PETG | 1   | either end down (only with `halo_block=true`) | none |

`stl/cap_v3b.stl` is a shorter knob to compare: 10 mm disc instead of 14
(exported by hand with `-D cap_disc_t=10`; same 29 mm knurl and bore).

"None" means the part was shaped to print without supports: the shell's
inside front is a 45 degree ramp and its front screw posts are teardrops;
the square frame under the face (it holds the knob's body) is only 1 mm
deep; the bottom plate's screw counterbores are short bridges, its
weight-pocket roofs print straight onto the weights (see the pause below),
and the C3 cradle and the seating lip are upright ribs (the lip's front run
leans 45 degrees, which prints fine).

**Shell exception, the front rim edge.** The inside front ramp is 45
degrees, but it starts at the open rim as a ~64 mm line with nothing under
it except the side walls at each end. Bambu calls that a bridge and won't
support it, so the first layers sag and the ramp builds on the sag. The
result would be a drooped lip where the shell sits on the bottom plate. Use
the support-painting tool to paint a thin strip along that inner front rim
edge, keep auto-support off, and check in Preview that support appears
under the strip. No in-model fix works here: a ramp that grows down from
the face would be a ~25 mm solid wedge in the encoder's space.

**Bottom plate: pause for the weights.** The four weights are sealed inside
the plate. Render `part="bottom"` and note the `weight_pause_z` echo (now
8.8 mm): that is the height of the pocket tops. In Bambu Studio, open the
layer slider in the preview, find the first layer above 8.8 mm (9.0 mm at
0.2 mm layers), right-click it and add a pause. Print. When the printer
pauses, drop one weight into each corner pocket, check none sticks up past
the pocket top, then resume. Leave their sticky backing on: the 5.8 mm
was measured with it. The printer seals over
them.

**Knob cap: 100% infill.** It is a solid 29 mm knob; full infill gives it
its weight.

The hood is the only part the light shines through, so it is the only big
part in translucent PETG. Everything else is opaque so light does not leak.

The C3-Zero sits face-up in a cradle on the bottom plate, 11.5 mm off
centre (`c3_x`), away from its wired row. Its USB-C port sits about 1.4 mm
inside the back wall on purpose: the board's edge sits 0.6 mm into a 1 mm
slot in the wall (0.4 mm spare at the slot's bottom, `c3_slot_clr`, so the
board never bumps the shell as the plate goes on). So the plug's plastic body
has to fit INTO the wall's hole for the plug to seat (checkpoint g). A small
block on the plate fills the hole's open bottom: full height under the board's
edge (it supports it), and stepped down to 0.2 mm under the plug body where
the plug enters, so the plug still seats. The slot, the USB hole and
the header recess beside them are all open at the bottom edge, so the board
lifts out with the plate. The unplug pull is taken by that slot, so unplug by
the plug body, not the cable.

## Bought parts for the box

- **4x M3 x 10 socket-head screws** (from the M3 kit) and **4x M3 hex nuts**.
  The screws come up through the 10 mm bottom plate into nuts held in the
  shell's corner posts. The counterbores are 5 mm deep, so the heads end up
  2 mm below the plate's underside (recessed, not flush). The plate is
  sized for 10 mm screws. A 12 mm or 8 mm screw also fits, but set
  `m3_screw_l` to match and re-export first: 12 sits flush, 8 sits 4 mm deep.
  The model refuses 6 mm (too little plate under the head) and 14 mm (the
  head sticks out).
- **4x ½ oz weights**, 19.65 x 22 x 5.8 mm, one per corner, sealed inside
  the plate while it prints (see the pause above). The pockets are exactly
  that size, no extra room.
- **One 9-pin 2.54 mm right-angle header** for the C3-Zero, and **female
  jumper wires** (F-F, some cut in half).
- **Thin double-sided tape** (or a hot-glue gun) for the ring.
- **2x TPU pads, 15 x 60 x 1.4 mm** (Evan's pre-printed ones) for the
  feet, and glue for them (super glue or contact cement). They sit in
  0.3 mm recesses on the plate's underside and stand 1.1 mm proud.

## Wiring (one header on the C3, jumpers plug in there)

The C3-Zero is the only place anything plugs in. Unplug its jumpers and the
plate (with the board on it) comes away from the shell; nothing else needs
desoldering.

- **C3-Zero:** solder one 9-pin 2.54 mm right-angle header onto its wired
  row (5V, GND, 3V3, GPIO0 to GPIO5, from the USB end). Fit it so the legs
  point **sideways off the board, toward the middle of the box** (away from
  the board's other row), not up and not over the board. If the strip's
  legs are bent at 45 degrees, bend them to 90 degrees first.
- **KY-040 knob board:** clip its right-angle pins to short stubs. Cut four
  female jumpers in half and solder each cut end to the +, CLK, DT and SW
  stubs. The female ends plug onto the C3's header. The GND stub gets a
  plain wire instead (see the GND splice below).
- **Ring:** cut three female jumpers in half and solder each cut end to one
  of the ring's pads (5V, GND, DIN).

| Wire           | C3-Zero pin |
|----------------|-------------|
| Ring DIN       | GPIO0       |
| Ring 5V        | 5V          |
| Ring GND       | GND         |
| KY-040 GND     | GND (the same pin: see below) |
| KY-040 +       | 3V3         |
| KY-040 CLK     | GPIO3       |
| KY-040 DT      | GPIO4       |
| KY-040 SW      | GPIO5       |

The C3-Zero has a single GND pin, and only one plug fits on it. So the
ring's GND and the knob's GND share one plug: the knob's GND stub gets a
short plain wire, and its free end is spliced onto the ring's GND jumper
between the face slot and the plug (strip about 5 mm from the jumper's
middle, wrap the knob wire round it, solder, and cover it with tape or heat
shrink). The splice ends up inside the shell, below the face, so it is done
after the ring's jumpers are threaded through the slot (assembly step 3).
Only the ring's GND plug goes onto the GND pin.

Optional: a 330 Ω resistor soldered inline in the ring's DIN wire protects
the first LED; with a short DIN wire it can be skipped.

Check the pin labels against Waveshare's pinout image before soldering.
Full design and pin notes:
`docs/superpowers/specs/2026-11-12-talon-controller-design.md`, "Hardware
wiring", and the housing spec's "Amendment 2026-11-17 (first test prints)".

The plate's cradle has grooves under both pin rows, so the header's solder
tails on the board's underside do not lift it. If the jumpers work loose, a
dab of hot glue or a strip of tape over each plug holds it.

## Assembly order

Work with the shell upside down (open bottom up). The cap goes on last, so
the box never rests on it.

1. **Solder everything first** (see Wiring): the header on the C3-Zero, the
   half jumpers on the knob board's stubs and on the ring's pads, and the
   plain GND wire on the knob board's GND stub.
2. **Ring.** Thread the ring jumpers' plug ends down through the slot in the
   face (a plug is 2.54 mm square and passes the 11 x 5.5 mm slot), then lay
   the ring flat on the face. Turn the ring to its 12 o'clock position and
   fix it to the face with two small pieces of thin double-sided tape (or a
   dab of hot glue): the firmware's 12 o'clock LED assumes the ring never
   turns. The ring goes before the hood: the hood covers it, and the nut in
   step 4 clamps the hood down.
3. **GND splice.** Below the face, inside the shell, splice the knob
   board's GND wire onto the ring's GND jumper, between the slot and the
   plug (see Wiring). Tape or heat shrink over it.
4. **Hood and knob board.** Set the hood over the ring, its tabs in the
   lip's notches. From inside the shell, push the encoder's threaded collar
   up through the face and the hood's well floor; the encoder body's square
   top drops into the square frame on the face's underside, which stops it
   turning. Add the metal washer and the nut inside the well and snug it
   with the nut driver. Do not crank it.
5. **Route the ring wires** along the channel under the face and top and
   down the back wall.
6. **C3-Zero onto the plate.** The weights are already sealed in the plate
   (see the print pause). Set the board face-up in the plate's cradle, its
   USB end toward the plate's back edge and its header toward the middle.
   Press the small clip down over the two side rails at the board's inner
   end until both legs click; only its two small teeth reach over the
   board, one each side of the red chip antenna, clear of the corner holes. To remove:
   spread the clip's legs and lift it off.
7. **Plug in the jumpers.** Hold the plate next to the open shell and plug
   each jumper onto its C3 pin (see the table). Leave enough slack that
   the plate can be lifted away from the box with the plugs still on.
8. **Bottom plate, last of the box.** Slide an M3 nut into each corner
   post's side slot until it clicks past the bumps. Lower the plate on: the
   lip round its top drops just inside the shell's walls and stops it
   sliding, the board's USB end slides into the back wall's slot and notch,
   and the header and its plugs into the recess beside them. Tuck the wires in so
   none is pinched under the plate's edge, then drive the four screws up
   from below. Snug, not tight.
9. **Feet.** Glue a 15 x 60 TPU pad into each long recess on the
   underside, its length running front to back.
10. **Cap.** Turn the box onto its feet and push the cap onto the shaft
   (flat side matches).

To get at the board later (or reach its BOOT button): unscrew the plate,
lift it away, and unplug the jumpers.

## Test coupons (print these first)

Two small, cheap prints that test the fits that are hard to get right on
paper, before you spend hours on the full housing.

**Fit coupon** (`stl/fit_test_vN.stl`, opaque), five pieces in a row. The real
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

**Frame coupon** (`stl/frame_test_vN.stl`, opaque): the fit coupon's
centre disc on its own (collar hole and square frame). Print it to re-check
(a) or (f) without printing the whole fit coupon.

**Glow coupon** (`stl/glow_test_vN.stl`, translucent PETG): four small tiles.
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
- Too tight: raise `collar_hole_d` (now 7.2) by 0.2 at a time.
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
- Tab will not go in: raise `key_fit` (now 0.1) to 0.2. This widens the
  notch and the gap around the hood wall.
- Sloppy, twists noticeably: lower `key_fit` to 0.05, or raise `key_tab_w`
  (now 2).
- Snapped off easily: raise `key_tab_w` to 3.

**(d) The bore plug slides onto the knob shaft's flat (D) end without slop
or forcing.**
- Will not go on, or needs force: raise `bore_fit` (now 0.15) by 0.1, or
  raise `shaft_flat` by 0.1 if only the flat side binds.
- Wobbles or turns on the shaft: lower `bore_fit` by 0.1.

**(e) Pick the glow gap that hides the LED dots.** Light the ring, lay the
glow strip over it, and look straight down at each step. Pick the lowest
step where you see one even glow instead of separate dots. If you printed
tiles on more than one plate, also note which finish hides the dots best
and print the hood on that plate.
- Set `glow_gap` to that number (now 8).
- Any step from 5 to 12 fits: the knob cap sits high enough for all of them.

**(f) The encoder body sits in the frame.** With the face disc on the
collar (frame side down), the encoder body's square top drops into the
frame with no wobble, and the disc sits flat on the body.
- Will not go in, or the disc rocks: raise `body_fit` (now 0.07) by 0.1.
- Goes in but the body turns or wobbles: lower `body_fit` by 0.1.

**(g) USB-C plug: measured 2026-11-18.** Evan's cables measure 12.12 x
6.6 and 11 x 6.1 mm (`usb_plug`); both fit the 12.5 x 7.5 hole
(`usb_plug_hole`), so the printed shell stays. The model refuses a plug
wider than the hole. For a new cable, measure the plastic overmold behind
the metal tip and set `usb_plug` to it.

**Other fits** (no coupon; change only if the real part fails):

| Number       | Now  | What it sets                                       |
|--------------|------|----------------------------------------------------|
| `c3_fit`     | 0.2  | C3-Zero slot: board play to the front stop, width, height |
| `m3_nut_fit` | 0.2  | M3 nut slots in the corner posts                   |
| `plate_fit`  | 0.2  | bottom plate's gap inside the shell outline        |
| `pad_fit`    | 0.15 | TPU pad recesses, each edge                        |
| `socket_fit` | 0.2  | nut driver's hex socket                            |
| `halo_fit`   | 0.2  | halo sleeve over the well wall (`halo_block` only) |

**(h) When the header arrives: measure its bent legs.** Solder (or just
hold) the header on the C3-Zero and measure, with calipers, how high the
middle of the bent legs sits above the board's top face. Set `hdr_leg_z`
to that (now 1.4). Also set `hdr_leg_out` (now 6) to how far the legs
reach past the header's plastic, and `plug` (now 2.54 x 2.54 x 14) to the
jumper plug's width, height and length.
- The cradle's rail on the header side (-X) is already lowered under the
  plugs, and it follows `hdr_leg_z`: re-render and it keeps 0.2 mm under
  them. It goes no lower than half the board's thickness; below about
  1 mm of leg height the render stops with "C3 wired-side rail too low".
  Tell Claude if that happens.

**(i) The plate drops into the shell (bottom_v6).** Lower the plate into
the open shell without screws. It should drop in with a light push and not
slide side to side or front to back.
- Will not go in, or needs force: raise `lip_fit` (now 0.1) to 0.15.
- Slides noticeably: lower `lip_fit` to 0.05.
- The back stop is the C3 cradle's back end (no lip fits on the back wall);
  it follows `lip_fit` too.

**(j) The clip holds the board (c3_clip_v3).** With the board in the
cradle, press the clip on. Both teeth should sit on the board's edge either
side of the red antenna, not on it, and the board should not lift.
- A tooth touches the antenna: raise `c3_ant_w` (now 6.4) to the measured
  length plus 0.4.

**(k) The board clears the back wall as the plate goes on.** If the USB
end still catches, raise `c3_slot_clr` (now 0.4) to 0.5; the model refuses
less than 0.4 mm of the board edge left in the slot.

Once a-k pass, re-run `bash print/tests/run.sh` and print the real parts.
