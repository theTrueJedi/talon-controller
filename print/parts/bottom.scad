// Bottom plate and TPU feet, in the BOX FRAME (see params.scad, "Derived
// (box frame)"). The plate spans z = -plate_t .. 0; its top (inside) face
// meets the shell's open rim at z = 0.
// Expects lib/params.scad included first.

// Shell footprint (plan corners rounded fillet_r), inset `plate_fit`.
module plate_outline() {
    offset(delta = -plate_fit) offset(r = fillet_r) offset(delta = -fillet_r)
        translate([-box_w / 2, 0]) square(box_footprint);
}

module bottom() {
    difference() {
        translate([0, 0, -plate_t]) linear_extrude(plate_t) plate_outline();
        // Weight pockets on the inside face, exactly weight-sized (the
        // adhesive backing is already in `weight`).
        for (i = [0 : weight_count - 1])
            translate([weight_xy(i)[0], weight_xy(i)[1], -weight[2]])
                cube([weight[0], weight[1], weight[2] + eps]);
        // M3 through holes, counterbored from below for the screw heads.
        for (p = boss_xy) translate([p[0], p[1], -plate_t - eps]) {
            cylinder(d = m3_clear_d, h = plate_t + 2 * eps);
            cylinder(d = m3_cbore_d, h = m3_cbore_h + eps);
        }
        // Foot recesses on the outside face.
        for (p = foot_xy) translate([p[0], p[1], -plate_t - eps])
            cylinder(r = foot_recess_r, h = foot_recess + eps);
    }
}

// TPU foot: a disc, foot_recess of it sits in the plate's recess.
module foot() cylinder(d = foot_d, h = foot_h);
