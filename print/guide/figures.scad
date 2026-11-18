// Figures for the print-and-assembly guide. Pick one with -D 'fig="..."'.
// Pale part colours plus one saturated accent (ACC) per figure; build.sh
// renders each, then lineart.py draws black edges over it.
include <../lib/params.scad>
include <../lib/checks.scad>
include <../parts/face.scad>
include <../parts/hood.scad>
include <../parts/cap.scad>
include <../parts/tools.scad>
include <../parts/shell.scad>
include <../parts/bottom.scad>
include <../parts/assembly.scad>

fig = "exploded";
SHELL = [0.80, 0.80, 0.80];
PLATE = [0.70, 0.76, 0.86];
HOOD = [0.93, 0.93, 0.90];
CAP = [0.55, 0.55, 0.58];
BOARD = [0.55, 0.70, 0.85];
ACC = [0.90, 0.10, 0.45];       // accent: what the figure is about
ACC2 = [0.98, 0.70, 0.10];      // second accent (weights, antenna)

module plate_group(clip_up = 0) {
    color(PLATE) item(1);
    color(BOARD) item(7);
    color(BOARD * 0.8) item(13);
    color(ACC) translate([0, 0, clip_up]) item(12);
}

// Inner front rim edge of the shell: where support gets painted.
module paint_strip() {
    yf = wall + shell_z1;
    translate([-(box_w / 2 - wall), yf - 2, 0]) cube([box_w - 2 * wall, 2, 0.8]);
}

module antenna_ghost() {
    y0 = c3_edge_y - c3[0];
    translate([c3_x - c3_ant_w / 2, y0 + 0.4, c3_z0 + c3[2]]) cube([c3_ant_w, 1.6, 0.9]);
}

module pads_ghost() for (s = [-1, 1]) translate([s * pad_x, box_d / 2, 0]) pad_ghost();

// 2D sections, extruded thin and stacked by z so colours do not fight.
// Side: across the box at mid-depth, zoomed on the left wall (x right, z up).
module cut_side(z) translate([0, 0, z]) linear_extrude(0.5) intersection() {
    projection(cut = true) rotate([-90, 0, 0]) translate([0, -box_d / 2, 0]) children();
    translate([-box_w / 2 - 1, -plate_t - 1]) square([12, plate_t + 9]);
}
// Front: front to back at x = -10, zoomed on the front wall (y right, z up).
module cut_front(z) translate([0, 0, z]) linear_extrude(0.5) intersection() {
    projection(cut = true) multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 10]]) children();
    translate([-1, -plate_t - 1]) square([26, plate_t + 15]);
}

// The build plate under a part in its print pose (STL already on z = 0): its
// footprint grown 4 mm, as a thin slab.
module on_bed(f) {
    color([0.93, 0.93, 0.93]) translate([0, 0, -0.8]) linear_extrude(0.8) offset(r = 4) projection() import(f);
    children();
}

if (fig == "exploded") {
    color(SHELL) item(0);
    translate([0, 0, -32]) { plate_group(); }
    translate([0, 0, -32 - plate_t - 10]) color(ACC) pads_ghost();
    translate(face_n * 22) { color(HOOD) item(2); color([0.3, 0.8, 0.3]) item(5); }
    translate(face_n * 48) color(CAP) item(3);
    color(BOARD) item(6);
}
else if (fig == "paint") {
    color(SHELL) item(0);
    color(ACC) paint_strip();
}
else if (fig == "pause") {
    // The plate as printed up to the pause: pocket tops open, weights going in.
    color(PLATE) intersection() {
        bottom();
        translate([-50, -10, -plate_t - 1]) cube([100, 100, plate_t - weight_roof + 1]);
    }
    color(ACC2) translate([0, 0, 14]) weights_ghost();
}
else if (fig == "c3") {
    color(PLATE) intersection() {
        item(1);
        translate([c3_x - 16, box_d - 34, -plate_t - 1]) cube([32, 40, 30]);
    }
    color(BOARD) item(7);
    color(ACC2) antenna_ghost();
    color(ACC) translate([0, 0, 7]) item(12);
}
else if (fig == "lip") {
    // Section across the box at mid-depth, plate seated: the left side wall
    // with the lip just inside it (lip_fit gap).
    color(SHELL) cut_side(0) item(0);
    color(PLATE) cut_side(0.5) item(1);
    color(ACC) cut_side(1) plate_lip();
}
else if (fig == "lip_front") {
    // Section front to back at x = -10: the lip's 45 degree face under the inside ramp.
    color(SHELL) cut_front(0) item(0);
    color(PLATE) cut_front(0.5) item(1);
    color(ACC) cut_front(1) plate_lip();
}
else if (fig == "underside") {
    color(PLATE) item(1);
    color(ACC) translate([0, 0, -plate_t - (pad[2] - pad_recess)]) pads_ghost();
}
else if (fig == "back") {
    {
    color(SHELL) item(0);
    color(PLATE) item(1);
    color(BOARD) item(7);
    color(ACC) translate([0, 0.05, 0.02]) port_filler();
    }
}
else if (fig == "screws") {
    color(SHELL) item(0);
    translate([0, 0, -14]) color(PLATE) item(1);
    color(ACC) translate([0, 0, -26]) screws_ghost();
}
else if (fig == "bed_shell") on_bed("../stl/shell_v6.stl") color(SHELL) import("../stl/shell_v6.stl");
else if (fig == "bed_bottom") on_bed("../stl/bottom_v8.stl") color(PLATE) import("../stl/bottom_v8.stl");
else if (fig == "bed_clip") on_bed("../stl/c3_clip_v3.stl") color(ACC) import("../stl/c3_clip_v3.stl");
else if (fig == "bed_hood") on_bed("../stl/hood_v2.stl") color(HOOD) import("../stl/hood_v2.stl");
else if (fig == "bed_cap") on_bed("../stl/cap_v3.stl") color(CAP) import("../stl/cap_v3.stl");
else assert(false, str("unknown fig: ", fig));
