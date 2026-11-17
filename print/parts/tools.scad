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
        // Hex socket, nut_af + socket_fit across flats.
        translate([0, 0, -eps])
            cylinder(d = (nut_af + socket_fit) / cos(30), h = socket_depth + eps, $fn = 6);
        // Through-bore slides over the collar and shaft.
        translate([0, 0, -eps])
            cylinder(d = collar_d + shaft_clr, h = driver_shaft_l + hh + 2 * eps);
    }
}

// ---- Test coupons (bed frame: z = 0 is the print bed) ----

// Fit coupon, in a row along +X, coupon_gap apart: the face split into a
// lip ring and a centre disc (so each prints flat with no supports), a
// well-floor washer, a cap-bore plug, and a hood segment with one key tab.
module fit_coupon() {
    // Lip ring, upright: seat lip and key notches for the hood-key test.
    translate([0, 0, face_t]) intersection() {
        face_center(coupon_face_r);
        tube(coupon_split_r, coupon_face_r + 1, -face_t - eps, lip_h + eps);
    }
    // Centre disc, face top on the bed: body frame points up. Collar hole,
    // body frame and clamp stack are tested on this piece.
    translate([coupon_disc_x, 0, 0]) rotate([180, 0, 0]) intersection() {
        face_center(coupon_face_r);
        translate([0, 0, body_frame_bot_z - eps])
            cylinder(r = coupon_split_r, h = face_t + body_frame_h + eps);
    }
    // Well-floor washer: stands in for the hood floor in the clamp stack.
    translate([coupon_washer_x, 0, 0]) tube(collar_hole_d / 2, floor_washer_od / 2, 0, floor_t);
    // Cap-bore plug, roof on the bed, bore open upward.
    translate([coupon_plug_x, 0, 0]) bore_plug();
    // Hood segment, top-down like the real hood; key tab toward -Y.
    translate([coupon_seg_x, (coupon_seg_or + coupon_seg_y0) / 2, hood_top_z])
        rotate([180, 0, 0]) hood_segment(key_tab_angles[0]);
}

// The cap's blind D bore inside a short cylinder; own frame, roof at z = 0.
module bore_plug() {
    depth = shaft_d_h + bore_fit;
    difference() {
        cylinder(d = coupon_plug_d, h = coupon_plug_h);
        translate([0, 0, coupon_plug_h - depth])
            linear_extrude(depth + eps) d_profile(shaft_d + bore_fit, shaft_flat + bore_fit);
    }
}

// coupon_arc of the hood (outer wall, top over the ring band) centred on the
// key tab at angle a, turned so the tab points +Y. Face frame.
module hood_segment(a) {
    rotate([0, 0, -a]) intersection() {
        hood();
        rotate([0, 0, 90 + a - coupon_arc / 2])
            rotate_extrude(angle = coupon_arc)
                translate([coupon_seg_ir, -eps]) square([coupon_seg_or + 1 - coupon_seg_ir, hood_top_z + 2 * eps]);
    }
}

// Glow coupon: a strip of hood-top thickness in steps along +X, each glow_steps
// gap above the ring top. Side legs straddle the ring band and stand on the
// surface the ring lies on. Gap labels are embossed on the -Y leg.
module glow_coupon() {
    w = glow_strip[1];
    n = len(glow_steps);
    translate([-glow_strip[0] / 2, 0, 0]) for (i = [0 : n - 1]) {
        g = glow_steps[i];
        under = ring_t + g;
        l = glow_step_l + (i < n - 1 ? eps : 0);      // overlap the next step
        translate([i * glow_step_l, 0, 0]) {
            for (y = [-w / 2, w / 2 - glow_leg_w])
                translate([0, y, 0]) cube([l, glow_leg_w, under + hood_top_t]);
            translate([0, -w / 2, under]) cube([l, w, hood_top_t]);
            translate([glow_step_l / 2, -w / 2 + eps, (ring_t + min(glow_steps)) / 2])
                rotate([90, 0, 0]) linear_extrude(glow_digit_depth + eps)
                    text(str(g), size = glow_digit_size, halign = "center", valign = "center");
        }
    }
}
