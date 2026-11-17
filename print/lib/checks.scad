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

// Hood keying, wire slot and fallback options.
assert(hood_od / 2 + key_tab_len <= lip_or, "key tab sticks out past the seat lip");
assert(wire_slot_r - wire_slot[1] / 2 >= ring_id / 2 &&
       wire_slot_r + wire_slot[1] / 2 <= ring_od / 2, "wire slot outside ring band");
assert(hood_screw_r - m2_boss_d / 2 >= ring_od / 2 + m2_boss_ring_clr, "M2 boss hits the ring");
if (hood_screws)
    for (s = hood_screw_angles) {
        assert(ang_dist(s, wire_slot_angle) >= 30, "M2 boss on wire slot");
        for (a = key_tab_angles) assert(ang_dist(s, a) >= 30, "M2 boss on key tab");
    }
assert(halo_ir + halo_t <= ring_id / 2 - 1, "halo sleeve reaches the LEDs");

// Cap bore and nut driver.
assert(cap_roof >= cap_roof_min, str("cap roof over bore too thin: ", cap_roof));
assert(stem_bot_z >= nut_top_z + 0.5, "cap stem hits the nut");
assert(driver_od <= well_id - 1, "nut driver too wide for well");
assert((nut_af + fit) / cos(30) <= driver_od - 2, "driver socket wall too thin");
