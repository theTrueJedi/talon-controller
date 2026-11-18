// Stack and fit checks over params.scad. Any failure aborts the render
// (OpenSCAD exits non-zero and prints the message to stderr).

collar_spare = collar_h - (face_t + floor_t + washer_t + nut_t);
assert(collar_spare >= 1.0, "collar thread: nut has <1mm engagement");

assert(cap_d <= 32, "cap covers LEDs");

assert(well_id >= nut_corner + 3, "well too narrow for nut driver");

assert(stem_od <= well_id - 1, "cap stem too wide for well");

assert(hood_id >= ring_od + 2, "hood ID too tight around ring");

// Circular distance, so 350 vs 0 counts as 10 degrees apart.
function ang_dist(a, b) = let(d = ((a - b) % 360 + 360) % 360) min(d, 360 - d);
for (a = key_tab_angles)
    assert(ang_dist(a, wire_slot_angle) >= 30, "key tab on wire slot");

// Encoder body locating frame: positive size, and shorter than the body, so it
// grips the body's top and stays off the KY-040 PCB.
assert(body_frame_h > 0 && body_frame_wall > 0, "body frame needs a positive height and wall");
assert(body_frame_h < body[2], str("body frame reaches the KY-040 PCB: body_frame_h ", body_frame_h,
                                   " >= body height ", body[2]));
assert(body_frame_in[0] / 2 > collar_hole_d / 2, "body frame inside the collar hole");

// Hood keying, wire slot and fallback options.
assert(hood_od / 2 + key_tab_len <= lip_or, "key tab sticks out past the seat lip");
assert(wire_slot_r - wire_slot[1] / 2 >= ring_id / 2 &&
       wire_slot_r + wire_slot[1] / 2 <= ring_od / 2, "wire slot outside ring band");
assert(hood_screw_r - m2_boss_d / 2 >= ring_od / 2 + m2_boss_ring_clr, "M2 boss hits the ring");
if (hood_screws)
    for (s = hood_screw_angles) {
        assert(ang_dist(s, wire_slot_angle) >= 30, "M2 boss on wire slot");
        for (a = key_tab_angles) assert(ang_dist(s, a) >= 30, "M2 boss on key tab");
    }
assert(halo_ir + halo_t <= ring_id / 2 - 1, "halo sleeve reaches the LEDs");

// Cap bore and nut driver.
assert(cap_roof >= cap_roof_min, str("cap roof over bore too thin: ", cap_roof));
assert(stem_bot_z >= nut_top_z + 0.5, "cap stem hits the nut");
assert(driver_od <= well_id - 1, "nut driver too wide for well");
assert((nut_af + socket_fit) / cos(30) <= driver_od - 2, "driver socket wall too thin");

// Knob press: every Z gap between the cap and a fixed part must exceed the
// switch travel, or the cap bottoms out before the switch clicks.
assert(cap_float > press_travel,
       str("cap_float gap (cap underside to hood top) <= press_travel: ", cap_float));
assert(cap_cbore_top_z - collar_top_z > press_travel,
       str("collar counterbore gap <= press_travel: ", cap_cbore_top_z - collar_top_z));
assert(stem_bot_z - nut_top_z > press_travel,
       str("stem-to-nut gap <= press_travel: ", stem_bot_z - nut_top_z));

// Test coupons.
assert(norm(body_frame_out / 2) < coupon_split_r, "fit coupon split cuts the body frame");
assert(coupon_split_r < lip_ir - 1, "fit coupon split cuts the seat lip");
glow_band_need = (ring_od - ring_id) / 2
               + ring_od / 2 - sqrt(pow(ring_od / 2, 2) - pow(glow_step_l / 2, 2));
assert(glow_strip[1] - 2 * glow_leg_w >= glow_band_need,
       str("glow legs land on the ring band: need ", glow_band_need, " between them"));
assert(glow_digit_size + 1 <= ring_t + min(glow_steps), "glow digits taller than the lowest leg");
assert(glow_digit_depth > 0, "glow digits must be embossed, not cut");

// Shell.
assert(fillet_r > wall, "fillet_r must exceed wall (inside corners round at fillet_r - wall)");
assert(face_half - fillet_r >= lip_or, "face_len too short: hood seat lip runs into the edge fillet");
assert(c3_wall_slot < wall, "C3 wall slot cuts through the back wall: nothing stops a cable pull");
// The front stop must leave the board room to seat, and catch it before a
// plug push slides its port edge out of the back-wall slot.
assert(c3_wall_slot - c3_slot_clr >= 0.4,
       str("C3 slot clearance leaves too little engagement: ", c3_wall_slot - c3_slot_clr, " < 0.4"));
assert(c3_stop_gap > 0 && c3_stop_gap <= c3_stop_gap_max && c3_stop_gap < c3_wall_slot - c3_slot_clr,
       str("C3 front stop gap ", c3_stop_gap, " (set by c3_fit) must be > 0, <= ", c3_stop_gap_max,
           " and < the slot engagement ", c3_wall_slot - c3_slot_clr));
assert(usb_plug[0] < usb_plug_hole[0] && usb_plug[1] < usb_plug_hole[1],
       str("USB plug wider than its hole: plug ", usb_plug, ", hole ", usb_plug_hole));
assert(c3_groove[1] < c3_z0, str("C3 solder groove cuts through the pedestal: depth ", c3_groove[1], " >= ", c3_z0));
assert(c3_groove[0] > 0 && c3_groove[0] < c3[1] / 2, "C3 solder grooves must leave a pedestal spine");
assert(c3_clip_engage + c3_fit < c3_rail_t, "C3 clip notch cuts through the rail");
assert(c3_clip_barb - c3_fit >= 0.4, str("C3 clip barb engagement past the leg gap < 0.4: ", c3_clip_barb - c3_fit));
c3_clip_bar_rect = [[-c3_clip_hw, c3_clip_y0], [c3_clip_hw, c3_clip_bar_y1]];
c3_clip_tooth_rects = [[[c3_tooth_x0, c3_stop_y], [c3_tooth_x1, c3_clip_y1]],
                       [[-c3_tooth_x1, c3_stop_y], [-c3_tooth_x0, c3_clip_y1]]];
assert(c3_tooth_x0 >= c3_ant_w / 2, str("C3 clip tooth over the antenna: inner edge ", c3_tooth_x0, " < ", c3_ant_w / 2));
for (h = c3_corner_holes, r = concat([c3_clip_bar_rect], c3_clip_tooth_rects))
    assert(rect_pt_dist(r, h) >= c3_corner_clr,
           str("C3 clip within c3_corner_clr of a pin-row corner hole: ", rect_pt_dist(r, h)));
assert(c3_clip_barb_z > c3_fit, "C3 clip notch runs off the rail bottom");
// The lowered wired-side rail must still locate at least half the board edge.
assert(c3_rail_low_z >= c3_z0 + c3[2] / 2,
       str("C3 wired-side rail too low to locate the board (hdr_leg_z ", hdr_leg_z, "): top ", c3_rail_low_z));
assert(c3_tooth_x1 < c3[1] / 2 - c3_groove[0],
       "C3 clip teeth reach the pin rows (keep them inside the groove-free middle)");
assert(c3_clip_top_z <= c3_top_z, "C3 clip stands taller than the USB port (the box height ignores it)");
assert(c3_hdr_y0 + c3_hdr_n * hdr_pitch <= c3[0], str("C3 header longer than the board: ", c3_hdr_n, " pins"));
assert(ky_hdr_n * hdr_pitch <= ky_pcb[1], str("KY-040 header wider than the board: ", ky_hdr_n, " pins"));
assert(ky_low_z >= c3_top_z + clr, str("KY-040 hangs onto the C3-Zero: ", ky_low_z));
assert(top_flat_min > 0, "top_flat_min must be > 0 (flat-topped rear)");
assert(m3_detent > 0 && m3_detent < m3_slot_w / 4, str("nut detent must be > 0 and small: ", m3_detent));

// Bottom plate.
assert(c3_filler_hw <= c3[1] / 2 - c3_groove[0], "port filler fills the solder-tail grooves");
assert(c3_hook_x1 - c3_hook_x0 >= 0.8, str("C3 port hooks too narrow: ", c3_hook_x1 - c3_hook_x0));
assert(c3_tab_y[1] - c3_tab_y[0] >= 0.6, str("C3 port tab too thin (receptacle overhang?): ", c3_tab_y[1] - c3_tab_y[0]));
assert(c3_filler_hw <= usb_plug_hole[0] / 2 - c3_fit,
       str("port filler rubs the notch sides: half-width ", c3_filler_hw, " > ", usb_plug_hole[0] / 2 - c3_fit));
assert(lip_side_y[1] - lip_side_y[0] > 10 && lip_front_hw > 5,
       str("plate lip runs too short: side ", lip_side_y, ", front half ", lip_front_hw));
assert(m3_cbore_h >= m3_head[1],
       str("M3 head sticks out of its counterbore: screw too long (m3_screw_l ", m3_screw_l, ")"));
assert(plate_t - m3_cbore_h >= bottom_t,
       str("too little plate under the M3 head: screw too short (m3_screw_l ", m3_screw_l, ")"));
assert(m3_tip_z <= boss_stack_h, "M3 screw tip hits the boss roof");
assert(m3_nut_t < m3_trap_h, str("M3 nut thicker than its slot: m3_nut_t ", m3_nut_t, " >= m3_trap_h ", m3_trap_h));
assert(bottom_t - pad_recess >= 1, "pad recess too close to the weight pocket floor");
// Plan distance from a rectangle [[x0, y0], [x1, y1]] to a point.
function rect_pt_dist(r, p) = norm([max(r[0][0] - p[0], 0, p[0] - r[1][0]),
                                    max(r[0][1] - p[1], 0, p[1] - r[1][1])]);
function rects_gap(a, b) = max(a[0][0] - b[1][0], b[0][0] - a[1][0],
                               a[0][1] - b[1][1], b[0][1] - a[1][1]);
c3_cradle_rect = [[c3_x - c3_cradle_hw, c3_cradle_y0], [c3_x + c3_cradle_hw, c3_cradle_y1]];
for (p = boss_xy) if (!boss_front(p))
    assert(rect_pt_dist(c3_cradle_rect, p) >= boss_d / 2 + clr,
           str("C3 cradle hits a rear boss: ", rect_pt_dist(c3_cradle_rect, p)));
for (i = [0 : len(weight_pockets) - 1]) {
    w = weight_rect(i);
    assert(w[0][0] >= -box_w / 2 + plate_fit + wall && w[1][0] <= box_w / 2 - plate_fit - wall &&
           w[0][1] >= plate_fit + wall && w[1][1] <= box_d - plate_fit - wall,
           str("weight pocket ", i, " too near the plate edge"));
    for (p = boss_xy) assert(rect_pt_dist(w, p) >= m3_cbore_d / 2 + clr,
                             str("weight pocket ", i, " cuts an M3 counterbore"));
    for (j = [0 : len(weight_pockets) - 1]) if (j > i)
        assert(rects_gap(w, weight_rect(j)) >= weight_gap,
               str("weight pockets overlap (or under weight_gap): ", i, " and ", j));
}
for (s = [-1, 1]) let(r = pad_rect(s)) {
    assert(r[0][0] >= -box_w / 2 + plate_fit + pad_edge && r[1][0] <= box_w / 2 - plate_fit - pad_edge &&
           r[0][1] >= plate_fit + pad_edge && r[1][1] <= box_d - plate_fit - pad_edge,
           str("pad recess too near the plate edge: ", r));
    for (p = boss_xy) assert(rect_pt_dist(r, p) >= m3_cbore_d / 2 + clr - 1e-6,
                             "pad recess cuts an M3 counterbore");
}
