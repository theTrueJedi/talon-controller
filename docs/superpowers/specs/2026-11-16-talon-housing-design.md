# Talon controller housing: design

Status: approved by Evan 2026-11-16 ("we can try it"), with the nut-clamp safeguards below.
Parent spec: `2026-11-12-talon-controller-design.md` (this replaces its short
"Housing" section). Measurements: `docs/housing-measurements.md`.

## Intent

A desk box for the Talon controller. Evan sees and works it from his chair.
A 12-LED ring glows the Talon mode color under a raised translucent "hood"
diffuser. A knob cap sits in the middle: tap, double-tap, and hold for modes,
turn to scroll. It should look deliberate and finished, not like a project
box. It must not slide when pressed. It must open for repairs.

**Goals**
- The ring's light reads as an even glow, not 12 dots. The hood's outer edge
  also glows, so the light shows from the side of the room.
- Pressing the knob feels solid. The box doesn't skid, and the cap never
  bottoms out on the diffuser.
- No visible fasteners on the face. Screws only on the bottom.
- One parametric OpenSCAD file. Evan fixes a fit by changing a number and
  reprinting.

**Non-goals:** the room-scale WLED sign, macro keys (a separate VIA pad),
battery or wireless.

**Anti-goals:** a fragile part that cracks when the nut is tightened. A
diffuser that shows hot spots. Glue joints that block access to the nut or
wiring.

## Constraints

- Parts and measurements: `docs/housing-measurements.md` (calipers).
- Printer: Bambu. Shell and cap in opaque PLA or PETG. Diffuser in
  translucent PETG. Feet in TPU.
- Fasteners on hand: M3 socket-head screws 6–25 mm with nuts; an M2–M5
  assortment with washers; the encoder's own nut (10 mm across flats, 2 mm
  thick) and washer (11.5 OD × 0.5).
- Weights: ½ oz wheel weights in a 19.65 × 22 × 5.8 pocket (Evan's existing
  cutout). Rebuild the pocket as a parameter; don't import the STL.
- Wiring: direct solder, no headers on the C3-Zero. **Knob side (updated
  2026-11-16):** Evan is fine clipping the KY-040's right-angle pins to short
  stubs and soldering wires directly. That is the default, so no jumper
  sockets need room inside the box.

## Approaches considered

| Approach | Trade-off | Outcome |
|---|---|---|
| Claude writes a parametric OpenSCAD model; Evan exports in Bambu Studio | Fits get fixed by editing numbers. Evan doesn't model. | **Chosen** |
| Evan models in his own CAD from a dimensioned drawing | More of Evan's time, more back and forth | Rejected |

How the diffuser and knob attach:

| Approach | Trade-off | Outcome |
|---|---|---|
| Knob cap is the diffuser (original spec) | Light turns with the knob; the cap must be translucent | Superseded |
| Flat diffuser disc, press-fit into the face | Simple, but a flat disc close to the LEDs shows dots, and the fit needs tuning | Rejected |
| Pegs through the ring's holes, M2 from below | Solid, but the pegs carry light and show as bright spots | Rejected |
| **Hood diffuser whose center well floor is clamped onto the encoder body by the encoder's own nut** (Evan's sketch) | No visible fasteners; one nut holds the top. The well must be deep and wide enough for a nut driver. | **Chosen** |

## Design (Evan's decisions)

- **Shape:** a wedge. A sloped front face at **30°**, and the USB-C cable
  leaving the **back**. Per Evan's first sketch, the rear part is flat-topped
  behind the slope.
- **Ring:** recessed in the sloped face.
- **Diffuser hood** (Evan's second sketch): an upside-down U in section. An
  outer wall stands on the face, a top annulus covers the ring, and an inner
  wall drops to a **well**. The well floor rests on top of the encoder body.
  The encoder's washer and nut clamp the floor down. The hood stands proud of
  the face, so its outer wall glows.
- **Cap:** T-shaped. A stem goes down the well onto the D-shaped shaft, and a
  wide top overhangs the inner part of the hood.
- **Access:** a removable bottom plate held by M3 screws. It carries the
  weight pockets.
- **Feet:** TPU.

## Design (Claude's calls; Evan can override)

**Datum:** z = 0 at the KY-040 PCB top surface, measured along the shaft axis
(the face normal). All heights below are defaults derived from measurements.
The builder recomputes them from parameters.

**Mounting (revised after builder check):** the knob is **panel-mounted
through the face**, the way commercial knobs mount. The face plate's center
sits on top of the encoder body. The hood's well floor sits on the face. The
encoder's washer and nut clamp **face + well floor** together onto the
encoder body. There are no screw posts for the KY-040.
- Pressing the knob loads the collar thread, which is built for it, not
  M2 threads in plastic.
- The hood's well floor and outer wall both sit on the same face plane. The
  hood's underside is one flat plane, so it prints flat and seats without
  rocking.
- Anti-rotation: one printed pin hangs from the face underside into the
  KY-040 hole **farther from the shaft** (4.5 from the header edge, 10 from
  the shaft; pin Ø2.6 in the Ø3 hole, a parameter). The nearer hole sits about 1 mm
  from the encoder body's corner, too tight for a pin. The encoder top has
  no lug (Evan, 2026-11-16): the collar rises straight from a flat square.

**Nut-clamp safeguards (Evan was nervous about the nut alone; added
2026-11-16):**
- **The hood is keyed, so it can't spin.** Two small tabs on the hood's
  outer wall drop into notches in the face's seat lip. The nut only presses
  down; it never has to resist twisting.
- **Panel mounting is the encoder's intended mount.** The collar and nut are
  how these encoders go into pedals and amps. Knob turns don't torque the
  hood: the shaft spins freely inside the collar.
- **The nut can loosen from detent clicks over time.** Mitigation: a drop of
  removable (blue) threadlocker, or a printed nut retainer in the cap's
  stem. Builder's choice.
- **Fallback, off by default:** a parameter adds 2 hidden M2 screw bosses.
  M2 screws go up through the face into thickened spots on the hood's outer
  wall, reachable from inside once the bottom plate is off. Use it only if
  the nut-only version fails the fit test, because the bosses may show as
  brighter spots.
- **Proven before the full print:** the face-center fit coupon includes a
  small hood-seat segment. Clamp it with the real nut, then try to twist and
  wiggle it.

**Stack along the shaft:**

| Item | z (mm) |
|---|---|
| KY-040 PCB | −1.5 … 0 |
| Encoder body top = face underside | 6.5 |
| Face plate (1.5 thick, parameter) | 6.5 … 8.0 |
| Ring (sits on face top inside the hood) | 8.0 … 11.1 |
| Well floor (1.5 thick) | 8.0 … 9.5 |
| Washer | 9.5 … 10.0 |
| Nut | 10.0 … 12.0 (1.5 mm of collar thread spare) |
| Collar top | 13.5 |
| Glow gap (parameter, default 8) | 11.1 … 19.1 |
| Hood top (2 thick) | 21.1 |
| Cap overhang underside (1.5 above hood) | 22.6 |
| D-flat section of shaft (axial lengths per Evan's drawing) | 19 … 26 |
| Cap top (1.5 above shaft top) | 27.5 |

The glow gap can rise to about 9.5 before the cap's overhang gets thinner
than about 3.5 mm. The collar budget is face + floor + washer + nut = 5.5 of
7 mm.

**Shell (opaque):**
- Face plate 1.5 mm, locally thicker away from the center if needed for
  stiffness. A **Ø7.4 hole** for the collar (measured Ø7). The
  encoder body sits entirely below the face.
- The KY-040 hangs from the face on the nut. Its **header edge points toward
  the back** of the wedge, the tallest part of the interior. The pins are
  clipped and wires soldered direct.
- The ring is centered on the **shaft**, not the PCB. The shaft sits 11.5 mm
  from one short edge and 10 mm from the long edge opposite the holes.
- The ring lies flat on the face top. The hood's outer wall locates it
  radially. A **wire slot** through the face under the ring's pads, toward
  the back. Ring rotation doesn't matter (firmware has a 12 o'clock index
  setting).
- Hood seat: a shallow locating lip on the face, outside the hood's outer
  wall. Hood inner wall Ø52 (ring OD 50 + 2), wall 1.6, so the hood is
  about Ø55.2. **The face grows to about 72 mm along the slope**, which
  leaves margin for the seat and the fillets.
- **C3-Zero cradle** at the inside of the back wall: a slot holding the
  24 × 18.05 board with its USB-C port flush to the wall. A **front stop**
  takes the push of plugging in the cable. A light clip or lip holds it down.
  Removable without tools.
- **USB-C hole** in the back wall for the cable's plug body: a rounded
  rectangle, parameter, default 12.5 × 7.5. The port itself is 8.85 × 3.15.
- **4 corner bosses** with M3 hex-nut traps, for the bottom plate.
- Minimum wall 2 mm. Inside clearance ≥ 1 mm around every part.
- Box size follows from the hood plus margin and from fitting everything
  under the face. Keep it as small as clears.

**Diffuser hood (translucent PETG):**
- Outer wall ID 52, wall 1.6 (OD ≈ 55.2). The underside is one flat plane:
  the outer wall bottom and the well floor bottom both sit on the face top.
- Top annulus 2 mm.
- Well inner Ø **16**, to clear the nut (10 A/F, ~11.6 across corners), the
  washer (11.5 OD) and a nut driver.
- Well floor 1.5 mm with a Ø7.4 hole for the collar. It is clamped with the
  face between the encoder body and the nut.
- The well walls glow, making a faint halo under the cap's edge. A parameter
  can blank it with an opaque sleeve.

**Cap (opaque):**
- Top disc Ø **28** (parameter, max ~32 before it covers LEDs head-on).
  Floats 1.5 mm above the hood top.
- Stem OD 15 (well 16). A D-shaped bore along the shaft's D-flat section, and
  a round clearance bore below it. The stem bottom stays ≥ 1 mm above the nut
  top.
- Optional knurl or grip ring on the disc edge.

**Bottom plate (opaque):**
- 4 × M3 screws into the shell's nut traps. Countersunk or counterbored, so
  the heads sit flush.
- **Weight pockets**, parameter count, default 4 (≈ 2 oz). Each is a
  19.65 × 22 × 5.8 pocket on the inside face. The weights' own 3M adhesive
  backing holds them; the pocket size already allows for it (Evan's proven
  cutout). No cover.
- 4 shallow recesses for **TPU feet** (printed discs, parameter Ø/thickness).
  Prefer the front edge, where the press load lands.

**Tools and test prints (printable, in the same file):**
- **Nut driver:** a 10 mm hex socket (+0.2) with OD ≤ 15, a length that
  reaches the well floor, and a handle.
- **Glow test coupon:** a stepped strip of hood top (gaps 5/8/10/12 mm) to
  hold over the lit ring before printing the full hood.
- **Fit test coupons:** the face center (collar hole plus anti-rotation pin), a ring recess
  ring, and a cap bore on a short plug, so fits are checked cheaply first.

**OpenSCAD file:** `print/talon-housing.scad`. All measurements and
clearances are named parameters at the top. A `part = "shell" | "hood" |
"cap" | "bottom" | "feet" | "nut_driver" | "glow_test" | "fit_test" |
"assembly"` switch, where assembly is a preview with the parts placed for
interference checking. Each part exports flat on its print face, with
supports noted.

## Related change to the parent spec (pin map)

C3-Zero has one GND. All wires go on the pin row 5V · GND · 3V3 · GPIO0–5:
- Ring DIN → **GPIO0**; ring 5V/GND → 5V/GND.
- KY-040 CLK/DT/SW → **GPIO3/4/5**; + → 3V3; GND → GND, shared with the
  ring's GND in the one hole.
- Avoid GPIO2/8/9 (boot), GPIO10 (onboard LED), GPIO18/19 (USB).

The parent spec's wiring table gets updated to match when the plan is
written.

## Left to the builder

- The exact wedge outline: front height, flat-top depth, fillets and
  chamfers.
- Print orientations and supports.
- Clip style for the C3-Zero cradle.
- Wire routing channels and tie points.
- The shape of the hood seat (groove vs lip).

## Still unmeasured / open

- **Shaft diameter and D-flat thickness** (the cap bore needs them). The
  default assumes EC11: Ø6, flat at 4.5. The fit-test coupon confirms it.
- **USB-C cable plug body** width × height (the back-wall hole). The default
  is 12.5 × 7.5.


## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Hood shows LED dots | Moderate | Glow-gap parameter plus a test coupon before the full print |
| PETG well floor / PLA face creep or crack under the nut | Moderate | Washer, snug not cranked, 1.5 mm each (parameters) |
| Collar has only 1.5 mm of thread spare above the nut | FYI | Face and floor thickness are parameters; a fit coupon checks it |
| Box skids when pressed | Moderate | 2 oz weights, TPU feet at the front, 30° face |
| Tight fit at the 30° slope (supports, overhangs) | FYI | Builder picks orientations; fit coupons first |
| PCB corners 0.9 mm inside the ring ID | FYI | Irrelevant: the PCB sits below the face |
