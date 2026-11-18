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
module c3_pose() translate([c3_x, c3_edge_y, c3_z0]) rotate([0, 0, 180]) children();

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
// +Y for front bosses, -Y for rear. The nut sits on boss_floor of boss, held
// centred on the screw axis by a detent at the hex pocket mouth.
module boss_cuts() {
    for (p = boss_xy) translate([p[0], p[1], 0]) {
        s = boss_front(p) ? 1 : -1;
        translate([0, 0, -eps]) cylinder(d = m3_clear_d, h = boss_stack_h + eps);
        // Hex pocket plus entry channel, minus two detent bumps just past the
        // seated nut's flats: the nut snaps past them and stays on the screw axis.
        translate([0, 0, boss_floor]) difference() {
            union() {
                rotate([0, 0, 90]) cylinder(r = m3_nut_r, h = m3_trap_h, $fn = 6);
                translate([-m3_slot_w / 2, s > 0 ? 0 : -(boss_d + 1), 0])
                    cube([m3_slot_w, boss_d + 1, m3_trap_h]);
            }
            for (x = [-1, 1])
                translate([x * m3_slot_w / 2, s * (m3_nut_r / 2 + m3_detent), -eps])
                    cylinder(r = m3_detent, h = m3_trap_h + 2 * eps, $fn = 16);
        }
    }
}

// ---- C3-Zero cradle ----
// On the bottom plate (bottom() places it at c3_x), modelled centred on x = 0:
// a pedestal under the board and a front stop across its inner short edge,
// two side rails along the long edges (the wired-side one lowered behind the
// stop face so the header plugs pass over it), all ending c3_fit short of the back
// wall's inner face (c3_cradle_y1). Grooves in the pedestal under both pin
// rows clear the solder tails.
// The board's port edge sits in a back-wall slot, which takes the cable's
// pull; slot and USB notch are open at the rim, so the board fitted to the
// plate slides up into them as the plate goes on. The hold-down is a separate
// clip (c3_clip below): rail lips at the corners would sit on the
// GPIO5/GPIO6 pads. Fit: tilt the board, lay it on the pedestal against the
// stop, press the clip down over the rails until both barbs click into the
// rail notches. Remove: spread the clip legs, lift it off.
module c3_cradle() {
    back = c3_cradle_y1;
    difference() {
        union() {
            // Pedestal and front stop.
            translate([-c3_ped_hw, c3_stop_y, 0]) cube([2 * c3_ped_hw, back - c3_stop_y, c3_z0]);
            translate([-c3_ped_hw, c3_cradle_y0, 0]) cube([2 * c3_ped_hw, c3_stop_t, c3_top_h]);
            // Rails. The wired-side (-X) rail runs full height only in front
            // of the stop face (the clip's barb notch); behind it, it drops to
            // c3_rail_low_z so the header plugs pass over it.
            translate([c3_slot_hw, c3_cradle_y0, 0]) cube([c3_rail_t, back - c3_cradle_y0, c3_top_h]);
            translate([-c3_slot_hw - c3_rail_t, c3_cradle_y0, 0]) cube([c3_rail_t, c3_stop_y - c3_cradle_y0, c3_top_h]);
            translate([-c3_slot_hw - c3_rail_t, c3_cradle_y0, 0]) cube([c3_rail_t, back - c3_cradle_y0, c3_rail_low_z]);
        }
        // Solder-tail grooves under both pin rows, open to the sides, running
        // the board's full length.
        for (s = [-1, 1])
            translate([s > 0 ? c3[1] / 2 - c3_groove[0] : -c3_ped_hw - eps, c3_stop_y, c3_z0 - c3_groove[1]])
                cube([c3_ped_hw + eps - (c3[1] / 2 - c3_groove[0]), c3_edge_y - c3_stop_y + eps, c3_groove[1] + eps]);
        // Clip notches in the rails' outer faces, open at the front.
        for (s = [-1, 1])
            translate([s > 0 ? c3_cradle_hw - c3_clip_engage - c3_fit : -c3_cradle_hw - eps,
                       c3_cradle_y0 - eps, c3_clip_barb_z])
                cube([c3_clip_engage + c3_fit + eps, c3_clip_bar_y1 - c3_cradle_y0 + c3_fit + eps, c3_clip_barb_h + c3_fit]);
    }
}

// Clip, centred on x = 0 like the cradle (placed at c3_x in the assembly).
// Bar over the rail and stop tops (it stops at the stop face, clear of the
// corner holes), a leg down each rail's outer face with a barb (ramp below,
// flat catch on top) in the rail's notch, and two teeth c3_fit above the
// board's top on its inner short edge, either side of the chip antenna.
module c3_clip() {
    translate([0, c3_clip_bar_y1, 0]) rotate([90, 0, 0]) linear_extrude(c3_clip_bar_y1 - c3_clip_y0) {
        translate([-c3_clip_hw, c3_top_h]) square([2 * c3_clip_hw, c3_clip_t]);
        for (s = [-1, 1]) {
            translate([s > 0 ? c3_clip_leg_x : -c3_clip_hw, c3_clip_barb_z])
                square([c3_clip_t, c3_top_h - c3_clip_barb_z + eps]);
            polygon([[s * (c3_clip_leg_x + eps), c3_clip_barb_z],
                     [s * (c3_clip_leg_x + eps), c3_clip_barb_z + c3_clip_barb_h],
                     [s * (c3_clip_leg_x - c3_clip_barb), c3_clip_barb_z + c3_clip_barb_h]]);
        }
    }
    // Two teeth, either side of the chip antenna: the only parts over the
    // board; full clip height so they join the bar.
    for (s = [-1, 1]) translate([s > 0 ? c3_tooth_x0 : -c3_tooth_x1, c3_stop_y - eps, c3_lip_z])
        cube([c3_tooth_w, c3_lip_len + eps, c3_clip_top_z - c3_lip_z]);
}

// Back-wall cuts for the board, at c3_x. All open below the rim (z
// c3_back_cuts_z0) so the board on the plate slides straight up into them.
module c3_cuts() {
    slot_y = box_d - wall - eps;
    slot_d = c3_wall_slot + eps;
    // Header plug recess: the slot widened toward -X over the header and its
    // plugs' X span, up to the plugs' top, same depth.
    translate([c3_hdr_recess_x[0], slot_y, c3_back_cuts_z0])
        cube([c3_hdr_recess_x[1] - c3_hdr_recess_x[0], slot_d, c3_hdr_recess_z1 - c3_back_cuts_z0]);
    translate([c3_x, 0, 0]) c3_board_cuts(slot_y, slot_d);
}
module c3_board_cuts(slot_y, slot_d) {
    // Board edge slot into the back wall.
    translate([-c3_slot_hw, slot_y, c3_back_cuts_z0])
        cube([2 * c3_slot_hw, slot_d, c3_z0 + c3[2] + c3_fit - c3_back_cuts_z0]);
    // USB plug notch: rounded top corners, centred on the port, open at the rim.
    translate([0, box_d + eps, 0]) rotate([90, 0, 0])
        linear_extrude(wall + 2 * eps) {
            translate([0, c3_port_z]) offset(r = usb_hole_r) offset(delta = -usb_hole_r)
                square(usb_plug_hole, center = true);
            translate([-usb_plug_hole[0] / 2, c3_back_cuts_z0]) square([usb_plug_hole[0], c3_port_z - c3_back_cuts_z0]);
        }
}

// ---- Cable channel ----
// Two ribs flanking the wire slot's width, following the inside ceiling from
// the slot up the face, along the top and down the back wall. It runs at the
// wire slot's x (cable_ch_x, near the middle), not over the USB notch at c3_x,
// and stops at cable_ch_z0 (the notch's top height plus a wall).
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
            cable_channel();
            face_pose() face_center_solid(lip_or);
        }
        face_pose() face_center_cuts();
        boss_cuts();
        c3_cuts();
    }
}
