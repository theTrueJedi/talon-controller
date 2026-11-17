// Talon controller housing. Select a part with -D 'part="..."'.
include <lib/params.scad>
include <lib/checks.scad>
include <parts/face.scad>
include <parts/hood.scad>

part = "checks";

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
else if (part == "face") face_center(lip_or + wall);   // face-center preview
else assert(false, str("unknown part: ", part));
