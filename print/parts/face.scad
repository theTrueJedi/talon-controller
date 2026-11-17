// Face center: the face plate around the knob, in the face frame.
// Expects lib/params.scad to be included by the caller.

// A box of size s, centred tangentially, starting at radius r0 along +Y,
// then rotated to angle a about +Z (0 = +Y).
module radial_box(a, r0, s, z0) {
    rotate([0, 0, a]) translate([-s[0] / 2, r0, z0]) cube(s);
}

module face_center(r) {
    assert(r >= lip_or, str("face_center radius ", r, " < lip outer ", lip_or));
    difference() {
        face_center_solid(r);
        face_center_cuts();
    }
}

// Solids only: disc, seat lip, anti-rotation pin. The shell unions this into
// its own face plate, then subtracts face_center_cuts().
module face_center_solid(r) {
    translate([0, 0, -face_t]) cylinder(r = r, h = face_t);
    // Hood seat lip, just outside the hood outer wall.
    difference() {
        cylinder(r = lip_or, h = lip_h);
        translate([0, 0, -eps]) cylinder(r = lip_ir, h = lip_h + 2 * eps);
    }
    // Anti-rotation pin through the far KY-040 hole, tip pin_through past the PCB.
    translate([ky_far_hole_xy[0], ky_far_hole_xy[1], pin_bot_z])
        cylinder(d = pin_d, h = pin_len + eps);
}

// Holes and notches through the face center.
module face_center_cuts() {
    // Collar hole.
    translate([0, 0, -face_t - eps]) cylinder(d = collar_hole_d, h = face_t + 2 * eps);
    // Key notches through the seat lip for the hood's tabs. Start inside the
    // hood-to-lip gap: the lip's faceted inner wall dips below lip_ir.
    for (a = key_tab_angles)
        radial_box(a, hood_od / 2, [key_tab_w + 2 * fit, lip_or - hood_od / 2 + eps, lip_h + 2 * eps], -eps);
    // Ring wire slot, through the face under the ring band.
    radial_box(wire_slot_angle, wire_slot_r - wire_slot[1] / 2,
               [wire_slot[0], wire_slot[1], face_t + 2 * eps], -face_t - eps);
    // M2 fallback: clearance holes, and lip notches for the bosses.
    if (hood_screws)
        for (a = hood_screw_angles) rotate([0, 0, a]) translate([0, hood_screw_r, 0]) {
            translate([0, 0, -face_t - eps]) cylinder(d = m2_clear_d, h = face_t + 2 * eps);
            translate([0, 0, -eps]) cylinder(d = m2_boss_d + 2 * fit, h = lip_h + 2 * eps);
        }
}
