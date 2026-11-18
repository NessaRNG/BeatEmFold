#!/usr/bin/env python3
"""
tools/generate_original_backgrounds.py

100% original, code-drawn layered pixel-art backgrounds for Beat 'Em Fold.
3 stages x 3 layers (far / mid / near) = 9 PNGs, each 1280x720 RGBA with alpha.

Stage 0 ALLEY  - night rain, red brick, wet asphalt, neon reflections
Stage 1 ROOFTOP- sunset, city silhouette, water tower, AC, gravel
Stage 2 BAR    - neon interior, wood panels, bottle shelves, stage lights

No downloaded art, no AI. Deterministic per-stage seeds.
Layers stack in stage_bg.gd: far -> mid -> near. Lane y 430..600 stays clean.
"""

import math
import random
from PIL import Image, ImageDraw

W, H = 1280, 720


def new():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def hx(c):
    c = c.lstrip('#')
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def lerp(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) if i < 3 else 255 for i in range(4))


def grad(img, y0, y1, top, bottom, curve=1.0):
    d = ImageDraw.Draw(img)
    for y in range(y0, y1):
        t = ((y - y0) / max(1, y1 - y0 - 1)) ** curve
        d.line([(0, y), (W, y)], fill=lerp(top, bottom, t))


def rect(d, x, y, w, h, c):
    d.rectangle([int(x), int(y), int(x + w), int(y + h)], fill=c)


def overlay(im, painter):
    """Draw semi-transparent shapes on a separate layer, then alpha-composite.
    ImageDraw.draw on an opaque image REPLACES pixels (ignores alpha), so glows
    must be composited to blend correctly instead of punching dark holes."""
    tmp = Image.new("RGBA", im.size, (0, 0, 0, 0))
    painter(ImageDraw.Draw(tmp))
    im.alpha_composite(tmp)


# --------------------------------------------------------------------------- ALLEY
def alley_far():
    im = new()
    grad(im, 0, 400, hx('080a1a'), hx('2a1b3d'), 1.4)
    d = ImageDraw.Draw(im)
    rng = random.Random(7)
    # moon + halo (composited so translucent rings blend, not replace)
    def _moon(td):
        for r, a in [(70, 26), (48, 48), (30, 90)]:
            td.ellipse([600 - r, 96 - r, 600 + r, 96 + r], fill=(220, 225, 255, a))
        td.ellipse([566, 76, 612, 116], fill=(210, 218, 255, 120))
    overlay(im, _moon)
    d.ellipse([576, 72, 624, 120], fill=hx('e8ecff'))
    # distant skyline two bands
    for band, base_y, col, lit in [
        (0, 360, hx('15162e'), (255, 200, 110, 90)),
        (1, 400, hx('0f1024'), (120, 180, 255, 90)),
    ]:
        x = -20
        while x < W:
            bw = rng.randint(70, 170)
            bh = rng.randint(90, 260) - band * 40
            rect(d, x, base_y - bh, bw, bh, col)
            for wy in range(base_y - bh + 12, base_y - 8, 15):
                for wx in range(x + 8, x + bw - 8, 14):
                    if rng.random() < 0.22:
                        rect(d, wx, wy, 5, 7, lit)
            x += bw + rng.randint(6, 26)
    # rain streaks
    for _ in range(260):
        x = rng.randrange(W)
        y = rng.randrange(0, 400)
        d.line([(x, y), (x - 3, y + 16)], fill=(150, 170, 220, rng.randint(14, 40)), width=1)
    return im


def alley_mid():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(11)
    # brick wall 170..430
    rect(d, 0, 170, W, 270, hx('241a20'))
    bh, bw = 15, 46
    for row, y in enumerate(range(170, 440, bh)):
        off = bw // 2 if row % 2 else 0
        x = -bw
        while x < W:
            v = rng.randint(-10, 16)
            brick = (150 + v, 74 + v // 2, 52 + v // 2, 255)
            rect(d, x + off + 1, y + 1, bw - 2, bh - 2, brick)
            # mortar shading
            d.line([(x + off + 1, y + 1), (x + off + bw - 1, y + 1)], fill=(190, 110, 80, 90))
            x += bw
    # soot / grime verticals
    for gx in [90, 470, 940, 1180]:
        grad_band = ImageDraw.Draw(im)
        for i in range(9):
            grad_band.line([(gx + i, 170), (gx + i, 430)], fill=(0, 0, 0, rng.randint(0, 16)))
    # fire escape silhouette right
    rect(d, 1080, 200, 150, 6, hx('0d0d14'))
    rect(d, 1080, 300, 150, 6, hx('0d0d14'))
    for px in [1090, 1210]:
        rect(d, px, 200, 6, 240, hx('0d0d14'))
    for sx in range(1084, 1230, 10):
        rect(d, sx, 206, 3, 94, (20, 20, 30, 180))
    # pipes
    for px in [150, 1130]:
        rect(d, px, 170, 22, 270, hx('14141c'))
        d.line([(px + 4, 170), (px + 4, 440)], fill=(255, 255, 255, 18))
    # posters
    for (px, py, pw, ph) in [(300, 250, 70, 92), (392, 268, 52, 70)]:
        rect(d, px - 2, py - 2, pw + 4, ph + 4, hx('0b0b10'))
        rect(d, px, py, pw, ph, hx('cfc8b0'))
        rect(d, px + 7, py + 9, pw - 14, 13, hx('8a2f3c'))
        rect(d, px + 7, py + 28, pw - 14, 4, hx('2b2b33'))
        rect(d, px + 7, py + 38, pw - 22, 4, hx('2b2b33'))
        rect(d, px + 7, py + 48, pw - 18, 4, hx('2b2b33'))
    # ledge / sidewalk top
    rect(d, 0, 430, W, 12, hx('2b2b3a'))
    rect(d, 0, 430, W, 3, hx('3a3a4c'))
    return im


def alley_near():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(13)
    # wet asphalt 442..720
    rect(d, 0, 442, W, 278, hx('12131f'))
    for i in range(2600):
        x = rng.randrange(W)
        y = rng.randrange(442, 720)
        c = (255, 255, 255, rng.randint(2, 10)) if i % 2 else (0, 0, 0, rng.randint(10, 28))
        rect(d, x, y, 2, 2, c)
    # puddle neon reflections (smeared vertical streaks, composited)
    def _puddles(td):
        for cx, col, ww in [(860, (255, 95, 210), 120), (200, (90, 255, 210), 70),
                            (1150, (255, 233, 168), 60)]:
            for k in range(10):
                y = 470 + k * 22
                half = int(ww * (0.35 + 0.65 * (k / 10)))
                a = 40 - k * 3
                rect(td, cx - half, y, half * 2, 8, (col[0], col[1], col[2], max(2, a)))
    overlay(im, _puddles)
    d = ImageDraw.Draw(im)
    # cracks
    for _ in range(14):
        x = rng.randrange(W)
        y = rng.randrange(470, 690)
        d.line([(x, y), (x + rng.randint(-30, 30), y + rng.randint(10, 40))], fill=(0, 0, 0, 60))
    # lane curb lines mark playable band edges faintly
    rect(d, 0, 428, W, 3, (180, 190, 220, 26))
    rect(d, 0, 606, W, 3, (180, 190, 220, 22))
    return im


# --------------------------------------------------------------------------- ROOFTOP
def rooftop_far():
    im = new()
    grad(im, 0, 430, hx('2a1238'), hx('e0632a'), 1.5)
    d = ImageDraw.Draw(im)
    rng = random.Random(21)
    # hazy sun
    def _sun(td):
        for r, a in [(120, 22), (84, 40), (58, 80)]:
            td.ellipse([640 - r, 250 - r, 640 + r, 250 + r], fill=(255, 210, 90, a))
    overlay(im, _sun)
    d.ellipse([596, 206, 684, 294], fill=hx('ffd970'))
    def _sunbands(td):
        for y in range(258, 292, 9):
            rect(td, 580, y, 120, 3, (230, 120, 40, 150))
    overlay(im, _sunbands)
    # city silhouette
    x = -20
    while x < W:
        bw = rng.randint(80, 190)
        bh = rng.randint(70, 210)
        rect(d, x, 400 - bh, bw, bh, hx('2a1a2e'))
        for wy in range(400 - bh + 10, 392, 17):
            for wx in range(x + 9, x + bw - 9, 16):
                if rng.random() < 0.2:
                    rect(d, wx, wy, 5, 7, (255, 190, 90, rng.randint(60, 130)))
        x += bw + rng.randint(8, 30)
    return im


def rooftop_mid():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(23)
    # parapet + railing
    rect(d, 0, 360, W, 70, hx('2b2436'))
    rect(d, 0, 360, W, 6, hx('3b3450'))
    for px in range(0, W, 52):
        rect(d, px, 330, 5, 100, hx('171420'))
    rect(d, 0, 330, W, 7, hx('3b3450'))
    # water tower left
    rect(d, 90, 232, 110, 128, hx('4a3a30'))
    rect(d, 100, 220, 90, 16, hx('5a4a3c'))
    d.ellipse([90, 232, 200, 258], fill=(90, 70, 56, 255))
    for i in range(3):
        rect(d, 100 + i * 34, 360, 9, 70, hx('2a2018'))
    # AC units
    for (ax, ay) in [(950, 382), (1030, 392), (430, 392)]:
        rect(d, ax, ay, 58, 42, hx('3c4250'))
        rect(d, ax + 6, ay + 6, 46, 6, (0, 0, 0, 90))
        for c in range(3):
            rect(d, ax + 8 + c * 14, ay + 18, 10, 18, hx('272c38'))
    # antenna
    rect(d, 700, 210, 6, 150, hx('101018'))
    rect(d, 678, 220, 48, 5, hx('101018'))
    rect(d, 698, 204, 12, 12, hx('ff5a5a'))
    return im


def rooftop_near():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(29)
    rect(d, 0, 430, W, 290, hx('242031'))
    for i in range(3000):
        x = rng.randrange(W)
        y = rng.randrange(430, 720)
        rect(d, x, y, 2, 2, (255, 255, 255, rng.randint(2, 9)) if i % 2 else (0, 0, 0, rng.randint(8, 22)))
    # gravel speckles warm from sunset
    for _ in range(500):
        x = rng.randrange(W)
        y = rng.randrange(430, 720)
        rect(d, x, y, 2, 2, (255, 150, 80, rng.randint(4, 14)))
    rect(d, 0, 428, W, 3, (255, 180, 110, 30))
    rect(d, 0, 606, W, 3, (255, 180, 110, 24))
    return im


# --------------------------------------------------------------------------- BAR
def bar_far():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(31)
    rect(d, 0, 0, W, 440, hx('160f18'))
    # wood panels
    for px in range(0, W, 88):
        v = rng.randint(-6, 10)
        rect(d, px + 2, 0, 84, 440, (52 + v, 30 + v, 28 + v, 255))
        rect(d, px + 2, 0, 3, 440, (0, 0, 0, 90))
    # bottle shelves
    for sy in [140, 250]:
        rect(d, 0, sy, W, 12, hx('0c0910'))
        rect(d, 0, sy + 12, W, 4, (0, 0, 0, 90))
    bcols = [hx('3fae5a'), hx('e04040'), hx('4da6ff'), hx('ffd94d')]
    for i in range(28):
        bx = 24 + i * 45 + rng.randint(-5, 5)
        c = bcols[i % 4]
        rect(d, bx, 108, 14, 32, c)
        rect(d, bx + 4, 100, 6, 8, (220, 220, 220, 180))
        rect(d, bx + 2, 218, 14, 32, bcols[(i + 2) % 4])
        rect(d, bx + 6, 210, 6, 8, (220, 220, 220, 180))
    return im


def bar_mid():
    im = new()
    d = ImageDraw.Draw(im)
    # stage light cones (composited)
    def _cones(td):
        for i, col in enumerate([hx('ff5fd2'), hx('5aa9ff'), hx('ffd94d')]):
            lx = 310 + i * 320
            for k in range(7):
                a = 24 - k * 3
                half = 30 + k * 22
                rect(td, lx + 6 - half, 80 + k * 52, half * 2, 52,
                     (col[0], col[1], col[2], max(2, a)))
    overlay(im, _cones)
    d = ImageDraw.Draw(im)
    for i, col in enumerate([hx('ff5fd2'), hx('5aa9ff'), hx('ffd94d')]):
        lx = 310 + i * 320
        rect(d, lx, 0, 12, 62, hx('0d0d14'))
        rect(d, lx - 8, 62, 28, 16, col)
    # hanging lamps
    for lx in [180, 640, 1100]:
        rect(d, lx, 0, 3, 90, hx('0d0d14'))
        d.ellipse([lx - 16, 90, lx + 16, 116], fill=hx('3a2a18'))
        d.ellipse([lx - 10, 96, lx + 10, 110], fill=(255, 220, 150, 220))
    # booth silhouettes back
    for bx in [120, 1020]:
        rect(d, bx, 360, 150, 70, hx('1c100c'))
        rect(d, bx + 10, 350, 130, 12, hx('2e1a12'))
    return im


def bar_near():
    im = new()
    d = ImageDraw.Draw(im)
    rng = random.Random(37)
    rect(d, 0, 430, W, 290, hx('1d130e'))
    # wood floor planks
    for y in range(430, 720, 22):
        rect(d, 0, y, W, 2, (0, 0, 0, 90))
        for x in range(0, W, 96):
            rect(d, x + ((y // 22) % 2) * 48, y, 2, 22, (0, 0, 0, 60))
        for _ in range(18):
            rect(d, rng.randrange(W), rng.randrange(y, min(y + 21, 719)), 3, 2,
                 (255, 190, 120, rng.randint(3, 12)))
    # colored light reflections on floor (composited)
    def _refl(td):
        for i, col in enumerate([hx('ff5fd2'), hx('5aa9ff'), hx('ffd94d')]):
            cx = 310 + i * 320
            for k in range(6):
                rect(td, cx - (20 + k * 14), 610 + k * 16, (40 + k * 28), 8,
                     (col[0], col[1], col[2], max(2, 30 - k * 4)))
        rect(td, 0, 428, W, 3, (255, 120, 200, 40))
    overlay(im, _refl)
    rect(d, 0, 428, W, 3, (255, 120, 200, 26))
    rect(d, 0, 606, W, 3, (255, 120, 200, 20))
    return im


STAGES = {
    'alley': (alley_far, alley_mid, alley_near),
    'rooftop': (rooftop_far, rooftop_mid, rooftop_near),
    'bar': (bar_far, bar_mid, bar_near),
}


def main():
    out_dir = "assets/backgrounds/original"
    import os
    os.makedirs(out_dir, exist_ok=True)
    for stage, layers in STAGES.items():
        for name, fn in zip(['far', 'mid', 'near'], layers):
            im = fn()
            path = f"{out_dir}/{stage}_{name}.png"
            im.save(path)
            print(f"generated {path} {im.size}")


if __name__ == '__main__':
    main()
