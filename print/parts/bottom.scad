// Bottom plate, in the BOX FRAME (see params.scad, "Derived
// (box frame)"). The plate spans z = -plate_t .. 0; its top (inside) face
// meets the shell's open rim at z = 0. The C3-Zero cradle stands on it.
// Expects lib/params.scad and parts/shell.scad (c3_cradle) included first.

// Shell footprint (plan corners rounded fillet_r), inset `plate_fit`.
module plate_outline() {
    offset(delta = -plate_fit) offset(r = fillet_r) offset(delta = -fillet_r)
        translate([-box_w / 2, 0]) square(box_footprint);
}

module bottom() {
    difference() {
        translate([0, 0, -plate_t]) linear_extrude(plate_t) plate_outline();
        // Weight pockets, sealed under weight_roof (print pauses at
        // weight_pause_z to drop them in), exactly weight-sized (the adhesive
        // backing is already in `weight`).
        for (i = [0 : len(weight_pockets) - 1]) let(r = weight_rect(i))
            translate([r[0][0], r[0][1], weight_z0]) cube([r[1][0] - r[0][0], r[1][1] - r[0][1], weight[2]]);
        // M3 through holes, counterbored from below for the screw heads.
        for (p = boss_xy) translate([p[0], p[1], -plate_t - eps]) {
            cylinder(d = m3_clear_d, h = plate_t + 2 * eps);
            cylinder(d = m3_cbore_d, h = m3_cbore_h + eps);
        }
        // TPU pad recesses on the outside face.
        for (s = [-1, 1]) let(r = pad_rect(s)) translate([r[0][0], r[0][1], -plate_t - eps])
            cube([pad_rec[0], pad_rec[1], pad_recess + eps]);
    }
    // C3-Zero cradle on the plate top.
    translate([c3_x, 0, 0]) c3_cradle();
    plate_lip();
    port_filler();
}

// Lip cross-section: d inward from the outer face, z up; outer top edge chamfered.
function lip_profile() = [[0, 0], [plate_lip_t, 0], [plate_lip_t, plate_lip_h], [plate_lip_chamfer, plate_lip_h], [0, plate_lip_h - plate_lip_chamfer]];

module plate_lip() {
    // Side lips, extruded along Y.
    for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0])
        translate([0, lip_side_y[1], 0]) rotate([90, 0, 0]) linear_extrude(lip_side_y[1] - lip_side_y[0])
            polygon([for (p = lip_profile()) [lip_side_xo - p[0], p[1]]]);
    // Front lip, extruded along X: the front face leans forward at 45 degrees,
    // parallel to the inside ramp, so the whole face seats.
    translate([-lip_front_hw, 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * lip_front_hw)
        polygon([[lip_front_c, 0], [lip_front_c + plate_lip_t, 0], [lip_front_c + plate_lip_t, plate_lip_h], [lip_front_c - plate_lip_h, plate_lip_h]]);
}

module port_filler() translate([c3_x - c3_filler_hw, 0, 0]) {
    // Under the board, ending c3_fit short of the port mouth (the plug body's face).
    translate([0, c3_cradle_y1 - eps, 0]) cube([2 * c3_filler_hw, c3_edge_y - c3_fit - c3_cradle_y1 + eps, c3_z0]);
    translate([0, c3_edge_y - c3_fit - eps, 0]) cube([2 * c3_filler_hw, box_d - c3_edge_y + eps, c3_filler_low_z]);
}

// TPU pad (bought/pre-printed; a ghost for the assembly), centred in its recess.
module pad_ghost() translate([-pad[0] / 2, -pad[1] / 2, 0]) cube(pad);
