// Assembly preview and interference check, in the BOX FRAME.
// Expects every other part file included first (params, face, hood, cap,
// tools, shell, bottom).
//
// Ghosts are the bought parts, modelled from params.scad: LED ring, KY-040
// (PCB with its two holes, body, collar, shaft), ESP32-C3-Zero (PCB, USB-C
// port), the C3's right-angle header with its jumper plugs, the KY-040's
// clipped stubs and solder joints, encoder nut and washer, M3 screws, weights.

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

// Header plastic on the board top along the wired pin row, plus one envelope
// for the mated plugs and their wire room, out past the board's edge.
module c3_hdr_ghost() {                                                   // C3 frame
    l = c3_hdr_n * hdr_pitch;
    translate([c3_hdr_x - hdr_pitch / 2, c3_hdr_y0, c3[2]]) cube([hdr_pitch, l, hdr_body_h]);
    translate([c3[1] / 2, c3_hdr_y0, c3_hdr_env_z[0]]) cube([plug_env_len, l, plug[1]]);
}

// Clipped header stubs, solder joints and wire bends, out +Y from the PCB's
// header edge, about the PCB mid-plane.
module ky_hdr_ghost() {                                                   // KY frame
    w = ky_hdr_n * hdr_pitch;
    translate([(ky_x_range[0] + ky_x_range[1] - w) / 2, ky_shaft_from_header_edge, -ky_pcb[2] / 2 - ky_stub_h])
        cube([w, ky_stub_room, 2 * ky_stub_h]);
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

// USB-C cable plug body (Evan's larger cable), pushed home: from the port
// mouth (the board's edge) out through the back-wall notch. Corners rounded
// usb_hole_r like the notch's (assumed: overmolds are rounded; unmeasured).
module usb_plug_ghost() {                                                 // box frame
    translate([c3_x, c3_edge_y, c3_port_z]) rotate([-90, 0, 0])
        linear_extrude(box_d + 5 - c3_edge_y)
            offset(r = usb_hole_r) offset(delta = -usb_hole_r) square(usb_plug, center = true);
}

module weights_ghost() {                                                  // box frame
    for (i = [0 : len(weight_pockets) - 1]) let(r = weight_rect(i))
        translate([r[0][0], r[0][1], weight_z0]) cube([r[1][0] - r[0][0], r[1][1] - r[0][1], weight[2]]);
}

module feet_placed() {                                                    // box frame
    for (s = [-1, 1]) translate([s * pad_x, box_d / 2, -plate_t - (pad[2] - pad_recess)]) pad_ghost();
}

// ---- Items, placed in the box frame ----
// 0 shell, 1 bottom, 2 hood, 3 cap, 4 feet, 5 ring, 6 KY-040, 7 C3-Zero,
// 8 washer, 9 nut, 10 screws, 11 weights, 12 C3 clip, 13 C3 header and plugs,
// 14 KY-040 stubs and solder joints, 15 USB-C plug body.
item_n = 16;
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
    else if (i == 12) translate([c3_x, 0, 0]) c3_clip();
    else if (i == 13) c3_pose() c3_hdr_ghost();
    else if (i == 14) ky_pose() ky_hdr_ghost();
    else if (i == 15) usb_plug_ghost();
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
    color("orange") { item(13); item(14); }
}

// ---- Interference ----
// Intended face contacts: item j is moved eps off item i along the contact
// normal before intersecting, so only a real overlap survives.
interference_contacts = [
    [0, 1, [0, 0, -eps]],               // shell rim and bosses on the plate top
    [0, 2, face_n * eps],               // hood (walls, well floor, key tabs) on the face top
    [0, 5, face_n * eps],               // ring on the face top
    [0, 6, -face_n * eps],              // KY-040 body top against the face underside
    [0, 7, [0, -eps, 0]],               // C3-Zero port edge toward the wall-slot end (c3_slot_clr short)
    [1, 4, [0, 0, -eps]],               // TPU pad against its recess ceiling
    [1, 7, [0, 0, eps]],                // C3-Zero on the plate cradle's pedestal
    [1, 10, [0, 0, -eps]],              // screw head against its counterbore ceiling
    [1, 12, [0, eps, eps]],             // C3 clip bar on the rail/stop tops, teeth against the stop face
    [6, 14, [0, cos(slope), sin(slope)] * eps],  // KY-040 stubs off the header edge (KY frame +Y)
    [7, 13, [0, 0, eps]],               // C3 header plastic on the board top
    [7, 15, [0, eps, 0]],               // USB plug body against the port mouth (board edge)
    [2, 8, face_n * eps],               // washer on the well floor
    [8, 9, face_n * eps],               // nut on the washer
];
// Pairs left out entirely (contact is the design, not a fault).
interference_omit = [
    [1, 11],                            // weights sealed in exact-size pockets (no clearance by spec)
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
