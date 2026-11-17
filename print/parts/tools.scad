// Nut driver for the encoder nut, through the hood well.
// Own frame: socket open end at z = 0 (rests on the washer), handle on top.
// Expects lib/params.scad and parts/cap.scad (knurled) included first.

module nut_driver() {
    hd = driver_handle[0];
    hh = driver_handle[1];
    difference() {
        union() {
            cylinder(d = driver_od, h = driver_shaft_l + eps);
            translate([0, 0, driver_shaft_l])
                knurled(hd, hh) cylinder(d = hd, h = hh);
        }
        // Hex socket, nut_af + fit across flats.
        translate([0, 0, -eps])
            cylinder(d = (nut_af + fit) / cos(30), h = socket_depth + eps, $fn = 6);
        // Through-bore slides over the collar and shaft.
        translate([0, 0, -eps])
            cylinder(d = collar_d + shaft_clr, h = driver_shaft_l + hh + 2 * eps);
    }
}
