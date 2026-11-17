// Talon controller housing. Select a part with -D 'part="..."'.
include <lib/params.scad>
include <lib/checks.scad>

part = "checks";

if (part == "checks") cube(1);   // checks ran above; emit something exportable
else assert(false, str("unknown part: ", part));
