// Talon controller housing. Select a part with -D 'part="..."'.
include <lib/params.scad>
include <lib/checks.scad>
include <parts/face.scad>
include <parts/hood.scad>
include <parts/cap.scad>
include <parts/tools.scad>
include <parts/shell.scad>
include <parts/bottom.scad>
include <parts/assembly.scad>

part = "checks";
probe = "";                       // part="shell_probe" only: which box (tests)

// Test-only: boxes the shell must miss, [[x0, y0, z0], [x1, y1, z1]] in the box frame.
function shell_probe_box(name) =
    // Rim strips inside the back-wall cuts: the plate comes off downward.
    // Each runs the cut's full height (the notch up to where its top corners
    // round), so a ledge anywhere inside a cut is caught.
    name == "c3_notch" ? [[c3_x - usb_plug_hole[0] / 2 + 0.1, box_d - wall + 0.05, 0],
                          [c3_x + usb_plug_hole[0] / 2 - 0.1, box_d - 0.05,
                           c3_port_z + usb_plug_hole[1] / 2 - usb_hole_r - 0.1]] :
    name == "c3_slot"  ? [[c3_x - c3_slot_hw + 0.1, box_d - wall + 0.05, 0],
                          [c3_x + c3_slot_hw - 0.1, c3_edge_y - 0.05, c3_z0 + c3[2] - 0.1]] :
    name == "c3_recess" ? [[c3_hdr_recess_x[0] + 0.1, box_d - wall + 0.05, 0],
                           [c3_hdr_recess_x[1] - 0.1, c3_edge_y - 0.05, c3_hdr_recess_z1 - 0.1]] :
    // The cradle's whole volume: it belongs to the plate.
    name == "c3_cradle" ? [[c3_x - c3_cradle_hw, c3_cradle_y0, 0], [c3_x + c3_cradle_hw, c3_cradle_y1, c3_top_h]] :
    assert(false, str("unknown probe: ", name));

// Test-only: boxes the bottom plate must reach (lip segments, port filler), box frame.
function bottom_probe_box(name) =
    let(xo = box_w / 2 - wall - lip_fit, ym = box_d / 2)
    name == "lip_left"  ? [[-xo + 0.1, ym - 1, 0.5], [-xo + 0.5, ym + 1, 1.2]] :
    name == "lip_right" ? [[xo - 0.5, ym - 1, 0.5], [xo - 0.1, ym + 1, 1.2]] :
    name == "lip_front" ? [[-1, lip_front_c + 0.3, 0.2], [1, lip_front_c + 0.8, 0.6]] :
    name == "back_stop" ? [[c3_x + c3_cradle_hw - 0.5, box_d - wall - lip_fit - 0.3, 0.5], [c3_x + c3_cradle_hw - 0.1, box_d - wall - lip_fit - 0.05, 1.2]] :
    name == "pad"       ? [[pad_x - 1, box_d / 2 - 1, -plate_t + 0.05], [pad_x + 1, box_d / 2 + 1, -plate_t + 0.25]] :
    // Over the board's top, 0.4 mm in from its port edge, beside the USB port.
    name == "hook_left"  ? [[c3_x - c3_hook_x1 + 0.2, c3_edge_y - 0.6, c3_z0 + c3[2] + c3_pinch_fit + 0.1], [c3_x - c3_hook_x0 - 0.2, c3_edge_y - 0.2, c3_hook_top_z - 0.1]] :
    name == "hook_right" ? [[c3_x + c3_hook_x0 + 0.2, c3_edge_y - 0.6, c3_z0 + c3[2] + c3_pinch_fit + 0.1], [c3_x + c3_hook_x1 - 0.2, c3_edge_y - 0.2, c3_hook_top_z - 0.1]] :
    // Over both port-end corner pins: must stay open.
    name == "pin_clear"  ? [[c3_x - c3_hdr_x - 0.6, c3_edge_y - c3_hole_end - 0.6, c3_z0 + c3[2] + 0.05], [c3_x - c3_hdr_x + 0.6, c3_edge_y - c3_hole_end + 0.6, 8]] :
    name == "filler"    ? [[c3_x - 1, box_d - wall + 0.2, 0.5], [c3_x + 1, box_d - 0.5, 1.5]] :
    assert(false, str("unknown bottom probe: ", name));

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
    echo(cap_d = cap_d, cap_h = cap_h, cap_disc = cap_top_z - cap_under_z);
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
else if (part == "frame_test") {
    echo(frame_footprint = [2 * coupon_split_r, 2 * coupon_split_r, face_t + body_frame_h]);
    coupon_disc();     // face disc alone: collar hole and body frame, frame up
}
else if (part == "glow_test") {
    echo(glow_footprint = glow_footprint);
    glow_coupon();     // four tiles, face down on the bed, legs up
}
else if (part == "shell") {
    echo(box_footprint = box_footprint);
    echo(box_h = box_h, hood_od = hood_od, wall = wall);
    echo(c3_stop_gap = c3_stop_gap);
    echo(c3_back_cuts_z0 = c3_back_cuts_z0);
    echo(front_h = front_h, front_h_ky = front_h_ky, front_h_boss = front_h_boss,
         rear_d = rear_d, rear_d_c3 = rear_d_c3, ky_low_z = ky_low_z, c3_top_z = c3_top_z);
    // Print on its back wall: back outer face on the bed, open bottom to the side.
    translate([0, 0, box_d]) rotate([-90, 0, 0]) shell();
}
else if (part == "bottom") {
    echo(bottom_footprint = bottom_footprint);
    echo(weight_pause_z = weight_pause_z);
    echo(m3_screw_l = m3_screw_l, m3_cbore_h = m3_cbore_h, m3_tip_z = m3_tip_z);
    // Print outside face down (recesses and counterbores on the bed), cradle up;
    // pause at weight_pause_z to drop the weights into the sealed pockets.
    translate([0, 0, plate_t]) bottom();
}
else if (part == "c3_clip") {
    // Bed bbox: box-frame X, Z (standing up), Y (depth on the bed).
    echo(c3_clip_bed = [c3_clip_size[0], c3_clip_size[2], c3_clip_size[1]]);
    // Print on its front face: bar and legs on the bed, the teeth rising from them.
    translate([0, 0, -c3_clip_y0]) rotate([90, 0, 0]) c3_clip();
}
else if (part == "shell_probe")                         // must render empty
    let(b = shell_probe_box(probe)) intersection() { shell(); translate(b[0]) cube(b[1] - b[0]); }
else if (part == "bottom_probe")                        // must render solid
    let(b = bottom_probe_box(probe)) intersection() { bottom(); translate(b[0]) cube(b[1] - b[0]); }
else if (part == "assembly") assembly();               // preview, box frame
else if (part == "interference") interference();       // must render empty
else if (part == "face") face_center(lip_or + wall);   // face-center preview
else assert(false, str("unknown part: ", part));
