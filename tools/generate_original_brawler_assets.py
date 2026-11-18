#!/usr/bin/env python3
"""
tools/generate_original_brawler_assets.py  (v2 — arcade anatomy rewrite)

100% original character sprites from scratch. No downloaded art, no AI.
v1 drew stick-figures from capsules with visible ball joints. v2 uses:
  - continuous tapered limbs built from polylines (no joint bubbles)
  - defined deltoids / pectorals / abs / quads via silhouette + inner lines
  - real heads: jaw, ear, eyebrow, eye+ pupil, nose, mouth, styled hair
  - gloves with thumb + knuckle line, boots with toe/sole/laces
  - directional 3-tone shading (base + highlight + shadow bands)
  - fabric folds on shirt/pants, belt with buckle

Layout (unchanged, 29 frames @ 128x96, sheet 3712x96):
  idle 0..5, walk 6..13, jab 14..18, hook 19..23, upper 24..28
"""

import math
from PIL import Image, ImageDraw

SS = 5
FW, FH = 128, 96
OUTLINE = (22, 16, 24, 255)


# ---------------------------------------------------------------------------
# colour helpers
# ---------------------------------------------------------------------------
def hexc(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def shade(c, f):
    r, g, b, a = c
    if f < 0:
        k = 1 + f
        return (int(r * k), int(g * k), int(b * k), a)
    return (int(r + (255 - r) * f), int(g + (255 - g) * f),
            int(b + (255 - b) * f), a)


def make_pal(skin, shirt, pants, gloves, hair, boots, eye):
    return {
        'skin': hexc(skin), 'skin_hi': shade(hexc(skin), 0.18),
        'skin_sh': shade(hexc(skin), -0.28),
        'shirt': hexc(shirt), 'shirt_hi': shade(hexc(shirt), 0.20),
        'shirt_sh': shade(hexc(shirt), -0.32),
        'pants': hexc(pants), 'pants_hi': shade(hexc(pants), 0.16),
        'pants_sh': shade(hexc(pants), -0.30),
        'gloves': hexc(gloves), 'gloves_hi': shade(hexc(gloves), 0.22),
        'gloves_sh': shade(hexc(gloves), -0.28),
        'hair': hexc(hair), 'hair_hi': shade(hexc(hair), 0.28),
        'boots': hexc(boots), 'boots_hi': shade(hexc(boots), 0.20),
        'boots_sh': shade(hexc(boots), -0.32),
        'eye': hexc(eye), 'belt': hexc('#4a3324'),
        'buckle': hexc('#d9b04a'), 'outline': OUTLINE,
    }


PLAYER = make_pal('#e8b08a', '#f4f6fa', '#38507a', '#cd3333', '#33262c', '#1d1d24', '#2f74c0')
ENEMY = make_pal('#d99c72', '#3f7d4c', '#343640', '#222229', '#dd7528', '#16161c', '#d63a30')
BOSS = make_pal('#eec5ad', '#20212a', '#20212a', '#17171d', '#cdd5e2', '#0f0f14', '#f2b436')


# ---------------------------------------------------------------------------
# Painter
# ---------------------------------------------------------------------------
class Painter:
    def __init__(self):
        self.im = Image.new('RGBA', (FW * SS, FH * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
        self.ow = max(1, int(1.25 * SS))

    def sp(self, p):
        return (p[0] * SS, p[1] * SS)

    def poly(self, pts, fill=None, outline=None, width=None):
        p = [self.sp(q) for q in pts]
        if fill is not None:
            self.d.polygon(p, fill=fill)
        if outline is not None:
            self.d.line(p + [p[0]], fill=outline,
                        width=width or self.ow, joint='curve')

    def line(self, pts, color, width=1):
        self.d.line([self.sp(p) for p in pts], fill=color,
                    width=max(1, int(width * SS / 2)), joint='curve')

    def oval(self, box, fill, outline=None, width=None):
        b = tuple(v * SS for v in box)
        self.d.ellipse(b, fill=fill, outline=outline,
                       width=width or self.ow if outline else 0)

    def finish(self):
        return self.im.resize((FW, FH), Image.LANCZOS)


# ---------------------------------------------------------------------------
# geometry: continuous tapered limb from a polyline
# ---------------------------------------------------------------------------
def normals_at(points):
    out = []
    n = len(points)
    for i in range(n):
        if i == 0:
            a, b = points[0], points[1]
        elif i == n - 1:
            a, b = points[-2], points[-1]
        else:
            a, b = points[i - 1], points[i + 1]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1e-6
        out.append((-dy / L, dx / L))
    return out


def offset_line(points, widths, normals, factor):
    return [(p[0] + n[0] * w * factor, p[1] + n[1] * w * factor)
            for p, w, n in zip(points, widths, normals)]


def limb(p, points, widths, base, hi, sh, outline=OUTLINE):
    """Single continuous tapered tube with highlight + shadow bands."""
    norms = normals_at(points)
    left = offset_line(points, widths, norms, 1.0)
    right = offset_line(points, widths, norms, -1.0)
    inner_l = offset_line(points, widths, norms, 0.42)
    inner_r = offset_line(points, widths, norms, -0.42)
    p.poly(left + list(reversed(right)), base)
    p.poly(left + list(reversed(inner_l)), hi)
    p.poly(inner_r + list(reversed(right)), sh)
    p.poly(left + list(reversed(right)), None, outline)


# ---------------------------------------------------------------------------
# poses (same 29-frame schema as v2 smoothing)
# ---------------------------------------------------------------------------
def base_pose():
    return dict(
        pelvis=(64, 57), chest=(64, 40), neck=(64, 30), head=(67, 19),
        sh_b=(56, 38), el_b=(52, 47), ha_b=(61, 35),
        sh_f=(73, 38), el_f=(79, 46), ha_f=(76, 34),
        hip_b=(58, 57), kn_b=(55, 73), ft_b=(50, 88),
        hip_f=(70, 57), kn_f=(73, 73), ft_f=(78, 88),
    )


def pose(**kw):
    q = base_pose()
    q.update(kw)
    return q


def lerp_pose(a, b, t):
    return {k: (a[k][0] + (b[k][0] - a[k][0]) * t,
                a[k][1] + (b[k][1] - a[k][1]) * t) for k in a}


IDLE_A = pose()
IDLE_B = pose(chest=(64, 39), neck=(64, 29), head=(67, 18),
              sh_b=(56, 37), el_b=(52, 46), ha_b=(61, 34),
              sh_f=(73, 37), el_f=(79, 45), ha_f=(76, 33))
WALK_A = pose(chest=(66, 40), head=(69, 18),
              kn_f=(81, 70), ft_f=(87, 87), kn_b=(53, 76), ft_b=(45, 86),
              el_f=(70, 50), ha_f=(66, 43), el_b=(55, 42), ha_b=(60, 34))
WALK_B = pose(chest=(62, 40), head=(65, 18),
              kn_b=(75, 70), ft_b=(81, 87), kn_f=(51, 76), ft_f=(45, 86),
              el_b=(73, 50), ha_b=(69, 43), el_f=(55, 42), ha_f=(60, 34))
JAB_W = pose(chest=(60, 41), head=(64, 19),
             sh_f=(71, 39), el_f=(65, 48), ha_f=(67, 40),
             sh_b=(55, 38), el_b=(51, 47), ha_b=(58, 35),
             kn_f=(77, 72), ft_f=(83, 88), kn_b=(53, 74), ft_b=(49, 88))
JAB_S = pose(chest=(69, 39), head=(73, 18),
             sh_f=(73, 37), el_f=(89, 38), ha_f=(106, 39),
             sh_b=(58, 39), el_b=(55, 49), ha_b=(59, 35),
             kn_f=(81, 70), ft_f=(89, 87), kn_b=(51, 75), ft_b=(45, 88))
HOOK_W = pose(chest=(59, 41), head=(62, 18),
              sh_f=(70, 38), el_f=(63, 47), ha_f=(58, 37),
              sh_b=(55, 38), el_b=(51, 46), ha_b=(55, 33))
HOOK_S = pose(chest=(71, 39), head=(75, 19),
              sh_f=(75, 37), el_f=(94, 31), ha_f=(102, 23),
              sh_b=(59, 40), el_b=(57, 51), ha_b=(61, 39),
              kn_f=(81, 70), ft_f=(87, 87), kn_b=(51, 75), ft_b=(45, 88))
UP_C = pose(pelvis=(64, 62), chest=(64, 47), neck=(64, 36), head=(67, 28),
            sh_f=(72, 45), el_f=(73, 55), ha_f=(68, 58),
            sh_b=(56, 45), el_b=(53, 55), ha_b=(57, 56),
            hip_b=(58, 62), hip_f=(70, 62),
            kn_f=(75, 76), ft_f=(79, 88), kn_b=(53, 78), ft_b=(49, 88))
UP_R = pose(pelvis=(65, 55), chest=(66, 34), neck=(66, 24), head=(69, 12),
            sh_f=(73, 33), el_f=(85, 19), ha_f=(93, 5),
            sh_b=(57, 35), el_b=(53, 46), ha_b=(55, 37),
            kn_f=(78, 70), ft_f=(84, 86), kn_b=(53, 74), ft_b=(47, 88))

JAB_MID = lerp_pose(JAB_W, JAB_S, 0.5)
JAB_REC = lerp_pose(JAB_S, IDLE_A, 0.6)
HOOK_MID = lerp_pose(HOOK_W, HOOK_S, 0.5)
HOOK_REC = lerp_pose(HOOK_S, IDLE_A, 0.6)
UP_MID = lerp_pose(UP_C, UP_R, 0.4)
UP_REC = lerp_pose(UP_R, IDLE_A, 0.55)


def frames():
    idle = [lerp_pose(IDLE_A, IDLE_B, v) for v in (0, .25, .5, .75, 1, .5)]
    w1, w2 = lerp_pose(WALK_A, WALK_B, .33), lerp_pose(WALK_A, WALK_B, .66)
    w3, w4 = lerp_pose(WALK_B, WALK_A, .33), lerp_pose(WALK_B, WALK_A, .66)
    walk = [WALK_A, w1, w2, WALK_B, WALK_B, w4, w3, WALK_A]
    jab = [(IDLE_A, None), (JAB_W, None), (JAB_MID, None),
           (JAB_S, (JAB_MID, .28, -7)), (JAB_REC, None)]
    hook = [(IDLE_A, None), (HOOK_W, None), (HOOK_MID, None),
            (HOOK_S, (HOOK_MID, .28, -7)), (HOOK_REC, None)]
    upper = [(IDLE_A, None), (UP_C, None), (UP_MID, None),
             (UP_R, (UP_MID, .26, -6)), (UP_REC, None)]
    return ([(q, None) for q in idle] + [(q, None) for q in walk]
            + jab + hook + upper)


# ---------------------------------------------------------------------------
# figure parts
# ---------------------------------------------------------------------------
def draw_arm(p, s, pal, back):
    if back:
        a, e, h = s['sh_b'], s['el_b'], s['ha_b']
        sk, hi, sh = pal['skin_sh'], pal['skin_sh'], pal['skin_sh']
        gl, gh, gs = pal['gloves_sh'], pal['gloves_sh'], pal['gloves_sh']
    else:
        a, e, h = s['sh_f'], s['el_f'], s['ha_f']
        sk, hi, sh = pal['skin'], pal['skin_hi'], pal['skin_sh']
        gl, gh, gs = pal['gloves'], pal['gloves_hi'], pal['gloves_sh']
    limb(p, [a, e, h], [6.0, 5.0, 4.0], sk, hi, sh)
    # glove: knuckle mass + thumb + seam
    p.oval((h[0]-5, h[1]-5, h[0]+4, h[1]+5), gl, OUTLINE)
    p.oval((h[0]+3, h[1]+1, h[0]+8, h[1]+5), gl, OUTLINE)
    p.line([(h[0]-4, h[1]-2), (h[0]+3, h[1]-2)], gh, 1)
    p.line([(h[0]-3, h[1]+3), (h[0]+3, h[1]+3)], gs, 1)


def draw_leg(p, s, pal, back):
    if back:
        hp, kn, ft = s['hip_b'], s['kn_b'], s['ft_b']
        base, hi, sh = pal['pants_sh'], pal['pants_sh'], pal['pants_sh']
        bt, bh = pal['boots_sh'], pal['boots_sh']
    else:
        hp, kn, ft = s['hip_f'], s['kn_f'], s['ft_f']
        base, hi, sh = pal['pants'], pal['pants_hi'], pal['pants_sh']
        bt, bh = pal['boots'], pal['boots_hi']
    limb(p, [hp, kn, ft], [8.0, 6.0, 4.6], base, hi, sh)
    # knee crease + thigh seam
    p.line([(kn[0]-4, kn[1]-1), (kn[0]+4, kn[1])], sh, 1)
    # boot with toe and sole
    p.poly([
        (ft[0]-5, ft[1]-6), (ft[0]+5, ft[1]-6),
        (ft[0]+6, ft[1]+1), (ft[0]+13, ft[1]+2),
        (ft[0]+13, ft[1]+5), (ft[0]-6, ft[1]+5),
    ], bt, OUTLINE)
    p.line([(ft[0]-5, ft[1]+3), (ft[0]+12, ft[1]+3)], pal['boots_sh'], 1)
    p.line([(ft[0]+3, ft[1]-5), (ft[0]+5, ft[1]+1)], bh, 1)


def draw_torso(p, s, pal):
    sb, sf = s['sh_b'], s['sh_f']
    ch, pe, nk = s['chest'], s['pelvis'], s['neck']
    hp, hf = s['hip_b'], s['hip_f']
    pts = [
        (sb[0]-3, sb[1]-4), (sf[0]+3, sf[1]-4),
        (sf[0]+2, ch[1]+4), (pe[0]+8, pe[1]-2),
        (pe[0]+6, pe[1]+4), (pe[0]-6, pe[1]+4),
        (pe[0]-8, pe[1]-2), (sb[0]-2, ch[1]+4),
    ]
    p.poly(pts, pal['shirt'], OUTLINE)
    # right-side body shadow
    p.poly([(ch[0]+2, ch[1]-2), (sf[0]+3, sf[1]-4), (sf[0]+2, ch[1]+4),
            (pe[0]+8, pe[1]-2), (pe[0]+3, pe[1]+3), (ch[0]+3, ch[1]+5)],
           pal['shirt_sh'])
    # chest highlight
    p.poly([(sb[0]-2, sb[1]-3), (ch[0]-1, ch[1]-2),
            (ch[0]-2, ch[1]+3), (sb[0]-2, ch[1]+3)], pal['shirt_hi'])
    # pectoral line + ab line
    p.line([(ch[0]-6, ch[1]+1), (ch[0]+5, ch[1]+2)], pal['shirt_sh'], 1)
    p.line([(ch[0], ch[1]+3), (ch[0], pe[1]-3)], pal['shirt_sh'], 1)
    # collar showing skin
    p.poly([(nk[0]-4, nk[1]+1), (nk[0]+4, nk[1]+1),
            (ch[0]+2, ch[1]+5), (ch[0]-3, ch[1]+4)],
           pal['skin_sh'], OUTLINE)
    # belt + buckle
    p.poly([(hp[0]-4, pe[1]-1), (hf[0]+4, pe[1]-1),
            (hf[0]+4, pe[1]+4), (hp[0]-4, pe[1]+4)], pal['belt'], OUTLINE)
    p.poly([(ch[0]-3, pe[1]), (ch[0]+3, pe[1]),
            (ch[0]+3, pe[1]+4), (ch[0]-3, pe[1]+4)], pal['buckle'], OUTLINE)


def draw_head(p, s, pal, variant):
    hx, hy = s['head']
    # neck
    limb(p, [s['neck'], (hx, hy+5)], [4.5, 4.0],
         pal['skin_sh'], pal['skin_sh'], pal['skin_sh'])
    # skull + jaw + ear
    p.oval((hx-9, hy-11, hx+9, hy+7), pal['skin'], OUTLINE)
    p.poly([(hx-7, hy+2), (hx+8, hy+2), (hx+5, hy+10), (hx-3, hy+10)],
           pal['skin'], OUTLINE)
    p.oval((hx-10, hy-1, hx-6, hy+4), pal['skin_sh'], OUTLINE)
    # cheek shadow
    p.poly([(hx-7, hy+1), (hx-5, hy+1), (hx-4, hy+8), (hx-6, hy+7)], pal['skin_sh'])
    # hair
    if variant == 'enemy':
        p.poly([(hx-8, hy-5), (hx-3, hy-17), (hx, hy-6), (hx+4, hy-16),
                (hx+8, hy-5), (hx+6, hy-3), (hx-7, hy-3)], pal['hair'], OUTLINE)
        p.line([(hx-2, hy-13), (hx+3, hy-12)], pal['hair_hi'], 1)
    elif variant == 'boss':
        p.poly([(hx-9, hy-4), (hx-6, hy-11), (hx+2, hy-13),
                (hx+10, hy-10), (hx+9, hy-4), (hx+4, hy-6), (hx-6, hy-4)],
               pal['hair'], OUTLINE)
        p.line([(hx-5, hy-9), (hx+6, hy-9)], pal['hair_hi'], 2)
    else:
        p.poly([(hx-9, hy-4), (hx-6, hy-12), (hx-2, hy-6),
                (hx+1, hy-13), (hx+5, hy-6), (hx+9, hy-11), (hx+9, hy-3),
                (hx-8, hy-3)], pal['hair'], OUTLINE)
        p.line([(hx-5, hy-8), (hx-3, hy-5)], pal['hair_hi'], 1)
    # face (facing right)
    p.line([(hx+2, hy-2), (hx+7, hy-3)], OUTLINE, 1)
    p.oval((hx+3, hy-1, hx+8, hy+4), (245, 245, 245, 255), OUTLINE)
    p.oval((hx+5, hy, hx+7, hy+3), pal['eye'])
    p.line([(hx+8, hy+1), (hx+9, hy+4)], pal['skin_sh'], 1)
    p.line([(hx+2, hy+7), (hx+6, hy+6)], pal['skin_sh'], 1)
    if variant == 'boss':
        p.poly([(hx+1, hy-2), (hx+9, hy-3), (hx+9, hy+3), (hx+1, hy+2)], OUTLINE)
        p.line([(hx+5, hy-2), (hx+5, hy+2)], pal['hair_hi'], 1)


def draw_figure(p, s, pal, variant):
    draw_leg(p, s, pal, back=True)
    draw_arm(p, s, pal, back=True)
    draw_torso(p, s, pal)
    draw_head(p, s, pal, variant)
    draw_leg(p, s, pal, back=False)
    draw_arm(p, s, pal, back=False)


def faded_pal(pal, f):
    return {k: (v[0], v[1], v[2], int(v[3] * f)) for k, v in pal.items()}


def render(pose_def, pal, variant, ghost=None):
    p = Painter()
    if ghost is not None:
        gpose, ga, gx = ghost
        gp = Painter()
        draw_figure(gp, gpose, faded_pal(pal, ga), variant)
        p.im.alpha_composite(gp.im, (int(gx * SS), 0))
    draw_figure(p, pose_def, pal, variant)
    return p.finish()


def make_sheet(pal, variant, out_path):
    fr = frames()
    sheet = Image.new('RGBA', (FW * len(fr), FH), (0, 0, 0, 0))
    for i, (s, ghost) in enumerate(fr):
        sheet.paste(render(s, pal, variant, ghost), (i * FW, 0))
    sheet.save(out_path)
    print(f"generated {out_path} {sheet.size} frames={len(fr)}")


def main():
    make_sheet(PLAYER, 'player', 'assets/sprites/original_player_sheet.png')
    make_sheet(ENEMY, 'enemy', 'assets/sprites/original_enemy_sheet.png')
    make_sheet(BOSS, 'boss', 'assets/sprites/original_boss_sheet.png')


if __name__ == '__main__':
    main()
