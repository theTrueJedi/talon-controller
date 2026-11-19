// Diffuser hood: upside-down-U annulus over the ring, in the face frame.
// Underside is one flat plane at z = 0 (key tabs included).
// Expects lib/params.scad and parts/face.scad (radial_box) included first.

module hood() {
    $fa = hood_fa;
    difference() {
        union() {
            // Outer wall and top annulus (rounded top outer corner if hood_round_r > 0).
            if (hood_round_r > 0) hood_round_shell();
            else {
                tube(hood_id / 2, hood_od / 2, 0, hood_top_z);
                tube(well_id / 2, hood_od / 2, hood_under_z, hood_top_z);
            }
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

// Outer wall + top annulus with a rounded top outer corner. The hood prints
// top face down, so the corner is the first thing off the bed: the arc
// (radius hood_round_r) runs from the wall to hood_round_angle from vertical,
// then a straight run at that angle meets the top face. Nothing is flatter
// than hood_round_angle from vertical, so it needs no support. The inside
// follows the same curve hood_wall in, so the wall keeps its thickness.
module hood_round_shell() {
    R = hood_round_r; a = hood_round_angle; t = hood_wall;
    ro = hood_od / 2; ri = hood_id / 2;
    c = [ro - R, hood_top_z - R];                        // arc centre
    arc = function(rad) [for (i = [0 : 24]) let(th = a * i / 24) c + rad * [cos(th), sin(th)]];
    // A straight run from point p, at angle a from vertical, inward until z.
    run_to = function(p, z) [p[0] - (z - p[1]) * tan(a), z];
    oa = arc(R);  ia = arc(R - t);
    rotate_extrude() difference() {
        polygon(concat([[well_id / 2, 0], [ro, 0]], oa,
                       [run_to(oa[len(oa) - 1], hood_top_z), [well_id / 2, hood_top_z]]));
        polygon(concat([[well_wall_or, -eps], [ri, -eps]], ia,
                       [run_to(ia[len(ia) - 1], hood_under_z), [well_wall_or, hood_under_z]]));
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
