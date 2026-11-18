"""Turn a flat-shaded OpenSCAD render into a line drawing.

Usage: python3 -I lineart.py in.png out.png
Black edges wherever colour or shade changes; parts keep a pale tint, and
saturated accent colours keep most of their strength.
"""
import sys
from PIL import Image, ImageChops, ImageFilter

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
# Edges on each channel, combined: catches both shading and colour changes.
edges = None
for ch in im.split():
    e = ch.filter(ImageFilter.FIND_EDGES)
    edges = e if edges is None else ImageChops.lighter(edges, e)
mask = edges.point(lambda v: 255 if v > 18 else 0).filter(ImageFilter.MaxFilter(3))
# Tint: blend toward white, less for saturated (accent) pixels.
hsv = im.convert("HSV")
sat = hsv.split()[1]
white = Image.new("RGB", im.size, (255, 255, 255))
pale = Image.blend(white, im, 0.35)
strong = Image.blend(white, im, 0.85)
keep = sat.point(lambda v: 255 if v > 110 else 0)
base = Image.composite(strong, pale, keep)
black = Image.new("RGB", im.size, (25, 25, 30))
out = Image.composite(black, base, mask)
w, h = out.size
out.resize((w // 2, h // 2), Image.LANCZOS).save(dst)
