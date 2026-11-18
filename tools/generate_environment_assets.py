#!/usr/bin/env python3
"""
tools/generate_environment_assets.py
Generator aset pixel-art untuk arena Beat 'Em Fold (1280x720).
Menghasilkan:
1. assets/backgrounds/alley_skyline.png (1280x360)
2. assets/backgrounds/alley_wall_midground.png (1280x320)
3. assets/backgrounds/alley_ground_lane.png (1280x320)
4. assets/backgrounds/alley_neon_props.png (512x256 atlas)
"""

import math
import random
from PIL import Image, ImageDraw

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    rgb = hex_to_rgb(h)
    return (rgb[0], rgb[1], rgb[2], a)

def generate_skyline():
    w, h = 1280, 360
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Gradient sky
    c_top = hex_to_rgb("#090814")
    c_mid = hex_to_rgb("#18122b")
    c_bot = hex_to_rgb("#2d1945")

    for y in range(h):
        t = y / float(h)
        if t < 0.6:
            sub_t = t / 0.6
            r = int(c_top[0] + (c_mid[0] - c_top[0]) * sub_t)
            g = int(c_top[1] + (c_mid[1] - c_top[1]) * sub_t)
            b = int(c_top[2] + (c_mid[2] - c_top[2]) * sub_t)
        else:
            sub_t = (t - 0.6) / 0.4
            r = int(c_mid[0] + (c_bot[0] - c_mid[0]) * sub_t)
            g = int(c_mid[1] + (c_bot[1] - c_mid[1]) * sub_t)
            b = int(c_mid[2] + (c_bot[2] - c_mid[2]) * sub_t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # Bulan redup berhawa cyberpunk
    moon_x, moon_y, moon_r = 980, 80, 40
    for r in range(moon_r + 15, moon_r, -1):
        alpha = int(25 * (1.0 - (r - moon_r) / 15.0))
        draw.ellipse([moon_x - r, moon_y - r, moon_x + r, moon_y + r], fill=(255, 240, 200, alpha))
    draw.ellipse([moon_x - moon_r, moon_y - moon_r, moon_x + moon_r, moon_y + moon_r], fill=(255, 245, 210, 240))
    # Crater detail
    draw.ellipse([moon_x - 15, moon_y - 10, moon_x - 2, moon_y + 5], fill=(235, 220, 185, 240))
    draw.ellipse([moon_x + 8, moon_y + 12, moon_x + 22, moon_y + 24], fill=(235, 220, 185, 240))

    # Siluet gedung jauh (layer 1 - deep)
    rng = random.Random(42)
    cur_x = 0
    while cur_x < w:
        bw = rng.randint(40, 90)
        bh = rng.randint(120, 240)
        col = hex_to_rgba("#131024", 255)
        draw.rectangle([cur_x, h - bh, cur_x + bw, h], fill=col)
        # Antena
        if rng.random() > 0.4:
            ax = cur_x + bw // 2
            draw.line([(ax, h - bh - 25), (ax, h - bh)], fill=(40, 35, 65, 255), width=2)
            draw.point((ax, h - bh - 26), fill=(255, 50, 70, 255))
        # Lampu jendela kecil
        for wy in range(h - bh + 15, h - 20, 12):
            for wx in range(cur_x + 6, cur_x + bw - 6, 10):
                if rng.random() > 0.75:
                    wcol = hex_to_rgba("#ffb703" if rng.random() > 0.3 else "#00f0ff", rng.randint(100, 200))
                    draw.rectangle([wx, wy, wx + 4, wy + 6], fill=wcol)
        cur_x += bw - rng.randint(4, 12)

    # Siluet gedung dekat (layer 2)
    cur_x = 0
    rng = random.Random(108)
    while cur_x < w:
        bw = rng.randint(60, 130)
        bh = rng.randint(80, 180)
        col = hex_to_rgba("#1b172e", 255)
        draw.rectangle([cur_x, h - bh, cur_x + bw, h], fill=col)
        # Roof rim
        draw.line([(cur_x, h - bh), (cur_x + bw, h - bh)], fill=(55, 45, 85, 255), width=2)
        # Water tower / HVAC units
        if rng.random() > 0.6:
            hx = cur_x + 10
            draw.rectangle([hx, h - bh - 16, hx + 22, h - bh], fill=(30, 25, 50, 255))
            draw.line([(hx + 4, h - bh), (hx + 4, h - bh - 16)], fill=(20, 15, 35, 255))
        for wy in range(h - bh + 20, h - 10, 14):
            for wx in range(cur_x + 8, cur_x + bw - 8, 12):
                if rng.random() > 0.65:
                    wcol = hex_to_rgba("#ffe066" if rng.random() > 0.4 else "#ff007f", rng.randint(120, 230))
                    draw.rectangle([wx, wy, wx + 5, wy + 8], fill=wcol)
        cur_x += bw - rng.randint(6, 16)

    return im

def generate_wall_midground():
    # 1280 x 320 (menempati rentang y = 140 s/d 460 pada scene)
    w, h = 1280, 320
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Tembok bata tua
    c_brick1 = hex_to_rgba("#2b2538", 255)
    c_brick2 = hex_to_rgba("#231e30", 255)
    c_mortar = hex_to_rgba("#1a1624", 255)

    draw.rectangle([0, 0, w, h], fill=c_mortar)

    brick_h = 10
    brick_w = 24
    rng = random.Random(77)

    for row, y in enumerate(range(0, h, brick_h)):
        offset = (row % 2) * (brick_w // 2)
        for x in range(-brick_w, w + brick_w, brick_w):
            bx = x + offset
            b_col = c_brick1 if (rng.random() > 0.35) else c_brick2
            draw.rectangle([bx + 1, y + 1, bx + brick_w - 2, y + brick_h - 2], fill=b_col)
            # Detail texture kusam
            if rng.random() > 0.8:
                draw.point((bx + rng.randint(2, brick_w - 4), y + rng.randint(2, brick_h - 4)), fill=(45, 38, 60, 255))

    # Pipa besi vertikal & horizontal
    pipes_x = [120, 380, 720, 1080]
    for px in pipes_x:
        draw.rectangle([px, 0, px + 12, h], fill=(35, 45, 55, 255))
        draw.line([(px, 0), (px, h)], fill=(60, 75, 90, 255), width=2)
        draw.line([(px + 10, 0), (px + 10, h)], fill=(20, 25, 30, 255), width=2)
        # Ring konektor pipa
        for ry in range(40, h, 60):
            draw.rectangle([px - 2, ry, px + 14, ry + 6], fill=(70, 85, 100, 255))

    # Fire escape (tangga darurat metal)
    fe_x, fe_w = 540, 160
    for floor_y in [60, 160, 260]:
        # Platform
        draw.rectangle([fe_x, floor_y, fe_x + fe_w, floor_y + 8], fill=(45, 48, 60, 255))
        draw.line([(fe_x, floor_y), (fe_x + fe_w, floor_y)], fill=(80, 85, 105, 255), width=2)
        # Railing
        draw.line([(fe_x, floor_y - 28), (fe_x + fe_w, floor_y - 28)], fill=(70, 75, 95, 255), width=2)
        for rx in range(fe_x + 10, fe_x + fe_w, 18):
            draw.line([(rx, floor_y - 28), (rx, floor_y)], fill=(50, 55, 70, 255), width=2)
        # Diagonal ladder ke bawah
        if floor_y < 260:
            draw.line([(fe_x + 20, floor_y + 8), (fe_x + 70, floor_y + 100)], fill=(65, 70, 85, 255), width=3)
            draw.line([(fe_x + 35, floor_y + 8), (fe_x + 85, floor_y + 100)], fill=(65, 70, 85, 255), width=3)
            for step_i in range(8):
                st_t = step_i / 8.0
                sx1 = int((fe_x + 20) + 50 * st_t)
                sy1 = int((floor_y + 8) + 92 * st_t)
                draw.line([(sx1, sy1), (sx1 + 15, sy1)], fill=(55, 60, 75, 255), width=2)

    # Graffiti / poster robek di tembok
    draw.rectangle([220, 180, 270, 240], fill=(210, 190, 140, 230))
    draw.polygon([(270, 180), (270, 210), (250, 180)], fill=(30, 25, 40, 255)) # robekan
    draw.line([(228, 195), (262, 195)], fill=(180, 40, 50, 255), width=3)
    draw.line([(228, 210), (255, 210)], fill=(40, 40, 50, 255), width=2)
    draw.line([(228, 222), (248, 222)], fill=(40, 40, 50, 255), width=2)

    return im

def generate_ground_lane():
    # 1280 x 320 (menempati y = 400 s/d 720 pada scene, mencakup LANE_TOP 430 dan LANE_BOTTOM 600)
    w, h = 1280, 320
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # 1. Sidewalk / Trotoar pembatas atas (y: 0 s/d 34 -> posisi global ~400..434)
    c_curb_top = hex_to_rgba("#3d4254", 255)
    c_curb_face = hex_to_rgba("#222533", 255)
    c_curb_edge = hex_to_rgba("#5a627a", 255)

    draw.rectangle([0, 0, w, 24], fill=c_curb_top)
    draw.line([(0, 0), (w, 0)], fill=c_curb_edge, width=2)
    draw.line([(0, 24), (w, 24)], fill=(15, 18, 25, 255), width=2)

    # Sambungan blok trotoar
    for tx in range(0, w, 80):
        draw.line([(tx, 0), (tx, 24)], fill=(25, 28, 38, 255), width=2)

    # Curb vertical drop
    draw.rectangle([0, 24, w, 34], fill=c_curb_face)
    draw.line([(0, 34), (w, 34)], fill=(10, 12, 18, 255), width=2)

    # 2. Aspal basah utama (y: 35 s/d h)
    c_asphalt = hex_to_rgba("#181924", 255)
    draw.rectangle([0, 35, w, h], fill=c_asphalt)

    # Tekstur kerikil/bintik aspal
    rng = random.Random(999)
    for _ in range(12000):
        gx = rng.randint(0, w - 1)
        gy = rng.randint(35, h - 1)
        val = rng.randint(28, 44)
        draw.point((gx, gy), fill=(val, val + 2, val + 8, 255))

    # Genangan air basah (puddles) dengan refleksi neon halus
    puddles = [
        (180, 90, 220, 45, "#00f0ff"),
        (650, 140, 260, 50, "#ff007f"),
        (1020, 80, 190, 40, "#ffb703"),
        (420, 200, 280, 55, "#00f0ff")
    ]

    for px, py, pw, ph, glow_hex in puddles:
        # Puddle base gelap & basah
        draw.ellipse([px, py, px + pw, py + ph], fill=(10, 12, 18, 255))
        draw.ellipse([px + 2, py + 2, px + pw - 2, py + ph - 2], fill=(14, 16, 26, 255))
        # Refleksi neon bergelombang di genangan
        glow_c = hex_to_rgb(glow_hex)
        for offset_x in range(20, pw - 20, 8):
            ref_len = rng.randint(6, 16)
            ref_y = py + ph // 2 + rng.randint(-6, 6)
            alpha = rng.randint(40, 110)
            draw.line([(px + offset_x, ref_y), (px + offset_x + ref_len, ref_y)], fill=(glow_c[0], glow_c[1], glow_c[2], alpha), width=2)

    # Garis pembatas visual halus penanda LANE_BOTTOM (y: ~200 -> global 600)
    draw.line([(0, 200), (w, 200)], fill=(38, 42, 60, 140), width=2)
    # Garis marka jalan kusam putus-putus
    for mx in range(30, w, 110):
        draw.rectangle([mx, 220, mx + 60, 226], fill=(130, 125, 100, 100))

    # Selokan / manhole cover
    mh_x, mh_y = 860, 110
    draw.ellipse([mh_x, mh_y, mh_x + 50, mh_y + 24], fill=(30, 32, 40, 255))
    draw.ellipse([mh_x + 3, mh_y + 2, mh_x + 47, mh_y + 22], fill=(45, 48, 58, 255))
    for i in range(5):
        lx = mh_x + 10 + i * 7
        draw.line([(lx, mh_y + 6), (lx, mh_y + 18)], fill=(20, 22, 28, 255), width=2)

    return im

def generate_neon_props():
    # Atlas 512x256 untuk props dekorasi neon & objek panggung
    w, h = 512, 256
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Prop 1: Neon Sign "K.O. BAR" (Rect: 0, 0, 192, 96)
    draw.rectangle([6, 6, 186, 90], fill=(16, 14, 25, 255), outline=(55, 48, 75, 255), width=3)
    # Glow luar neon border
    draw.rectangle([10, 10, 182, 86], outline=(255, 0, 127, 80), width=2)
    draw.rectangle([12, 12, 180, 84], outline=(255, 0, 127, 255), width=2)
    # Text K.O.
    # K
    draw.rectangle([30, 24, 38, 72], fill=(0, 240, 255, 255))
    draw.line([(38, 48), (62, 24)], fill=(0, 240, 255, 255), width=6)
    draw.line([(44, 46), (64, 72)], fill=(0, 240, 255, 255), width=6)
    # Dot
    draw.rectangle([70, 64, 76, 72], fill=(255, 0, 127, 255))
    # O
    draw.rectangle([84, 24, 116, 72], outline=(0, 240, 255, 255), width=6)
    # Sub-text BAR
    draw.rectangle([130, 32, 168, 64], fill=(255, 183, 3, 230))
    draw.text((135, 38), "BAR", fill=(20, 10, 0, 255))

    # Prop 2: 4 Card Suits Neon (Rect: 200, 0, 200, 50)
    # Hearts (merah)
    hx, hy = 210, 12
    draw.polygon([(hx+10, hy+26), (hx, hy+12), (hx+4, hy+4), (hx+10, hy+8), (hx+16, hy+4), (hx+20, hy+12)], fill=(255, 40, 60, 255))
    # Spades (cyan-blue)
    sx, sy = 250, 12
    draw.polygon([(sx+10, sy+4), (sx, sy+18), (sx+6, sy+24), (sx+9, sy+22), (sx+8, sy+28), (sx+12, sy+28), (sx+11, sy+22), (sx+14, sy+24), (sx+20, sy+18)], fill=(0, 220, 255, 255))
    # Diamonds (kuning-emas)
    dx, dy = 290, 12
    draw.polygon([(dx+10, dy+4), (dx, dy+16), (dx+10, dy+28), (dx+20, dy+16)], fill=(255, 200, 20, 255))
    # Clubs (hijau-neon)
    cx, cy = 330, 12
    draw.ellipse([cx+6, cy+4, cx+14, cy+12], fill=(50, 255, 120, 255))
    draw.ellipse([cx+1, cy+11, cx+9, cy+19], fill=(50, 255, 120, 255))
    draw.ellipse([cx+11, cy+11, cx+19, cy+19], fill=(50, 255, 120, 255))
    draw.polygon([(cx+9, cy+14), (cx+7, cy+25), (cx+13, cy+25), (cx+11, cy+14)], fill=(50, 255, 120, 255))

    # Prop 3: Dumpster metal gang (Rect: 0, 110, 140, 130)
    d_x, d_y, d_w, d_h = 10, 115, 125, 115
    # Shadow bawah dumpster
    draw.ellipse([d_x - 5, d_y + d_h - 15, d_x + d_w + 5, d_y + d_h + 8], fill=(0, 0, 0, 140))
    # Body dumpster (hijau tua kusam industri)
    draw.rectangle([d_x, d_y + 25, d_x + d_w, d_y + d_h], fill=(38, 55, 45, 255), outline=(22, 33, 27, 255), width=2)
    # Tutup dumpster miring
    draw.polygon([(d_x - 4, d_y + 25), (d_x + d_w // 2, d_y + 8), (d_x + d_w + 4, d_y + 25)], fill=(28, 42, 34, 255))
    draw.line([(d_x - 4, d_y + 25), (d_x + d_w + 4, d_y + 25)], fill=(55, 75, 62, 255), width=3)
    # Garis rusuk penguat metal
    for rx in range(d_x + 18, d_x + d_w - 10, 26):
        draw.line([(rx, d_y + 30), (rx, d_y + d_h - 8)], fill=(22, 33, 27, 255), width=3)
        draw.line([(rx + 2, d_y + 30), (rx + 2, d_y + d_h - 8)], fill=(52, 72, 60, 255), width=2)
    # Roda dumpster
    draw.rectangle([d_x + 12, d_y + d_h, d_x + 24, d_y + d_h + 10], fill=(20, 20, 25, 255))
    draw.rectangle([d_x + d_w - 24, d_y + d_h, d_x + d_w - 12, d_y + d_h + 10], fill=(20, 20, 25, 255))

    # Prop 4: Street Lamp Post & Light Cone (Rect: 160, 100, 120, 150)
    lx, ly = 190, 105
    # Tiang besi
    draw.rectangle([lx, ly, lx + 8, ly + 140], fill=(45, 50, 60, 255))
    draw.line([(lx, ly), (lx, ly + 140)], fill=(75, 82, 98, 255), width=2)
    # Kepala lampu
    draw.polygon([(lx - 16, ly + 12), (lx + 24, ly + 12), (lx + 14, ly), (lx - 6, ly)], fill=(32, 35, 45, 255))
    # Bohlam menyala kuning hangat
    draw.ellipse([lx - 4, ly + 8, lx + 12, ly + 20], fill=(255, 245, 170, 255))
    # Cone cahaya halus ke bawah
    draw.polygon([(lx + 4, ly + 16), (lx - 35, ly + 145), (lx + 43, ly + 145)], fill=(255, 230, 140, 28))

    return im

def main():
    sky = generate_skyline()
    sky.save("assets/backgrounds/alley_skyline.png")
    print("Generated: assets/backgrounds/alley_skyline.png (1280x360)")

    wall = generate_wall_midground()
    wall.save("assets/backgrounds/alley_wall_midground.png")
    print("Generated: assets/backgrounds/alley_wall_midground.png (1280x320)")

    ground = generate_ground_lane()
    ground.save("assets/backgrounds/alley_ground_lane.png")
    print("Generated: assets/backgrounds/alley_ground_lane.png (1280x320)")

    props = generate_neon_props()
    props.save("assets/backgrounds/alley_neon_props.png")
    print("Generated: assets/backgrounds/alley_neon_props.png (512x256)")

if __name__ == "__main__":
    main()
