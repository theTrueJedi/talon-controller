#!/usr/bin/env bash
# Build the print-and-assembly guide: render figures, line-art them, print
# guide.html to talon-housing-guide.pdf with headless Chrome.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
command -v openscad >/dev/null 2>&1 && OPENSCAD=openscad
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p fig raw
# name | camera rotation rx,ry,rz | projection (p/o) | size WxH
figs="
exploded|62,0,35|p|1600x1800
paint|235,0,20|p|1600x1200
pause|50,0,25|p|1600x1100
c3|45,0,215|p|1600x1200
lip|0,0,0|o|1200x1200
lip_front|0,0,0|o|1600x1200
underside|180,0,0|o|1400x1400
back|11.5,72.4,2,90,0,180,70|o|1600x1100
screws|245,0,30|p|1600x1600
bed_shell|55,0,30|p|1000x900
bed_bottom|55,0,30|p|1000x900
bed_clip|55,0,30|p|1000x900
bed_hood|55,0,30|p|1000x900
bed_cap|55,0,30|p|1000x900
"
for line in $figs; do
    IFS='|' read -r name rot proj size <<<"$line"
    # Three numbers: a view direction, auto-fitted. Seven: an explicit camera.
    case "$rot" in *,*,*,*) cam=(--camera=$rot);; *) cam=(--camera=0,0,0,$rot,0 --viewall --autocenter);; esac
    "$OPENSCAD" --backend=manifold -o "raw/$name.png" -D "fig=\"$name\"" \
        "${cam[@]}" --projection=$proj \
        --imgsize=${size/x/,} --colorscheme=Tomorrow figures.scad >/dev/null 2>"raw/$name.log" \
        || { echo "FAIL fig $name"; tail -5 "raw/$name.log"; exit 1; }
    python3 -I lineart.py "raw/$name.png" "fig/$name.png"
    echo "fig    $name"
done
"$CHROME" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$here/talon-housing-guide.pdf" \
    "file://$here/guide.html" 2>/dev/null
echo "pdf    $here/talon-housing-guide.pdf"
