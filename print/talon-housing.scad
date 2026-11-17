// Talon controller housing. Select a part with -D 'part="..."'.
include <lib/params.scad>
include <lib/checks.scad>
include <parts/face.scad>
include <parts/hood.scad>
include <parts/cap.scad>
include <parts/tools.scad>
include <parts/shell.scad>

part = "checks";

if (part == "checks") cube(1);   // checks ran above; emit something exportable
else if (part == "hood") {
    echo(hood_top_z = hood_top_z, hood_od = hood_od, key_tab_len = key_tab_len);
    // Print top-down: top annulus on the bed.
    translate([0, 0, hood_top_z]) rotate([180, 0, 0]) hood();
}
else if (part == "halo") {
    assert(halo_block, "part halo needs -D halo_block=true");
    halo_sleeve();
}
else if (part == "cap") {
    echo(cap_d = cap_d, cap_h = cap_h);
    // Print top-face down: cap top on the bed.
    translate([0, 0, cap_top_z]) rotate([180, 0, 0]) cap();
}
else if (part == "nut_driver") {
    // Print handle down: handle end on the bed, socket up.
    translate([0, 0, driver_shaft_l + driver_handle[1]]) rotate([180, 0, 0]) nut_driver();
}
else if (part == "fit_test") {
    echo(fit_footprint = fit_footprint);
    fit_coupon();
}
else if (part == "glow_test") {
    echo(glow_footprint = glow_footprint);
    glow_coupon();     // prints as modelled: legs on the bed, steps bridge between them
}
else if (part == "shell") {
    echo(box_footprint = box_footprint);
    echo(box_h = box_h, hood_od = hood_od, wall = wall);
    echo(c3_stop_gap = c3_stop_gap);
    echo(front_h = front_h, front_h_ky = front_h_ky, front_h_boss = front_h_boss,
         rear_d = rear_d, rear_d_c3 = rear_d_c3, ky_low_z = ky_low_z, c3_top_z = c3_top_z);
    // Print on its back wall: back outer face on the bed, open bottom to the side.
    translate([0, 0, box_d]) rotate([-90, 0, 0]) shell();
}
else if (part == "face") face_center(lip_or + wall);   // face-center preview
else assert(false, str("unknown part: ", part));
