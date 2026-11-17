// Talon controller housing parameters. All dims in mm, angles in degrees.
//
// FACE FRAME: origin on the shaft axis at the face top plane; +Z along the
// shaft, out of the box; +Y up-slope toward the back; +X right, seen from front.

// ---- Ring (LED ring PCB) ----
ring_od = 50;
ring_id = 37;
ring_t  = 3.1;

// ---- KY-040 board ----
ky_pcb = [26, 19, 1.5];                 // [along header axis, across, thick]
ky_shaft_from_header_edge = 14.5;
ky_shaft_from_hole_edge   = 9;
ky_hole_d = 3;
ky_hole_x_from_header = [4.5, 21.5];    // hole centres from the header edge
ky_hole_from_long_edge = 2.5;           // hole centres in from the hole edge

// ---- Encoder ----
body = [12, 12, 6.5];                   // square body, centred on the shaft
collar_d = 7;
collar_h = 7;
shaft_gap = 0.5;
shaft_round_h = 5;
shaft_d_h = 7;
shaft_d = 6;
shaft_flat = 4.5;

// ---- Nut and washer ----
nut_af = 10;
nut_t = 2;
washer_od = 11.5;
washer_t = 0.5;

// ---- ESP32-C3-Zero ----
c3 = [24, 18.05, 1.0];
usb_port = [8.85, 3.15];
usb_plug_hole = [12.5, 7.5];

// ---- Weights ----
weight = [19.65, 22, 5.8];
weight_count = 4;

// ---- Face and hood ----
face_t = 1.5;
floor_t = 1.5;
hood_id = 52;
hood_wall = 1.6;
hood_top_t = 2;
glow_gap = 8;
well_id = 16;
collar_hole_d = 7.4;
well_wall = 1.6;                        // hood inner (well) wall thickness
lip_h = 1;                              // hood seat lip on the face
lip_w = 1.6;
// Key tabs project outward from the hood outer wall at z 0..lip_h and sit
// in notches cut through the seat lip.
key_tab_w = 2;                          // tangential
key_tab_len = lip_w;                    // radial; stays inside the lip OD
wire_slot = [8, 3];                     // [tangential, radial], under the ring band
// M2 fallback (hood_screws): clearance through the face, pilot in a boss
// grown outward from the hood outer wall (notched through the seat lip).
m2_clear_d = 2.4;
m2_pilot_d = 1.6;
m2_pilot_depth = 6;
m2_boss_d = 3.6;
m2_boss_ring_clr = 0.5;                 // boss inner edge to ring OD
hood_screw_angles = [45, 225];          // about +Z; 0 = +Y
// Opaque halo sleeve (halo_block): slips over the outside of the well wall.
halo_t = 0.8;

// ---- Cap ----
cap_d = 28;
cap_float = 1.5;
cap_over_shaft = 1.5;
stem_od = 15;
cap_chamfer = 0.8;                      // disc top and bottom edge chamfer
shaft_clr = 0.6;                        // diametral clearance on the round shaft
press_travel = 0.5;                     // measured shaft->collar gap = switch travel
collar_clr_h = 0.5;                     // counterbore margin above collar top + press_travel
cap_roof_min = 1.2;                     // material over the blind bore
knurl_n = 36;                           // flutes round a knurled grip
knurl_flute_d = 1.2;                    // flute cutter diameter
knurl_depth = 0.4;                      // flute depth into the grip

// ---- Nut driver ----
socket_depth = 3;
driver_od = well_id - 1;                // socket and shaft OD; must fit the well
driver_handle_clear = 15;               // handle bottom above the hood top
driver_handle = [20, 20];               // [diameter, height]

// ---- Fits and pins ----
pin_d = 2.6;
clr = 1;
fit = 0.2;

// ---- Box ----
slope = 30;
face_len = 72;
wall = 2;

// ---- Facets ----
$fa = 2;
$fs = 0.3;
eps = 0.01;

// ---- Options ----
hood_screws = false;
halo_block = false;
key_tab_angles = [90, 270];             // about +Z; 0 = +Y
wire_slot_angle = 0;                    // about +Z; 0 = +Y
cap_knurl = false;                      // flute the cap rim

// ================= Derived (face frame Z) =================
body_top_z   = -face_t;                         // encoder body top meets face underside
collar_top_z = body_top_z + collar_h;
shaft_top_z  = collar_top_z + shaft_gap + shaft_round_h + shaft_d_h;
ring_top_z   = ring_t;                          // ring sits on face top
hood_under_z = ring_top_z + glow_gap;
hood_top_z   = hood_under_z + hood_top_t;
cap_under_z  = hood_top_z + cap_float;
cap_top_z    = shaft_top_z + cap_over_shaft;
nut_top_z    = floor_t + washer_t + nut_t;      // well floor, washer, nut on face top
nut_corner   = nut_af / cos(30);
stem_bot_z   = nut_top_z + 1;                   // cap stem bottom, 1 above the nut
shaft_dsec_z = shaft_top_z - shaft_d_h;         // bottom of the shaft's D section
cap_cbore_top_z = collar_top_z + press_travel + collar_clr_h;  // collar counterbore ceiling
cap_bore_top_z = shaft_top_z + fit;             // blind end of the cap bore
cap_roof     = cap_top_z - cap_bore_top_z;
cap_h        = cap_top_z - stem_bot_z;
// Driver open end rests on the washer; shaft runs from there to the handle.
driver_shaft_l = hood_top_z + driver_handle_clear - (nut_top_z - nut_t);
// glow_gap at which hood_top_z == cap_top_z - 3.5 - cap_float
max_glow_gap = cap_top_z - 3.5 - cap_float - ring_top_z - hood_top_t;

// ================= Derived (face and hood radii) =================
hood_od = hood_id + 2 * hood_wall;
hood_screw_r = ring_od / 2 + m2_boss_ring_clr + m2_boss_d / 2;  // M2 circle
lip_ir = hood_od / 2 + fit;                     // lip inner radius
lip_or = lip_ir + lip_w;
wire_slot_r = (ring_id + ring_od) / 4;          // centre of the ring band
well_wall_or = well_id / 2 + well_wall;
halo_ir = well_wall_or + fit;

// ================= Derived (face frame XY) =================
// KY-040 orientation: header edge toward +Y, hole (long) edge toward +X.
// Board-local u runs from the header edge; the shaft is at u = 14.5.
// Far hole (u = 4.5) sits 10 toward +Y; holes sit 9 - 2.5 = 6.5 toward +X.
ky_hole_x = ky_shaft_from_hole_edge - ky_hole_from_long_edge;
ky_far_hole_xy  = [ky_hole_x, ky_shaft_from_header_edge - ky_hole_x_from_header[0]];
ky_near_hole_xy = [ky_hole_x, ky_shaft_from_header_edge - ky_hole_x_from_header[1]];
// Encoder body corner nearest the far hole (body centred on shaft).
ky_far_body_corner_xy = [body[0] / 2, body[1] / 2];
