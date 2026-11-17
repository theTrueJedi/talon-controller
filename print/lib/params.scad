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
shaft_gap = 0.5;                        // measured shaft step to collar top = switch travel
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
c3_port_len = 7.35;                     // USB-C receptacle depth (assembly ghost only)

// ---- Weights ----
weight = [19.65, 22, 5.8];
weight_count = 4;
weight_gap = 2;                         // between weight pockets

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
press_travel = shaft_gap;               // switch travel: the measured shaft gap
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

// ---- Test coupons ----
coupon_gap = 5;                         // bed spacing between coupon bodies
coupon_face_margin = 4;                 // fit-coupon face disc radius past hood OD
coupon_split_r = ring_id / 2;           // face splits here: inner disc + lip ring
coupon_arc = 40;                        // hood segment arc, centred on a key tab
coupon_plug_d = 12;                     // cap-bore plug OD
coupon_plug_roof = 2;                   // plug height over the D section
glow_strip = [60, 14];                  // [total length, width]; split into one tile per gap
glow_steps = [5, 8, 10, 12];            // glow gaps under each step, low to high
glow_leg_w = hood_wall;                 // side legs, straddling the ring band
glow_digit_size = 5;                    // embossed label text size
glow_digit_depth = 0.6;                 // label emboss height, out of the leg
glow_tile_gap = 4;                      // bed spacing between glow tiles

// ---- Encoder body locating frame ----
// A square frame hanging from the face underside, centred on the shaft. The
// encoder body's square top seats inside it, so the body can't turn.
body_frame_h = 1.0;                     // frame height below the face underside
body_frame_wall = 1.2;                  // frame wall thickness
body_fit = 0.2;                         // frame inner side = body side + body_fit

// ---- Fits ----
// Printed-fit clearances, one per feature, so a checkpoint failure names the
// one number to change.
clr = 1;                                // least inside clearance around bought parts
bore_fit = 0.2;                         // cap D-bore over the shaft (and bore plug)
key_fit = 0.2;                          // hood in its seat lip, key tab in its notch
halo_fit = 0.2;                         // halo sleeve over the well wall (radial)
c3_fit = 0.2;                           // C3-Zero slot: length (stop gap), width, height
m3_nut_fit = 0.2;                       // M3 nut slot across flats
plate_fit = 0.2;                        // bottom plate inset from the shell outline
foot_fit = 0.2;                         // TPU foot recess (radial)
socket_fit = 0.2;                       // nut driver hex socket across flats

// ---- Box ----
slope = 30;
face_len = 72;
wall = 2;
fillet_r = 3;                           // outer edge fillets (bottom edges stay sharp)
face_margin = 1.6;                      // seat lip OD to the side edge fillet
top_flat_min = 10;                      // least flat-top depth behind the slope
ky_wire_room = 5;                       // past the KY-040 header edge (+Y): stubs + wires
ky_wire_h = 3;                          // above the KY-040 PCB top near the header edge
// Corner bosses for the bottom plate's M3 screws. The nut sits in a
// side-entry slot with boss material under it, so tightening a screw from
// below clamps the plate to the shell.
boss_d = 8;
m3_clear_d = 3.4;
m3_nut_af = 5.7;
m3_trap_h = 2.6;                        // nut slot height
boss_floor = 2;                         // boss material between plate and nut
boss_roof = 1.2;                        // boss material over the nut (screw-tip room)
m3_detent = 0.25;                       // bumps narrowing the nut slot at the hex pocket mouth
// C3-Zero cradle: pedestal, front stop, two side rails, and a separate clip.
// Wires solder straight into the board's holes (no headers), so solder tails
// stick out under both pin rows (the board's long edges) and wires stand up
// from the corner holes: grooves clear the tails, and the hold-down sits on
// the middle of the inner short edge, away from every pad.
c3_wall_slot = 1;                       // board's port edge sinks this far into the back wall
c3_stop_gap_max = 0.3;                  // most board play between the wall slot and front stop
c3_stop_t = 2;                          // front stop thickness (Y)
c3_rail_t = 1.2;                        // side rail thickness (X)
c3_rail_gap = 0.6;                      // rail to pedestal gap
c3_groove = [3, 1.5];                   // solder-tail groove under each pin row: [width in from the board's long edge, depth]
c3_lip_h = 0.8;                         // clip tongue height: its underside to the rail and stop tops
c3_lip_len = 1;                         // clip tongue length (Y) past the front stop face, over the board
c3_clip_w = 6;                          // clip tongue width (X), centred on the board's inner short edge
c3_clip_t = 1.2;                        // clip bar thickness (Z) and leg thickness (X)
c3_clip_engage = 0.5;                   // barb overlap onto the rail, past the leg's c3_fit gap
c3_hole_edge = 1.6;                     // pin-row hole centres in from the board's long edge (unmeasured)
c3_hole_end = 1.6;                      // end hole centres in from the board's short edge (unmeasured)
c3_corner_clr = 1.5;                    // least clip clearance (plan) to an inner-end corner hole centre
c3_clip_barb_h = 1;                     // barb height (Z): ramp below, flat catch on top
c3_clip_barb_z = 1;                     // barb bottom above the rail bottom
usb_hole_r = 1.5;                       // USB plug hole corner radius
cable_rib = [1.2, 3];                   // [thickness, height] of the cable channel ribs

// ---- Bottom plate and feet ----
bottom_t = 3;                           // plate thickness under the weight pockets
// M3 socket-head screws from the kit (6/8/10/12/16/20/25 long), up through
// the plate into the shell's boss nuts. The counterbore depth follows the
// length so the tip always lands m3_tip_over_nut past the nut.
m3_screw_l = 10;                        // under-head length
m3_d = 3;                               // thread OD (assembly ghost)
m3_head = [5.5, 3];                     // socket head [diameter, height]
m3_cbore_clr = 0.6;                     // counterbore diametral clearance on the head
m3_nut_t = 2.4;                         // M3 hex nut thickness
m3_tip_over_nut = 0.6;                  // screw tip past the nut top
foot_d = 12;                            // TPU foot disc
foot_h = 3;
foot_recess = 1;                        // recess depth on the plate's outside
foot_edge = 1.5;                        // least plate rim outside a foot recess

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
cap_bore_top_z = shaft_top_z + bore_fit;             // blind end of the cap bore
cap_roof     = cap_top_z - cap_bore_top_z;
cap_h        = cap_top_z - stem_bot_z;
// Driver open end rests on the washer; shaft runs from there to the handle.
driver_shaft_l = hood_top_z + driver_handle_clear - (nut_top_z - nut_t);
// glow_gap at which hood_top_z == cap_top_z - 3.5 - cap_float
max_glow_gap = cap_top_z - 3.5 - cap_float - ring_top_z - hood_top_t;
ky_pcb_bottom_z = body_top_z - body[2] - ky_pcb[2];
body_frame_in = [body[0] + body_fit, body[1] + body_fit];  // frame inner sides
body_frame_out = body_frame_in + 2 * [body_frame_wall, body_frame_wall];
body_frame_bot_z = body_top_z - body_frame_h;   // frame bottom edge

// ================= Derived (face and hood radii) =================
hood_od = hood_id + 2 * hood_wall;
hood_screw_r = ring_od / 2 + m2_boss_ring_clr + m2_boss_d / 2;  // M2 circle
lip_ir = hood_od / 2 + key_fit;                     // lip inner radius
lip_or = lip_ir + lip_w;
wire_slot_r = (ring_id + ring_od) / 4;          // centre of the ring band
well_wall_or = well_id / 2 + well_wall;
halo_ir = well_wall_or + halo_fit;

// ================= Derived (test coupons) =================
coupon_face_r = hood_od / 2 + coupon_face_margin;
floor_washer_od = well_id + 2 * well_wall;      // matches the hood well floor
coupon_plug_h = shaft_d_h + coupon_plug_roof;
// Hood segment, flipped and turned so its key tab points -Y.
coupon_seg_ir = ring_id / 2;                    // segment top spans the ring band
coupon_seg_or = hood_od / 2 + key_tab_len;      // out to the key tab tip
coupon_seg_half_w = hood_od / 2 * sin(coupon_arc / 2);
coupon_seg_y0 = coupon_seg_ir * cos(coupon_arc / 2);  // nearest the axis
// Bed row along +X: lip ring, face disc, washer, plug, hood segment (centres).
coupon_disc_x = coupon_face_r + coupon_gap + coupon_split_r;
coupon_washer_x = coupon_disc_x + coupon_split_r + coupon_gap + floor_washer_od / 2;
coupon_plug_x = coupon_washer_x + floor_washer_od / 2 + coupon_gap + coupon_plug_d / 2;
coupon_seg_x = coupon_plug_x + coupon_plug_d / 2 + coupon_gap + coupon_seg_half_w;
fit_footprint = [coupon_seg_x + coupon_seg_half_w + coupon_face_r,
                 2 * coupon_face_r,
                 max(face_t + lip_h, face_t + body_frame_h, hood_top_z, coupon_plug_h)];
glow_step_l = glow_strip[0] / len(glow_steps);
glow_footprint = [len(glow_steps) * glow_step_l + (len(glow_steps) - 1) * glow_tile_gap,
                  glow_strip[1] + glow_digit_depth,
                  ring_t + max(glow_steps) + hood_top_t];

// ================= Derived (face frame XY) =================
// KY-040 orientation: header edge toward +Y, hole (long) edge toward +X.
// Board-local u runs from the header edge; the shaft is at u = 14.5.
// Far hole (u = 4.5) sits 10 toward +Y; holes sit 9 - 2.5 = 6.5 toward +X.
ky_hole_x = ky_shaft_from_hole_edge - ky_hole_from_long_edge;
ky_far_hole_xy  = [ky_hole_x, ky_shaft_from_header_edge - ky_hole_x_from_header[0]];
ky_near_hole_xy = [ky_hole_x, ky_shaft_from_header_edge - ky_hole_x_from_header[1]];

// ================= Derived (box frame) =================
// BOX FRAME: x = 0 on the shaft axis (box is symmetric in X), +X right;
// y = 0 at the front outer face, +Y toward the back; z = 0 at the shell's
// open bottom rim, which is also the bottom plate's top (inside) face.
// The bottom plate sits below z = 0.
face_half = face_len / 2;
face_run = face_len * cos(slope);               // slope's footprint depth
face_rise = face_len * sin(slope);
box_w = 2 * (lip_or + face_margin + fillet_r);
// KY-040 envelope (face frame): PCB plus header wire room, up to the face underside.
ky_pcb_top_z = body_top_z - body[2];
ky_x_range = [ky_shaft_from_hole_edge - ky_pcb[1], ky_shaft_from_hole_edge];
ky_y_range = [ky_shaft_from_header_edge - ky_pcb[0], ky_shaft_from_header_edge + ky_wire_room];
ky_z_range = [ky_pcb_top_z - ky_pcb[2], body_top_z];
// Front height: the least that keeps the KY-040 clr above the plate, and
// keeps each front boss's nut slot (+ roof) under the face.
front_h_ky = -((ky_y_range[0] - clr) * sin(slope) + (ky_z_range[0] - clr) * cos(slope))
           - face_half * sin(slope);
boss_c = wall + boss_d / 2;                     // boss centre inset from the outer faces
m3_slot_w = m3_nut_af + m3_nut_fit;            // nut slot across flats
m3_nut_r = m3_slot_w / 2 / cos(30);            // nut slot hex circumradius
boss_stack_h = boss_floor + m3_trap_h + boss_roof;
front_h_boss = boss_stack_h + face_t / cos(slope) - (boss_c - m3_nut_r) * tan(slope);
front_h = max(front_h_ky, front_h_boss);
box_h = front_h + face_rise;
face_origin = [0, face_half * cos(slope), front_h + face_half * sin(slope)];
function face_to_box(p) = face_origin + [p[0], p[1] * cos(slope) - p[2] * sin(slope),
                                         p[1] * sin(slope) + p[2] * cos(slope)];
// Inside ceiling under the slope at box y.
function slope_under_z(y) = front_h + y * tan(slope) - face_t / cos(slope);
ky_low_z = face_to_box([0, ky_y_range[0], ky_z_range[0]])[2];
// C3-Zero: board bottom high enough that the plug hole keeps `wall` below it.
c3_z0 = wall + usb_plug_hole[1] / 2 - c3[2] - usb_port[1] / 2;
c3_port_z = c3_z0 + c3[2] + usb_port[1] / 2;    // port (and plug hole) centre
c3_top_z = c3_z0 + c3[2] + usb_port[1];
c3_reach = (wall - c3_wall_slot) + c3[0] + c3_fit + c3_stop_t;  // back outer face to stop front
// Rear depth: the least flat top that keeps the cradle's front clr under the slope.
rear_d_c3 = (c3_top_z + clr - front_h + face_t / cos(slope)) / tan(slope)
          + c3_reach - face_run;
rear_d = max(rear_d_c3, top_flat_min);
box_d = face_run + rear_d;
box_footprint = [box_w, box_d];                 // outer, plan corners rounded fillet_r
c3_edge_y = box_d - wall + c3_wall_slot;        // board port edge, seated in the wall slot
c3_slot_len = c3[0] + c3_fit;
c3_stop_y = c3_edge_y - c3_slot_len;            // front stop face
c3_stop_gap = (c3_edge_y - c3[0]) - c3_stop_y;  // board inner edge to stop face
c3_lip_z = c3_z0 + c3[2] + c3_fit;              // clip tongue underside
c3_slot_hw = (c3[1] + c3_fit) / 2;                 // board slot half width (rail inner face)
c3_ped_hw = c3_slot_hw - c3_rail_gap;
c3_cradle_hw = c3_slot_hw + c3_rail_t;          // rail outer face
c3_cradle_y0 = c3_stop_y - c3_stop_t;           // front stop's front face
c3_top_h = c3_lip_z + c3_lip_h;                 // rail and stop top; the clip bar rests on it
// C3 clip (box frame): a bar across the rail tops over the stop, legs down the
// rails' outer faces with barbs into rail notches, tongue over the board.
c3_clip_y0 = c3_cradle_y0;
c3_clip_y1 = c3_stop_y + c3_lip_len;            // tongue tip, over the board
c3_clip_leg_x = c3_cradle_hw + c3_fit;          // leg inner face
c3_clip_hw = c3_clip_leg_x + c3_clip_t;         // leg outer face
c3_clip_barb = c3_fit + c3_clip_engage;         // barb depth from the leg's inner face
c3_clip_bar_y1 = c3_stop_y;                     // bar and legs end at the stop face; only the tongue reaches over the board
// Inner-end corner holes (GPIO5 / GPIO6), plan [x, y] in the box frame.
c3_corner_holes = [for (s = [-1, 1]) [s * (c3[1] / 2 - c3_hole_edge), c3_edge_y - c3[0] + c3_hole_end]];
c3_clip_top_z = c3_top_h + c3_clip_t;
c3_clip_size = [2 * c3_clip_hw, c3_clip_y1 - c3_clip_y0, c3_clip_top_z - c3_clip_barb_z];
boss_x = box_w / 2 - boss_c;
boss_xy = [[-boss_x, boss_c], [boss_x, boss_c],
           [-boss_x, box_d - boss_c], [boss_x, box_d - boss_c]];
// Cable channel: from the ring wire slot, under the face and top, down the back wall.
cable_ch_x = -wire_slot_r * sin(wire_slot_angle);
cable_ch_y0 = face_to_box([cable_ch_x, wire_slot_r * cos(wire_slot_angle), -face_t])[1];
cable_ch_z0 = c3_port_z + usb_plug_hole[1] / 2 + wall;

// ================= Derived (bottom plate, box frame) =================
// The plate spans z = -plate_t .. 0, footprint inset `plate_fit` from the shell's.
plate_t = bottom_t + weight[2];
bottom_footprint = [box_w - 2 * plate_fit, box_d - 2 * plate_fit, plate_t];
m3_tip_z = boss_floor + m3_nut_t + m3_tip_over_nut;       // screw tip, above the plate top
m3_cbore_h = plate_t - (m3_screw_l - m3_tip_z);           // counterbore depth from below
m3_cbore_d = m3_head[0] + m3_cbore_clr;
// Weight pockets, rows of two from the front (front-biased: the knob press
// lands at the front). Row 0 hugs the centreline; later rows step outboard
// of the C3-Zero cradle. weight_xy(i) = pocket's min corner [x, y].
weight_y0 = wall + clr;
function weight_row_x(r) = r == 0 ? weight_gap / 2 : c3_cradle_hw + clr;
function weight_xy(i) = let(r = floor(i / 2), s = i % 2 == 0 ? -1 : 1, xi = weight_row_x(r))
    [s > 0 ? xi : -xi - weight[0], weight_y0 + r * (weight[1] + weight_gap)];
// Feet: on the screw rows, just inboard of the counterbores.
foot_recess_r = foot_d / 2 + foot_fit;
foot_y = plate_fit + foot_edge + foot_recess_r;
foot_x = boss_x - m3_cbore_d / 2 - clr - foot_recess_r;
foot_xy = [[-foot_x, foot_y], [foot_x, foot_y], [-foot_x, box_d - foot_y], [foot_x, box_d - foot_y]];
