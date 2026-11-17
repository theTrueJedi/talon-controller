# Housing measurements (calipers, Evan)

Source data for the parametric OpenSCAD housing. Units: mm. Blank = not yet measured.

## LED ring (12× WS2812B 5050)
| What | Value |
|---|---|
| Outer diameter | 50 |
| Inner diameter | 37 |
| Thickness incl. LEDs | 3.1 |
| Mounting holes | 4× Ø2 |
| Pads (back) | DI, 5V, GND, DO |

## KY-040 knob board
| What | Value |
|---|---|
| Shaft, D-flat section (top) | 7 |
| Shaft, round section | 5 |
| Gap shaft→collar | 0.5 |
| Threaded collar height | 7 |
| Encoder body height above PCB top | 6.5 (8 from PCB underside) |
| PCB thickness | 1.5 |
| PCB length × width | 26 × 19 |
| Shaft center from PCB edges | 11.5 from the short edge opposite the header; 10 from the long edge opposite the holes (so 14.5 from header edge, 9 from hole edge) |
| Header | right-angle, 5 pins on the short edge opposite the shaft side; pins stick ~5 mm past the PCB edge (photo estimate); with F–F jumpers on, ~6.5 high |
| Mounting holes | 2× Ø3, 17 c–c, along the long edge 9 from shaft center; distance from that edge: |
| Nut across flats / thickness | 10 / 2 |

Shaft is NOT centered on the PCB; the ring centers on the shaft.

## ESP32-C3-Zero
| What | Value |
|---|---|
| Length × width | 24 × 18.05 (USB-C flush with the short edge) |
| USB-C port height | 3.16 |
| Pins (bottom view, USB up) | left 21,20,19,18,10,9,8,7,6 · right 5V,GND,3V3,0,1,2,3,4,5 (one GND) |

## Other parts
- Weight pocket: 19.65 × 22 × 5.8 (½ oz wheel weight, from `~/Pers/3D Printing/COMPONENTS/WEIGHT_0.5oz.stl`).
- Screws on hand: M3 SHCS 6–25 mm + nuts; M2–M5 assortment with washers.

## Derived (Claude, 2026-11-16)
- PCB corners from shaft center: 14.6, 15.2, 17.1, 17.6 → all inside the ring's 18.5 inner radius (0.9 margin).
- LED band: radius 18.5–25; LED inner edge ≈ 19.
