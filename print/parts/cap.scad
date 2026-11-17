// Knob cap, in the face frame: stem in the hood well, disc above the hood.
// Expects lib/params.scad and parts/hood.scad (tube) included first.

module cap() {
    difference() {
        union() {
            translate([0, 0, cap_under_z])
                if (cap_knurl) knurled(cap_d, cap_top_z - cap_under_z) chamfered_disc();
                else chamfered_disc();
            translate([0, 0, stem_bot_z]) cylinder(d = stem_od, h = cap_under_z - stem_bot_z + eps);
        }
        // Collar counterbore: the stem bottom sits below the collar top; the
        // ceiling clears the collar even at full knob press.
        translate([0, 0, stem_bot_z - eps])
            cylinder(d = collar_d + shaft_clr, h = cap_cbore_top_z - stem_bot_z + eps);
        // Round clearance over the shaft's round section.
        translate([0, 0, stem_bot_z - eps])
            cylinder(d = shaft_d + shaft_clr, h = shaft_dsec_z - stem_bot_z + 2 * eps);
        // Blind D bore over the D section; flat faces +Y.
        translate([0, 0, shaft_dsec_z])
            linear_extrude(cap_bore_top_z - shaft_dsec_z) d_profile(shaft_d + fit, shaft_flat + fit);
    }
}

module chamfered_disc() {
    h = cap_top_z - cap_under_z;
    c = cap_chamfer;
    rotate_extrude() polygon([[0, 0], [cap_d / 2 - c, 0], [cap_d / 2, c],
                              [cap_d / 2, h - c], [cap_d / 2 - c, h], [0, h]]);
}

// D profile: circle of diameter d, cut by a flat at distance `across` from
// the far (round) side; the flat faces +Y.
module d_profile(d, across) {
    intersection() {
        circle(d = d);
        translate([-d / 2, -d / 2]) square([d, across]);
    }
}

// Cut knurl_n vertical flutes round the rim of the child (diameter d, height h).
module knurled(d, h) {
    difference() {
        children();
        for (i = [0 : knurl_n - 1])
            rotate([0, 0, i * 360 / knurl_n])
                translate([d / 2 + knurl_flute_d / 2 - knurl_depth, 0, -eps])
                    cylinder(d = knurl_flute_d, h = h + 2 * eps, $fn = 12);
    }
}
