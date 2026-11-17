// Stack and fit checks over params.scad. Any failure aborts the render
// (OpenSCAD exits non-zero and prints the message to stderr).

collar_spare = collar_h - (face_t + floor_t + washer_t + nut_t);
assert(collar_spare >= 1.0, "collar thread: nut has <1mm engagement");

assert(hood_top_z <= cap_top_z - 3.5 - cap_float,
       str("glow_gap too large: max is ", max_glow_gap));

assert(cap_d <= 32, "cap covers LEDs");

assert(well_id >= nut_corner + 3, "well too narrow for nut driver");

assert(stem_od <= well_id - 1, "cap stem too wide for well");

assert(hood_id >= ring_od + 2, "hood ID too tight around ring");

// Circular distance, so 350 vs 0 counts as 10 degrees apart.
function ang_dist(a, b) = let(d = ((a - b) % 360 + 360) % 360) min(d, 360 - d);
for (a = key_tab_angles)
    assert(ang_dist(a, wire_slot_angle) >= 30, "key tab on wire slot");

// Anti-rotation pin in the far KY-040 hole must clear the encoder body corner.
ky_pin_corner_dist = norm(ky_far_hole_xy - ky_far_body_corner_xy);
assert(ky_pin_corner_dist >= pin_d / 2 + 0.5,
       str("anti-rotation pin hits encoder body corner: ", ky_pin_corner_dist));
