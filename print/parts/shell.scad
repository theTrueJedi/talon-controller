// Shell: the opaque wedge, open at the bottom, modelled in the BOX FRAME
// (see params.scad, "Derived (box frame)").
// Expects lib/params.scad and parts/face.scad included first.
//
// Profile (YZ): a front wall front_h tall, the face rising at `slope` for
// face_len, a flat top rear_d deep, a vertical back wall. Outer edges are
// filleted fillet_r except the bottom rim. Inside, the front wall is a 45
// degree ramp, so the shell prints on its back wall with no supports there.

// ---- Poses: Task 6 places parts and ghosts with these ----

// Face frame -> box frame. Children modelled in the face frame (origin on the
// shaft axis at the face top, +Z out along the shaft, +Y up-slope) land on
// the slope. face_to_box(p) does the same for a point.
module face_pose() translate(face_origin) rotate([slope, 0, 0]) children();

// KY-040 frame -> box frame. KY frame: the face frame shifted down the shaft
// to the KY-040 PCB top (the spec's datum). PCB: x ky_x_range, y from
// ky_y_range[0] to ky_shaft_from_header_edge, z -ky_pcb[2]..0. Encoder body
// centred on the shaft, z 0..body[2].
module ky_pose() face_pose() translate([0, 0, ky_pcb_top_z]) children();

// C3-Zero frame -> box frame. C3 frame: origin at the centre of the port
// edge on the PCB underside; +Y into the board (24), +X across (18.05), +Z
// to the component side. Port: x +-usb_port[0]/2, z c3[2]..c3[2]+usb_port[1],
// mouth at y = 0. Pose = board seated in its back-wall slot (unplugged);
// plugging in can push it c3_stop_gap further in, onto the front stop.
module c3_pose() translate([0, c3_edge_y, c3_z0]) rotate([0, 0, 180]) children();

// ---- Profiles (2D, x = box y, y = box z) ----
shell_zb = -(fillet_r + 1);                     // below the rim; cut off / left open
shell_ri = fillet_r - wall;                     // inside corner radius
shell_z1 = slope_under_z(wall);                 // face underside at the front wall
shell_yc = (box_h - wall - front_h + face_t / cos(slope)) / tan(slope);

function outer_profile() = [[0, shell_zb], [0, front_h], [face_run, box_h],
                            [box_d, box_h], [box_d, shell_zb]];
function inner_profile() = [[wall + shell_z1 - shell_zb, shell_zb], [wall, shell_z1],
                            [shell_yc, box_h - wall], [box_d - wall, box_h - wall],
                            [box_d - wall, shell_zb]];

// Convex profile extruded across X, edges rounded r by a sphere.
module rounded_prism(profile, w, r) {
    minkowski() {
        translate([-(w / 2 - r), 0, 0]) rotate([90, 0, 90])
            linear_extrude(w - 2 * r) offset(delta = -r) polygon(profile);
        sphere(r = r);
    }
}

module shell_outer() {
    intersection() {
        rounded_prism(outer_profile(), box_w, fillet_r);
        translate([-box_w, -box_d, 0]) cube([2 * box_w, 3 * box_d, 2 * box_h]);
    }
}

module shell_inner() rounded_prism(inner_profile(), box_w - 2 * wall, shell_ri);

// ---- Corner bosses ----
// Front bosses are teardrops (45 degree tip toward +Y): printed on the back
// wall, +Y is down. Rear bosses run flat into the back wall.
function boss_front(p) = p[1] < box_d / 2;

module boss_footprint(p) {
    s = boss_front(p) ? -1 : 1;                 // toward the near (front/back) wall
    hull() {
        translate(p) circle(d = boss_d);
        translate([p[0] - boss_d / 2, s > 0 ? p[1] : wall - eps])
            square([boss_d, boss_c - wall + eps]);
        if (boss_front(p)) translate([p[0], p[1] + boss_d / 2 * sqrt(2)]) square(eps, center = true);
    }
}

module bosses() {
    intersection() {
        shell_outer();
        for (p = boss_xy) linear_extrude(box_h) boss_footprint(p);
    }
}

// M3 clearance hole (blind) and a side-entry nut slot opening into the box:
// +Y for front bosses, -Y for rear. The nut sits on boss_floor of boss.
module boss_cuts() {
    for (p = boss_xy) translate([p[0], p[1], 0]) {
        s = boss_front(p) ? 1 : -1;
        translate([0, 0, -eps]) cylinder(d = m3_clear_d, h = boss_stack_h + eps);
        translate([0, 0, boss_floor]) {
            rotate([0, 0, 90]) cylinder(r = m3_nut_r, h = m3_trap_h, $fn = 6);
            translate([-(m3_nut_af + fit) / 2, s > 0 ? 0 : -(boss_d + 1), 0])
                cube([m3_nut_af + fit, boss_d + 1, m3_trap_h]);
        }
    }
}

// ---- C3-Zero cradle ----
// Pedestal under the board and a front stop across its inner short edge,
// both fixed to the back wall. Two rails along the long edges hang off the
// back wall only, so they flex outward; their lips hook the board's top at
// the inner-end corners. Board's port edge sits in a slot in the back wall,
// which takes the cable's pull. Fit: tilt the board, slide the port edge into
// the wall slot, press the inner end down past the lips. Remove: spread the
// rails, lift the inner end.
c3_slot_hw = (c3[1] + fit) / 2;                 // board slot half width (rail inner face)
c3_ped_hw = c3_slot_hw - c3_rail_gap;
c3_top_h = c3_lip_z + c3_lip_h;                 // rail and stop top

module c3_cradle() {
    back = box_d - wall + eps;
    // Pedestal and front stop.
    translate([-c3_ped_hw, c3_stop_y, 0]) cube([2 * c3_ped_hw, back - c3_stop_y, c3_z0]);
    translate([-c3_ped_hw, c3_stop_y - c3_stop_t, 0]) cube([2 * c3_ped_hw, c3_stop_t, c3_top_h]);
    for (s = [-1, 1]) {
        // Rail.
        translate([s > 0 ? c3_slot_hw : -c3_slot_hw - c3_rail_t, c3_stop_y - c3_stop_t, 0])
            cube([c3_rail_t, back - (c3_stop_y - c3_stop_t), c3_top_h]);
        // Lip: flat underside over the board, sloped top as the lead-in.
        translate([0, c3_stop_y + c3_lip_len, 0]) rotate([90, 0, 0])
            linear_extrude(c3_lip_len)
                polygon([[s * (c3_slot_hw + eps), c3_lip_z], [s * (c3_slot_hw - c3_lip), c3_lip_z],
                         [s * (c3_slot_hw + eps), c3_top_h]]);
    }
}

module c3_cuts() {
    // Board edge slot into the back wall.
    translate([-c3_slot_hw, box_d - wall - eps, c3_z0])
        cube([2 * c3_slot_hw, c3_edge_y - (box_d - wall) + eps, c3[2] + fit]);
    // USB plug hole, rounded, centred on the port.
    translate([0, box_d + eps, c3_port_z]) rotate([90, 0, 0])
        linear_extrude(wall + 2 * eps)
            offset(r = usb_hole_r) offset(delta = -usb_hole_r)
                square(usb_plug_hole, center = true);
}

// ---- Cable channel ----
// Two ribs flanking the wire slot's width, following the inside ceiling from
// the slot up the face, along the top and down the back wall to above the
// plug hole.
module cable_channel() {
    for (s = [-1, 1])
        translate([cable_ch_x + s * (wire_slot[0] / 2 + cable_rib[0] / 2) - cable_rib[0] / 2, 0, 0])
            rotate([90, 0, 90]) linear_extrude(cable_rib[0])
                intersection() {
                    difference() {
                        polygon(inner_profile());
                        offset(delta = -cable_rib[1]) polygon(inner_profile());
                    }
                    translate([cable_ch_y0, cable_ch_z0]) square([box_d, box_h]);
                }
}

module shell() {
    difference() {
        union() {
            difference() {
                shell_outer();
                shell_inner();
            }
            bosses();
            c3_cradle();
            cable_channel();
            face_pose() face_center_solid(lip_or);
        }
        face_pose() face_center_cuts();
        boss_cuts();
        c3_cuts();
    }
}
