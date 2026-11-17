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

// Knob press: every Z gap between the cap and a fixed part must exceed the
// switch travel, or the cap bottoms out before the switch clicks.
assert(cap_float > press_travel,
       str("cap_float gap (cap underside to hood top) <= press_travel: ", cap_float));
assert(cap_cbore_top_z - collar_top_z > press_travel,
       str("collar counterbore gap <= press_travel: ", cap_cbore_top_z - collar_top_z));
assert(stem_bot_z - nut_top_z > press_travel,
       str("stem-to-nut gap <= press_travel: ", stem_bot_z - nut_top_z));

// Test coupons.
assert(norm(ky_far_hole_xy) + pin_d / 2 < coupon_split_r, "fit coupon split cuts the anti-rotation pin");
assert(coupon_split_r < lip_ir - 1, "fit coupon split cuts the seat lip");
glow_band_need = (ring_od - ring_id) / 2
               + ring_od / 2 - sqrt(pow(ring_od / 2, 2) - pow(glow_step_l / 2, 2));
assert(glow_strip[1] - 2 * glow_leg_w >= glow_band_need,
       str("glow legs land on the ring band: need ", glow_band_need, " between them"));
assert(glow_digit_size + 1 <= ring_t + min(glow_steps), "glow digits taller than the lowest leg");
assert(glow_digit_depth > 0, "glow digits must be embossed, not cut");

// Shell.
assert(fillet_r > wall, "fillet_r must exceed wall (inside corners round at fillet_r - wall)");
assert(face_half - fillet_r >= lip_or, "face_len too short: hood seat lip runs into the edge fillet");
assert(c3_wall_slot < wall, "C3 wall slot cuts through the back wall: nothing stops a cable pull");
assert(c3_stop_gap <= 0.3, str("C3 front stop too far from the board: ", c3_stop_gap));
assert(ky_low_z >= c3_top_z + clr, str("KY-040 hangs onto the C3-Zero: ", ky_low_z));
assert(top_flat_min > 0, "top_flat_min must be > 0 (flat-topped rear)");
assert(pin_bot_z < ky_pcb_bottom_z, str("anti-rotation pin stops short of the KY-040 PCB bottom: ", pin_bot_z));
assert(m3_detent > 0 && m3_detent < (m3_nut_af + fit) / 4, str("nut detent must be > 0 and small: ", m3_detent));
