"""Traces the 5L3B logo (a flat JPG) into polygons, one group per animated part.

Writes shapes.json:
  bbox   [x, y, w, h] of the logo in the original 1600px picture
  ball   {cx, cy, r}  circle of the ball, relative to bbox
  parts  [{name, color, contours: [[x0, y0, x1, y1, ...], ...]}]  relative to bbox
"""
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi
from skimage import draw, measure

SRC = sys.argv[1]
OUT = sys.argv[2]
S = 2  # work at twice the size: the edges come out smoother
PAL = {
    'navy': (10, 43, 96),
    'blue': (5, 79, 186),
    'green': (141, 198, 65),
}
HEX = {'navy': '0A2B60', 'blue': '054FBA', 'green': '8DC641'}

img = Image.open(SRC).convert('RGB')
big = img.resize((img.width * S, img.height * S), Image.LANCZOS)
a = np.asarray(big).astype(np.float64)
H, W, _ = a.shape

# Where the logo is, in the original picture.
fg0 = np.asarray(img).min(2) < 235
ys, xs = np.where(fg0)
BX0, BY0, BX1, BY1 = xs.min() - 2, ys.min() - 2, xs.max() + 3, ys.max() + 3
BW, BH = BX1 - BX0, BY1 - BY0

# 1. Which color is each solid pixel? Decide on the cores only (edges are mixed with white).
fg = a.min(2) < 200
dist = np.stack([((a - np.array(c)) ** 2).sum(2) for c in PAL.values()], 0)
nearest = dist.argmin(0)
core = ndi.binary_erosion(fg, iterations=4 * S // 2 + 1)

cover = {}
region = {}
for i, (name, rgb) in enumerate(PAL.items()):
    c = np.array(rgb, dtype=np.float64)
    v = 255.0 - c
    # How much of the pixel is this color, if it is mixed with white.
    alpha = np.clip(((255.0 - a) @ v) / (v @ v), 0, 1)
    own_core = core & (nearest == i)
    near = ndi.distance_transform_edt(~own_core) <= 3 * S
    cover[name] = alpha * near
    region[name] = own_core


def smooth(m):
    return ndi.gaussian_filter(m, 0.7)


def components(name, min_area):
    mask = cover[name] >= 0.5
    lab, n = ndi.label(mask, structure=np.ones((3, 3)))
    out = []
    for k in range(1, n + 1):
        area = (lab == k).sum() / (S * S)
        if area < min_area:
            continue
        out.append(k)
    return lab, out


def trace(soft, keep, tol=0.55):
    """Polygons (original pixels, relative to the logo) around the 0.5 level of `soft`."""
    ys_, xs_ = np.where(keep)
    y0, y1 = max(ys_.min() - 6, 0), min(ys_.max() + 7, H)
    x0, x1 = max(xs_.min() - 6, 0), min(xs_.max() + 7, W)
    m = smooth(soft[y0:y1, x0:x1] * keep[y0:y1, x0:x1])
    polys = []
    for c in measure.find_contours(m, 0.5):
        c = measure.approximate_polygon(c, tol)
        if len(c) < 4:
            continue
        pts = []
        for r, q in c[:-1]:
            pts.append(round(((q + x0 + 0.5) / S) - BX0, 2))
            pts.append(round(((r + y0 + 0.5) / S) - BY0, 2))
        polys.append(pts)
    return polys


def polygon_area(p):
    xs_ = np.array(p[0::2])
    ys_ = np.array(p[1::2])
    return 0.5 * abs(np.dot(xs_, np.roll(ys_, 1)) - np.dot(ys_, np.roll(xs_, 1)))


parts = []

# 2. The ball: every navy and blue piece left of the letters.
ball_pts = []
for name in ('navy', 'blue'):
    lab, ids = components(name, 40)
    for k in ids:
        comp = lab == k
        cy, cx = ndi.center_of_mass(comp)
        if cx / S > 640:
            continue
        keep = ndi.binary_dilation(comp, iterations=3 * S)
        polys = trace(cover[name], keep)
        polys = [p for p in polys if polygon_area(p) > 6]
        parts.append({'name': f'ball_{name}', 'color': HEX[name], 'contours': polys})
        for p in polys:
            ball_pts += list(zip(p[0::2], p[1::2]))

pts = np.array(ball_pts)
left, top, bottom = pts[:, 0].min(), pts[:, 1].min(), pts[:, 1].max()
r = (bottom - top) / 2
ball = {'cx': round(left + r, 2), 'cy': round((top + bottom) / 2, 2), 'r': round(r, 2)}

# 2b. The ball as it would be without the 5 on it. In the logo the 5 (and the
# white line round it) bites a piece out of the ball; while the ball is on its
# own that piece is filled, as one more big navy patch, and the white seams
# between the patches are kept.
yy, xx = np.mgrid[0:H, 0:W]
cxp = (ball['cx'] + BX0) * S
cyp = (ball['cy'] + BY0) * S
inside = (xx - cxp) ** 2 + (yy - cyp) ** 2 <= (ball['r'] * S - 0.5 * S) ** 2
patches = np.zeros((H, W), dtype=bool)
for name in ('navy', 'blue'):
    lab_b, ids_b = components(name, 40)
    for k in ids_b:
        comp = lab_b == k
        cy_, cx_ = ndi.center_of_mass(comp)
        if cx_ / S <= 640:
            patches |= comp
free = inside & ~patches
SEAM = 9 * S
yg, xg = np.mgrid[-SEAM:SEAM + 1, -SEAM:SEAM + 1]
disk = (xg ** 2 + yg ** 2) <= SEAM ** 2
opened = ndi.binary_opening(free, structure=disk)  # the seams are thinner than the disk
lab_o, n_o = ndi.label(opened)
sizes = ndi.sum(opened, lab_o, range(1, n_o + 1))
big = lab_o == (int(np.argmax(sizes)) + 1)
# A seam's width away from the patches, but all the way to the edge of the ball.
gap = ndi.distance_transform_edt(~patches) >= 10 * S
fill = (big & gap).astype(np.float64)
fill_polys = [p for p in trace(fill, ndi.binary_dilation(fill > 0.5, iterations=4)) if polygon_area(p) > 20]
parts.append({'name': 'ball_fill', 'color': HEX['navy'], 'contours': fill_polys})

# 3. The letters L, 3, B (navy, right of the ball), left to right.
lab, ids = components('navy', 400)
letters = []
for k in ids:
    comp = lab == k
    cy, cx = ndi.center_of_mass(comp)
    if cx / S > 640:
        letters.append((cx, comp))
letters.sort(key=lambda t: t[0])
assert len(letters) == 3, len(letters)
for (cx, comp), name in zip(letters, ('L', '3', 'B')):
    keep = ndi.binary_dilation(comp, iterations=3 * S)
    polys = [p for p in trace(cover['navy'], keep) if polygon_area(p) > 6]
    parts.append({'name': name, 'color': HEX['navy'], 'contours': polys})

# 4. The green: the 5, and the stroke that shoots out of its top bar.
CUT_X, CUT_Y, LAP = 560, 715, 3  # original pixels
yy, xx = np.mgrid[0:H, 0:W]
rect = ((xx / S + BX0 * 0) >= CUT_X) & ((yy / S) < CUT_Y)
rect_lap = ((xx / S) >= CUT_X - LAP) & ((yy / S) < CUT_Y + LAP)
green = cover['green']
lab, ids = components('green', 400)
assert len(ids) == 1, ids
keep_all = ndi.binary_dilation(lab == ids[0], iterations=3 * S)
five = trace(green * ~rect, keep_all & ~rect)
swoosh = trace(green * rect_lap, keep_all & rect_lap)
parts.append({'name': 'five', 'color': HEX['green'],
              'contours': [p for p in five if polygon_area(p) > 6]})
parts.append({'name': 'swoosh', 'color': HEX['green'],
              'contours': [p for p in swoosh if polygon_area(p) > 2]})

json.dump({'bbox': [int(BX0), int(BY0), int(BW), int(BH)], 'ball': ball, 'parts': parts},
          open(OUT, 'w'))

# Report, and a picture to compare with the original.
total = 0
for p in parts:
    n = sum(len(c) // 2 for c in p['contours'])
    total += n
    print(f"{p['name']:12s} {len(p['contours'])} contours {n} points")
print('total points', total, 'bbox', (BX0, BY0, BW, BH), 'ball', ball)

rend = np.zeros((BH * 2, BW * 2, 3), dtype=np.uint8) + 255
for p in parts:
    col = np.array([int(p['color'][i:i + 2], 16) for i in (0, 2, 4)], dtype=np.uint8)
    m = np.zeros((BH * 2, BW * 2), dtype=bool)
    for c in p['contours']:
        rr, cc = draw.polygon(np.array(c[1::2]) * 2, np.array(c[0::2]) * 2, m.shape)
        m[rr, cc] ^= True
    rend[m] = col
Image.fromarray(rend).save(OUT.replace('.json', '_render.png'))

orig = img.crop((BX0, BY0, BX1, BY1)).resize((BW * 2, BH * 2), Image.LANCZOS)
diff = np.abs(np.asarray(orig).astype(int) - rend.astype(int)).sum(2)
print('pixels off by more than 120:', int((diff > 120).sum()), 'of', diff.size)
Image.fromarray(np.clip(diff, 0, 255).astype(np.uint8)).save(OUT.replace('.json', '_diff.png'))
