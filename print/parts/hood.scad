// Diffuser hood: upside-down-U annulus over the ring, in the face frame.
// Underside is one flat plane at z = 0 (key tabs included).
// Expects lib/params.scad and parts/face.scad (radial_box) included first.

module hood() {
    difference() {
        union() {
            // Outer wall.
            tube(hood_id / 2, hood_od / 2, 0, hood_top_z);
            // Top annulus.
            tube(well_id / 2, hood_od / 2, hood_under_z, hood_top_z);
            // Inner (well) wall.
            tube(well_id / 2, well_wall_or, 0, hood_top_z);
            // Well floor.
            cylinder(r = well_id / 2 + eps, h = floor_t);
            // Key tabs, outward from the outer wall into the lip notches.
            for (a = key_tab_angles)
                radial_box(a, hood_od / 2 - eps, [key_tab_w, key_tab_len + eps, lip_h], 0);
            // M2 fallback bosses on the outer wall, clear of the ring.
            if (hood_screws)
                for (a = hood_screw_angles)
                    rotate([0, 0, a]) translate([0, hood_screw_r, 0])
                        cylinder(d = m2_boss_d, h = hood_top_z);
        }
        translate([0, 0, -eps]) cylinder(d = collar_hole_d, h = floor_t + 2 * eps);
        if (hood_screws)
            for (a = hood_screw_angles)
                rotate([0, 0, a]) translate([0, hood_screw_r, -eps])
                    cylinder(d = m2_pilot_d, h = m2_pilot_depth + eps);
    }
}

// Opaque sleeve over the outside of the well wall; blanks the well halo.
module halo_sleeve() {
    tube(halo_ir, halo_ir + halo_t, 0, hood_under_z);
}

module tube(ri, ro, z0, z1) {
    translate([0, 0, z0]) difference() {
        cylinder(r = ro, h = z1 - z0);
        translate([0, 0, -eps]) cylinder(r = ri, h = z1 - z0 + 2 * eps);
    }
}
