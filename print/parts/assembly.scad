// Assembly preview and interference check, in the BOX FRAME.
// Expects every other part file included first (params, face, hood, cap,
// tools, shell, bottom).
//
// Ghosts are the bought parts, modelled from params.scad: LED ring, KY-040
// (PCB with its two holes, body, collar, shaft), ESP32-C3-Zero (PCB, USB-C
// port), encoder nut and washer, M3 screws, weights.

face_n = [0, -sin(slope), cos(slope)];          // face normal (face frame +Z), box frame

// ---- Ghosts, each in its own frame ----
module ring_ghost() tube(ring_id / 2, ring_od / 2, 0, ring_t);            // face frame

module ky_ghost() {                                                       // KY frame
    difference() {
        translate([ky_x_range[0], ky_y_range[0], -ky_pcb[2]]) cube([ky_pcb[1], ky_pcb[0], ky_pcb[2]]);
        for (h = [ky_far_hole_xy, ky_near_hole_xy])
            translate([h[0], h[1], -ky_pcb[2] - eps]) cylinder(d = ky_hole_d, h = ky_pcb[2] + 2 * eps);
    }
    translate([-body[0] / 2, -body[1] / 2, 0]) cube(body);
    translate([0, 0, body[2]]) cylinder(d = collar_d, h = collar_h);
    // Shaft, in face-frame heights shifted to the KY frame.
    translate([0, 0, collar_top_z - ky_pcb_top_z]) cylinder(d = shaft_d, h = shaft_dsec_z - collar_top_z);
    translate([0, 0, shaft_dsec_z - ky_pcb_top_z]) linear_extrude(shaft_d_h) d_profile(shaft_d, shaft_flat);
}

module c3_ghost() {                                                       // C3 frame
    translate([-c3[1] / 2, 0, 0]) cube([c3[1], c3[0], c3[2]]);
    translate([-usb_port[0] / 2, 0, c3[2]]) cube([usb_port[0], c3_port_len, usb_port[1]]);
}

module washer_ghost() tube(collar_d / 2, washer_od / 2, floor_t, floor_t + washer_t);   // face frame

module nut_ghost() {                                                      // face frame
    translate([0, 0, floor_t + washer_t]) difference() {
        cylinder(d = nut_corner, h = nut_t, $fn = 6);
        translate([0, 0, -eps]) cylinder(d = collar_d, h = nut_t + 2 * eps);
    }
}

// Screw head seated on the counterbore ceiling, shank up into the boss nut.
module screws_ghost() {                                                   // box frame
    for (p = boss_xy) translate([p[0], p[1], -plate_t + m3_cbore_h]) {
        translate([0, 0, -m3_head[1]]) cylinder(d = m3_head[0], h = m3_head[1]);
        cylinder(d = m3_d, h = m3_screw_l);
    }
}

module weights_ghost() {                                                  // box frame
    for (i = [0 : weight_count - 1])
        translate([weight_xy(i)[0], weight_xy(i)[1], -weight[2]]) cube(weight);
}

module feet_placed() {                                                    // box frame
    for (p = foot_xy) translate([p[0], p[1], -plate_t - (foot_h - foot_recess)]) foot();
}

// ---- Items, placed in the box frame ----
// 0 shell, 1 bottom, 2 hood, 3 cap, 4 feet, 5 ring, 6 KY-040, 7 C3-Zero,
// 8 washer, 9 nut, 10 screws, 11 weights, 12 C3 clip.
item_n = 13;
module item(i) {
    if (i == 0) shell();
    else if (i == 1) bottom();
    else if (i == 2) face_pose() hood();
    else if (i == 3) face_pose() cap();
    else if (i == 4) feet_placed();
    else if (i == 5) face_pose() ring_ghost();
    else if (i == 6) ky_pose() ky_ghost();
    else if (i == 7) c3_pose() c3_ghost();
    else if (i == 8) face_pose() washer_ghost();
    else if (i == 9) face_pose() nut_ghost();
    else if (i == 10) screws_ghost();
    else if (i == 11) weights_ghost();
    else if (i == 12) c3_clip();
}

module assembly() {
    color("dimgray") item(0);
    color("slategray") item(1);
    color("white", 0.5) item(2);
    color("black") item(3);
    color("darkred") item(4);
    color("lime") item(5);
    color("royalblue") item(6);
    color("teal") item(7);
    color("silver") { item(8); item(9); item(10); }
    color("gold") item(11);
    color("dimgray") item(12);
}

// ---- Interference ----
// Intended face contacts: item j is moved eps off item i along the contact
// normal before intersecting, so only a real overlap survives.
interference_contacts = [
    [0, 1, [0, 0, -eps]],               // shell rim, bosses, cradle on the plate top
    [0, 2, face_n * eps],               // hood (walls, well floor, key tabs) on the face top
    [0, 5, face_n * eps],               // ring on the face top
    [0, 6, -face_n * eps],              // KY-040 body top against the face underside
    [0, 7, [0, -eps, eps]],             // C3-Zero on its pedestal, port edge at the wall-slot end
    [0, 11, [0, 0, -eps]],              // weights flush with the plate top, under the front ramp
    [0, 12, [0, eps, eps]],             // C3 clip bar on the rail/stop tops, tongue against the stop face
    [1, 4, [0, 0, -eps]],               // foot against its recess ceiling
    [1, 10, [0, 0, -eps]],              // screw head against its counterbore ceiling
    [2, 8, face_n * eps],               // washer on the well floor
    [8, 9, face_n * eps],               // nut on the washer
];
// Pairs left out entirely (contact is the design, not a fault).
interference_omit = [
    [1, 11],                            // weights in exact-size pockets (no clearance by spec)
    [6, 8], [6, 9],                     // washer and nut on the encoder collar thread
];

function contact_shift(i, j) = let(m = [for (c = interference_contacts) if (c[0] == i && c[1] == j) c[2]])
    len(m) > 0 ? m[0] : [0, 0, 0];
function omitted(i, j) = len([for (o = interference_omit) if (o == [i, j]) 1]) > 0;

module interference() {
    for (i = [0 : item_n - 2], j = [i + 1 : item_n - 1])
        if (!omitted(i, j))
            intersection() {
                item(i);
                translate(contact_shift(i, j)) item(j);
            }
}
