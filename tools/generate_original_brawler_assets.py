#!/usr/bin/env python3
"""
tools/generate_original_brawler_assets.py

100% original character sprite generator. No downloaded art, no AI.
Draws proportional arcade brawlers from a skeletal pose system using tapered
polygons, joint discs, multi-tone shading, hair, gloves, boots and fabric folds.
Renders at 4x then LANCZOS-downsamples for smooth, non-boxed curves.

Sheets (2048x96, 16 frames @ 128x96):
  idle 0..3, walk 4..9, jab 10..11, hook 12..13, upper 14..15
"""

import math
from PIL import Image, ImageDraw

SS = 4          # supersample factor
FW, FH = 128, 96
OL = (10, 8, 14, 255)


def hexc(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def shade(c, f):
    """f<0 darken, f>0 lighten."""
    r, g, b, a = c
    if f < 0:
        k = 1 + f
        return (int(r * k), int(g * k), int(b * k), a)
    return (int(r + (255 - r) * f), int(g + (255 - g) * f), int(b + (255 - b) * f), a)


def make_pal(skin, shirt, pants, gloves, hair, boots, eye):
    return {
        'skin': hexc(skin), 'skin_shade': shade(hexc(skin), -0.28),
        'shirt': hexc(shirt), 'shirt_shade': shade(hexc(shirt), -0.30),
        'pants': hexc(pants), 'pants_shade': shade(hexc(pants), -0.30),
        'gloves': hexc(gloves), 'gloves_shade': shade(hexc(gloves), -0.28),
        'hair': hexc(hair), 'hair_shade': shade(hexc(hair), -0.30),
        'boots': hexc(boots), 'boots_shade': shade(hexc(boots), -0.30),
        'eye': hexc(eye), 'belt': hexc('#3a2a20'), 'outline': OL,
    }


PLAYER = make_pal('#e6a97c', '#f2f4f8', '#33446b', '#cf2b2b', '#2a2026', '#1c1c22', '#2b6cb0')
ENEMY = make_pal('#d99a70', '#3f7a4a', '#33343d', '#202027', '#e0722c', '#15151a', '#d0332b')
BOSS = make_pal('#ecc0a6', '#1a1b22', '#1a1b22', '#141419', '#c9d0dd', '#0e0e12', '#f0b429')


# ----------------------------------------------------------------------------
# Painter
# ----------------------------------------------------------------------------
class Painter:
    def __init__(self):
        self.im = Image.new('RGBA', (FW * SS, FH * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
        self.ow = max(1, int(1.05 * SS))

    def sp(self, p):
        return (p[0] * SS, p[1] * SS)

    def line(self, pts, fill, width=1):
        self.d.line([self.sp(p) for p in pts], fill=fill,
                    width=max(1, int(width * SS)), joint='curve')

    def poly(self, pts, fill, outline=None):
        p = [self.sp(q) for q in pts]
        self.d.polygon(p, fill=fill)
        if outline:
            self.d.line(p + [p[0]], fill=outline, width=self.ow, joint='curve')

    def ellipse(self, box, fill, outline=None):
        b = tuple(v * SS for v in box)
        self.d.ellipse(b, fill=fill, outline=outline, width=self.ow if outline else 0)

    def capsule(self, a, b, wa, wb, base, shadow):
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = max(1e-3, math.hypot(dx, dy))
        nx, ny = -dy / L, dx / L
        quad = [
            (a[0] + nx * wa, a[1] + ny * wa),
            (b[0] + nx * wb, b[1] + ny * wb),
            (b[0] - nx * wb, b[1] - ny * wb),
            (a[0] - nx * wa, a[1] - ny * wa),
        ]
        self.poly(quad, base)
        # shading strip on the lower/right side
        s = [
            (a[0] + nx * wa * 0.25, a[1] + ny * wa * 0.25),
            (b[0] + nx * wb * 0.25, b[1] + ny * wb * 0.25),
            (b[0] - nx * wb, b[1] - ny * wb),
            (a[0] - nx * wa, a[1] - ny * wa),
        ]
        self.poly(s, shadow)
        # outline on the quad
        p = [self.sp(q) for q in quad]
        self.d.line(p + [p[0]], fill=OL, width=self.ow, joint='curve')
        # rounded joints
        for c, r in ((a, wa), (b, wb)):
            self.ellipse((c[0] - r, c[1] - r, c[0] + r, c[1] + r), base, OL)

    def finish(self):
        return self.im.resize((FW, FH), Image.LANCZOS)


# ----------------------------------------------------------------------------
# Skeleton / poses
# ----------------------------------------------------------------------------
def base_pose():
    return dict(
        pelvis=(64, 57), chest=(64, 39), neck=(64, 29), head=(66, 19),
        sh_b=(58, 37), el_b=(53, 45), ha_b=(60, 34),
        sh_f=(71, 37), el_f=(78, 45), ha_f=(74, 33),
        hip_b=(59, 57), kn_b=(56, 73), ft_b=(51, 88),
        hip_f=(69, 57), kn_f=(72, 73), ft_f=(77, 88),
    )


def pose(**kw):
    p = base_pose()
    p.update(kw)
    return p


def lerp_pose(a, b, t):
    out = {}
    for k in a:
        ax, ay = a[k]
        bx, by = b[k]
        out[k] = (ax + (bx - ax) * t, ay + (by - ay) * t)
    return out


IDLE_A = pose()
IDLE_B = pose(
    chest=(64, 38), neck=(64, 28), head=(66, 18),
    sh_b=(58, 36), el_b=(53, 44), ha_b=(60, 33),
    sh_f=(71, 36), el_f=(78, 44), ha_f=(74, 32),
)

WALK_A = pose(  # front stride
    chest=(66, 39), head=(68, 18),
    kn_f=(80, 70), ft_f=(86, 87), kn_b=(54, 76), ft_b=(46, 86),
    el_f=(70, 50), ha_f=(66, 43), el_b=(56, 42), ha_b=(61, 34),
)
WALK_B = pose(  # back stride
    chest=(62, 39), head=(64, 18),
    kn_b=(74, 70), ft_b=(80, 87), kn_f=(52, 76), ft_f=(46, 86),
    el_b=(72, 50), ha_b=(68, 43), el_f=(56, 42), ha_f=(61, 34),
)

JAB_W = pose(  # windup — coil back
    chest=(60, 40), head=(63, 19),
    sh_f=(69, 38), el_f=(64, 47), ha_f=(66, 40),
    sh_b=(57, 37), el_b=(52, 46), ha_b=(58, 35),
    kn_f=(76, 72), ft_f=(82, 88), kn_b=(54, 74), ft_b=(50, 88),
)
JAB_S = pose(  # snap — straight arm out
    chest=(68, 38), head=(72, 18),
    sh_f=(72, 36), el_f=(88, 37), ha_f=(105, 38),
    sh_b=(59, 38), el_b=(56, 48), ha_b=(60, 35),
    kn_f=(80, 70), ft_f=(88, 87), kn_b=(52, 75), ft_b=(46, 88),
)

HOOK_W = pose(  # coil
    chest=(59, 40), head=(61, 18),
    sh_f=(68, 37), el_f=(62, 46), ha_f=(57, 37),
    sh_b=(56, 37), el_b=(52, 45), ha_b=(56, 33),
)
HOOK_S = pose(  # swing across
    chest=(70, 38), head=(74, 19),
    sh_f=(74, 36), el_f=(93, 31), ha_f=(101, 23),
    sh_b=(60, 39), el_b=(58, 50), ha_b=(62, 39),
    kn_f=(80, 70), ft_f=(86, 87), kn_b=(52, 75), ft_b=(46, 88),
)

UP_C = pose(  # deep crouch
    pelvis=(64, 62), chest=(64, 46), neck=(64, 35), head=(66, 27),
    sh_f=(71, 44), el_f=(72, 54), ha_f=(67, 57),
    sh_b=(57, 44), el_b=(54, 54), ha_b=(58, 55),
    hip_b=(59, 62), hip_f=(69, 62),
    kn_f=(74, 76), ft_f=(78, 88), kn_b=(54, 78), ft_b=(50, 88),
)
UP_R = pose(  # rise, uppercut driving up
    pelvis=(65, 55), chest=(66, 34), neck=(66, 24), head=(68, 12),
    sh_f=(72, 33), el_f=(84, 19), ha_f=(92, 5),
    sh_b=(58, 35), el_b=(54, 46), ha_b=(56, 37),
    kn_f=(77, 70), ft_f=(83, 86), kn_b=(54, 74), ft_b=(48, 88),
)


def frames():
    mid_ab = lerp_pose(WALK_A, WALK_B, 0.5)
    return [
        IDLE_A, IDLE_B, IDLE_A, IDLE_B,
        WALK_A, mid_ab, WALK_B, WALK_B, mid_ab, WALK_A,
        JAB_W, JAB_S,
        HOOK_W, HOOK_S,
        UP_C, UP_R,
    ]


# ----------------------------------------------------------------------------
# Drawing
# ----------------------------------------------------------------------------
def draw_arm(p, s, pal, back):
    if back:
        a, e, h = s['sh_b'], s['el_b'], s['ha_b']
        skin, skin_s = pal['skin_shade'], shade(pal['skin'], -0.40)
    else:
        a, e, h = s['sh_f'], s['el_f'], s['ha_f']
        skin, skin_s = pal['skin'], pal['skin_shade']
    p.capsule(a, e, 5.4, 4.4, skin, skin_s)
    p.capsule(e, h, 4.4, 3.6, skin, skin_s)
    # glove / forearm wrap
    g = pal['gloves']
    p.ellipse((h[0] - 5, h[1] - 5, h[0] + 5, h[1] + 5), g, OL)
    p.ellipse((h[0] - 2, h[1] - 3, h[0] + 2, h[1] - 1), shade(g, 0.35))


def draw_leg(p, s, pal, back):
    if back:
        hp, kn, ft = s['hip_b'], s['kn_b'], s['ft_b']
        base, bs = pal['pants_shade'], shade(pal['pants'], -0.42)
        boot, boots = pal['boots_shade'], shade(pal['boots'], -0.40)
    else:
        hp, kn, ft = s['hip_f'], s['kn_f'], s['ft_f']
        base, bs = pal['pants'], pal['pants_shade']
        boot, boots = pal['boots'], pal['boots_shade']
    p.capsule(hp, kn, 7.2, 5.4, base, bs)
    p.capsule(kn, ft, 5.4, 4.2, base, bs)
    # boot: block toe pointing forward (+x)
    p.poly([
        (ft[0] - 4, ft[1] - 5), (ft[0] + 4, ft[1] - 5),
        (ft[0] + 10, ft[1] + 2), (ft[0] + 9, ft[1] + 4),
        (ft[0] - 5, ft[1] + 4),
    ], boot, OL)
    p.line([(ft[0] - 3, ft[1] + 1), (ft[0] + 8, ft[1] + 1)], boots, 1)


def draw_torso(p, s, pal, variant):
    sb, sf = s['sh_b'], s['sh_f']
    hp, hf = s['hip_b'], s['hip_f']
    ch, pe, nk = s['chest'], s['pelvis'], s['neck']
    # torso quad with waist taper
    quad = [
        (sb[0] - 3, sb[1] - 2), (sf[0] + 3, sf[1] - 2),
        (hf[0] + 4, hf[1] + 3), (hp[0] - 4, hp[1] + 3),
    ]
    p.poly(quad, pal['shirt'], OL)
    # side shading
    p.poly([
        (ch[0] + 1, ch[1] - 2), (sf[0] + 3, sf[1] - 2),
        (hf[0] + 4, hf[1] + 3), (ch[0] + 2, pe[1] + 2),
    ], pal['shirt_shade'])
    # chest / collar opening
    p.poly([
        (nk[0] - 4, nk[1] + 1), (nk[0] + 4, nk[1] + 1),
        (ch[0] + 2, ch[1] + 5), (ch[0] - 3, ch[1] + 4),
    ], pal['skin_shade'], OL)
    # fabric folds
    p.line([(ch[0] - 4, ch[1] + 7), (ch[0] - 3, pe[1] - 2)], pal['shirt_shade'], 1)
    p.line([(hp[0] + 1, pe[1] - 5), (hp[0] + 2, pe[1] - 1)], pal['pants_shade'], 1)
    # belt
    p.poly([
        (hp[0] - 4, pe[1]), (hf[0] + 4, pe[1]),
        (hf[0] + 4, pe[1] + 4), (hp[0] - 4, pe[1] + 4),
    ], pal['belt'], OL)
    p.poly([(ch[0] - 2, pe[1]), (ch[0] + 2, pe[1]), (ch[0] + 2, pe[1] + 4), (ch[0] - 2, pe[1] + 4)],
           shade(pal['belt'], 0.45))


def draw_head(p, s, pal, variant):
    hx, hy = s['head']
    # neck
    p.poly([(s['neck'][0] - 3, s['neck'][1]), (s['neck'][0] + 3, s['neck'][1]),
            (s['neck'][0] + 3, s['neck'][1] + 4), (s['neck'][0] - 3, s['neck'][1] + 4)],
           pal['skin_shade'], OL)
    # cranium
    p.ellipse((hx - 9, hy - 10, hx + 9, hy + 8), pal['skin'], OL)
    # jaw
    p.poly([(hx - 6, hy + 3), (hx + 7, hy + 3), (hx + 4, hy + 10), (hx - 3, hy + 10)],
           pal['skin'], OL)
    # ear
    p.ellipse((hx - 10, hy - 1, hx - 7, hy + 3), pal['skin_shade'], OL)
    # hair by variant
    if variant == 'enemy':        # mohawk
        p.poly([(hx - 8, hy - 5), (hx - 3, hy - 16), (hx, hy - 6),
                (hx + 4, hy - 15), (hx + 8, hy - 5), (hx + 6, hy - 3), (hx - 7, hy - 3)],
               pal['hair'], OL)
    elif variant == 'boss':       # slicked silver, swept back
        p.poly([(hx - 9, hy - 4), (hx - 6, hy - 10), (hx + 2, hy - 12),
                (hx + 10, hy - 9), (hx + 9, hy - 4), (hx + 4, hy - 6), (hx - 6, hy - 4)],
               pal['hair'], OL)
        p.line([(hx - 5, hy - 8), (hx + 6, hy - 8)], pal['hair_shade'], 2)
    else:                          # spiky dark
        p.poly([(hx - 9, hy - 4), (hx - 6, hy - 11), (hx - 2, hy - 6),
                (hx + 1, hy - 12), (hx + 5, hy - 6), (hx + 9, hy - 10), (hx + 9, hy - 3),
                (hx - 8, hy - 3)], pal['hair'], OL)
    # face: brow + eye, facing right
    p.line([(hx + 2, hy - 1), (hx + 7, hy - 2)], OL, 1)
    p.ellipse((hx + 3, hy, hx + 6, hy + 3), pal['eye'], OL)
    if variant == 'boss':          # sunglasses
        p.poly([(hx - 1, hy - 1), (hx + 9, hy - 2), (hx + 9, hy + 3), (hx - 1, hy + 3)], OL)
        p.line([(hx + 4, hy - 1), (hx + 4, hy + 3)], pal['hair'], 1)
    # mouth / jaw line
    p.line([(hx + 2, hy + 6), (hx + 6, hy + 5)], pal['skin_shade'], 1)


def render(pose_def, pal, variant):
    p = Painter()
    draw_leg(p, pose_def, pal, back=True)
    draw_arm(p, pose_def, pal, back=True)
    draw_torso(p, pose_def, pal, variant)
    draw_head(p, pose_def, pal, variant)
    draw_leg(p, pose_def, pal, back=False)
    draw_arm(p, pose_def, pal, back=False)
    return p.finish()


def make_sheet(pal, variant, out_path):
    fr = frames()
    sheet = Image.new('RGBA', (FW * len(fr), FH), (0, 0, 0, 0))
    for i, s in enumerate(fr):
        sheet.paste(render(s, pal, variant), (i * FW, 0))
    sheet.save(out_path)
    print(f"generated {out_path} {sheet.size} frames={len(fr)}")


def main():
    make_sheet(PLAYER, 'player', 'assets/sprites/original_player_sheet.png')
    make_sheet(ENEMY, 'enemy', 'assets/sprites/original_enemy_sheet.png')
    make_sheet(BOSS, 'boss', 'assets/sprites/original_boss_sheet.png')


if __name__ == '__main__':
    main()
