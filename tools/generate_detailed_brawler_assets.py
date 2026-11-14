#!/usr/bin/env python3
"""
tools/generate_detailed_brawler_assets.py
Generator karakter Arcade Brawler Proporsional Detail (Neo-Geo / CPS2 Style, 64x64 grid).
Sheet layout: 16 frames @ 64x64 = 1024x64
0-3: idle (4 frames)
4-9: walk (6 frames)
10-11: jab (2 frames: windup, snap)
12-13: hook (2 frames: windup, heavy hook)
14-15: upper (2 frames: crouch dip, soaring upper)
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

def draw_detailed_frame(draw, ox, oy, pose="idle1", pal=None):
    if pal is None:
        pal = {
            "skin_hi": hex_to_rgba("#ffd1b3"),
            "skin": hex_to_rgba("#f0a27e"),
            "skin_dark": hex_to_rgba("#c46b49"),
            "hair": hex_to_rgba("#221a24"),
            "hair_hi": hex_to_rgba("#44384a"),
            "shirt": hex_to_rgba("#f0f2f8"),
            "shirt_shadow": hex_to_rgba("#aab0c2"),
            "pants": hex_to_rgba("#2b3a58"),
            "pants_dark": hex_to_rgba("#182236"),
            "shoes": hex_to_rgba("#141418"),
            "shoes_hi": hex_to_rgba("#383844"),
            "outline": hex_to_rgba("#000000"),
            "gloves": hex_to_rgba("#c92a2a"),
            "eye": hex_to_rgba("#268bd2"),
        }

    out = pal["outline"]
    sk_h = pal["skin_hi"]
    sk = pal["skin"]
    sk_d = pal["skin_dark"]
    hr = pal["hair"]
    hr_h = pal["hair_hi"]
    sh = pal["shirt"]
    sh_d = pal["shirt_shadow"]
    pt = pal["pants"]
    pt_d = pal["pants_dark"]
    so = pal["shoes"]
    so_h = pal["shoes_hi"]
    gl = pal.get("gloves", sk)

    # Bobbing & stride heights
    bob_y = 0
    if pose in ["idle2"]:
        bob_y = -1
    elif pose in ["idle4", "upper1"]:
        bob_y = 2
    elif pose in ["walk2", "walk5"]:
        bob_y = -2
    elif pose == "upper2":
        bob_y = -4

    # Center origin: box 64x64, feet touch bottom y=62
    cx = ox + 32
    top_y = oy + 6 + bob_y

    # --- 1. KEPALA & RAMBUT PROPORSIONAL (Human 6-head ratio: kepala ~14px) ---
    hy = top_y
    # Rambut bervolume
    draw.rectangle([cx - 5, hy, cx + 5, hy + 11], fill=hr)
    draw.rectangle([cx - 6, hy + 2, cx + 6, hy + 8], fill=hr)
    draw.line([(cx - 4, hy - 1), (cx + 4, hy - 1)], fill=out, width=1)
    draw.line([(cx - 7, hy + 2), (cx - 7, hy + 8)], fill=out, width=1)
    draw.line([(cx + 7, hy + 2), (cx + 7, hy + 8)], fill=out, width=1)

    # Highlight rambut
    draw.line([(cx - 3, hy + 1), (cx + 2, hy + 1)], fill=hr_h, width=1)

    # Wajah proporsional & rahang
    draw.rectangle([cx - 3, hy + 4, cx + 5, hy + 11], fill=sk)
    draw.rectangle([cx - 2, hy + 10, cx + 4, hy + 12], fill=sk_d) # rahang/dagu
    draw.point((cx + 5, hy + 8), fill=sk_d) # hidung

    # Mata brawler tajam
    draw.line([(cx + 1, hy + 6), (cx + 4, hy + 6)], fill=out, width=1)
    draw.point((cx + 2, hy + 7), fill=pal["eye"])
    draw.point((cx + 4, hy + 7), fill=sk_h)

    # --- 2. LEHER & DADA / BAHU BEROTOT (Torso atletis) ---
    ny = hy + 12
    draw.rectangle([cx - 2, ny, cx + 2, ny + 2], fill=sk_d) # leher

    by = ny + 2
    # Bahu & Deltoid atletis (lebar 18px)
    draw.rectangle([cx - 9, by, cx + 9, by + 14], fill=sh)
    # Shading otot dada / kutang
    draw.rectangle([cx - 7, by + 1, cx + 7, by + 6], fill=sh)
    draw.line([(cx - 9, by), (cx - 9, by + 14)], fill=out, width=1)
    draw.line([(cx + 9, by), (cx + 9, by + 14)], fill=out, width=1)
    draw.rectangle([cx - 9, by + 4, cx - 6, by + 14], fill=sh_d) # shading sisi tubuh
    draw.line([(cx - 4, by), (cx + 4, by)], fill=sk, width=2) # garis leher kutang
    draw.line([(cx - 2, by + 4), (cx + 2, by + 4)], fill=sh_d, width=1) # belahan dada

    # --- 3. LENGAN & SERANGAN ---
    ty = by + 2
    if pose.startswith("idle"):
        # Lengan guard santai
        draw.rectangle([cx + 7, ty + 1, cx + 11, ty + 10], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 8, ty + 9, cx + 12, ty + 14], fill=gl, outline=out, width=1) # kepalan depan
        draw.rectangle([cx - 11, ty + 1, cx - 7, ty + 10], fill=sk_d, outline=out, width=1)
        draw.rectangle([cx - 11, ty + 9, cx - 7, ty + 13], fill=gl, outline=out, width=1)

    elif pose in ["walk1", "walk2", "walk3"]:
        draw.rectangle([cx + 8, ty, cx + 12, ty + 9], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 10, ty + 8, cx + 14, ty + 13], fill=gl, outline=out, width=1)
        draw.rectangle([cx - 13, ty + 2, cx - 9, ty + 10], fill=sk_d, outline=out, width=1)
        draw.rectangle([cx - 14, ty + 9, cx - 10, ty + 13], fill=gl, outline=out, width=1)

    elif pose in ["walk4", "walk5", "walk6"]:
        draw.rectangle([cx + 6, ty + 3, cx + 10, ty + 11], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 7, ty + 10, cx + 11, ty + 14], fill=gl, outline=out, width=1)
        draw.rectangle([cx - 11, ty - 1, cx - 7, ty + 7], fill=sk_d, outline=out, width=1)
        draw.rectangle([cx - 10, ty + 6, cx - 6, ty + 11], fill=gl, outline=out, width=1)

    elif pose == "jab1":
        # Windup tarikan siku ke belakang
        draw.rectangle([cx + 4, ty + 1, cx + 9, ty + 8], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 5, ty + 6, cx + 10, ty + 12], fill=gl, outline=out, width=1)
        draw.rectangle([cx - 10, ty + 2, cx - 6, ty + 9], fill=sk_d, outline=out, width=1)

    elif pose == "jab2":
        # Pukulan lurus bertenaga panjang
        draw.rectangle([cx + 8, ty + 1, cx + 22, ty + 7], fill=sk)
        draw.rectangle([cx + 18, ty, cx + 26, ty + 8], fill=gl, outline=out, width=1) # sarung tinju
        draw.line([(cx + 8, ty + 1), (cx + 18, ty + 1)], fill=out, width=1)
        draw.line([(cx + 8, ty + 7), (cx + 18, ty + 7)], fill=out, width=1)
        draw.line([(cx + 12, ty - 1), (cx + 24, ty - 1)], fill=(255, 255, 255, 220), width=1)
        draw.rectangle([cx - 9, ty + 3, cx - 5, ty + 9], fill=sk_d, outline=out, width=1)

    elif pose == "hook1":
        # Hook windup body rotation
        draw.rectangle([cx + 5, ty - 1, cx + 10, ty + 7], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 6, ty + 5, cx + 11, ty + 11], fill=gl, outline=out, width=1)
        draw.rectangle([cx - 10, ty + 1, cx - 6, ty + 8], fill=sk_d, outline=out, width=1)

    elif pose == "hook2":
        # Heavy hook swing arc
        draw.rectangle([cx + 8, ty - 4, cx + 20, ty + 5], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 16, ty - 5, cx + 24, ty + 6], fill=gl, outline=out, width=1)
        draw.arc([cx + 12, ty - 8, cx + 28, ty + 8], start=260, end=90, fill=(255, 255, 255, 220), width=2)
        draw.rectangle([cx - 9, ty + 3, cx - 5, ty + 9], fill=sk_d, outline=out, width=1)

    elif pose == "upper1":
        # Low power crouch
        draw.rectangle([cx + 6, ty + 5, cx + 12, ty + 12], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 7, ty + 11, cx + 13, ty + 17], fill=gl, outline=out, width=1)
        draw.rectangle([cx - 10, ty + 4, cx - 6, ty + 11], fill=sk_d, outline=out, width=1)

    elif pose == "upper2":
        # Soaring uppercut
        draw.rectangle([cx + 7, ty - 11, cx + 14, ty], fill=sk, outline=out, width=1)
        draw.rectangle([cx + 7, ty - 16, cx + 15, ty - 8], fill=gl, outline=out, width=1)
        draw.line([(cx + 11, ty + 2), (cx + 11, ty + 14)], fill=(255, 255, 255, 200), width=2)
        draw.rectangle([cx - 9, ty + 2, cx - 5, ty + 8], fill=sk_d, outline=out, width=1)

    # --- 4. SABUK / PINGGANG & CELANA DENIM JEANS ---
    py = by + 14
    # Ikat pinggang
    draw.rectangle([cx - 8, py, cx + 8, py + 3], fill=hex_to_rgba("#181414"), outline=out, width=1)
    draw.rectangle([cx - 2, py, cx + 2, py + 3], fill=hex_to_rgba("#e6c86e")) # kepala sabuk kuningan

    ly = py + 3
    # Kaki proporsional panjang (24px)
    if pose in ["idle1", "idle2"]:
        # Kaki kanan & kiri
        draw.rectangle([cx - 8, ly, cx - 1, ly + 14], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 1, ly, cx + 8, ly + 14], fill=pt, outline=out, width=1)
        draw.line([(cx - 7, ly + 2), (cx - 7, ly + 12)], fill=pt_d, width=1) # shading lipatan
        # Boot bertali
        draw.rectangle([cx - 9, ly + 14, cx - 1, ly + 22], fill=so, outline=out, width=1)
        draw.rectangle([cx + 1, ly + 14, cx + 9, ly + 22], fill=so, outline=out, width=1)
        draw.line([(cx - 8, ly + 15), (cx - 2, ly + 15)], fill=so_h, width=1)
        draw.line([(cx + 2, ly + 15), (cx + 8, ly + 15)], fill=so_h, width=1)

    elif pose in ["idle3", "idle4"]:
        draw.rectangle([cx - 8, ly, cx - 2, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 2, ly, cx + 8, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 9, ly + 13, cx - 2, ly + 21], fill=so, outline=out, width=1)
        draw.rectangle([cx + 2, ly + 13, cx + 9, ly + 21], fill=so, outline=out, width=1)

    elif pose in ["walk1", "walk2"]:
        # Kaki depan melangkah maju
        draw.rectangle([cx + 2, ly, cx + 10, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 9, ly, cx - 2, ly + 13], fill=pt_d, outline=out, width=1)
        draw.rectangle([cx + 3, ly + 13, cx + 12, ly + 21], fill=so, outline=out, width=1)
        draw.rectangle([cx - 10, ly + 13, cx - 3, ly + 21], fill=so, outline=out, width=1)

    elif pose == "walk3":
        draw.rectangle([cx + 3, ly, cx + 11, ly + 14], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 10, ly - 1, cx - 3, ly + 12], fill=pt_d, outline=out, width=1)
        draw.rectangle([cx + 4, ly + 14, cx + 13, ly + 22], fill=so, outline=out, width=1)
        draw.rectangle([cx - 11, ly + 11, cx - 4, ly + 19], fill=so, outline=out, width=1)

    elif pose in ["walk4", "walk5"]:
        draw.rectangle([cx - 9, ly, cx - 1, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 1, ly, cx + 8, ly + 13], fill=pt_d, outline=out, width=1)
        draw.rectangle([cx - 10, ly + 13, cx - 1, ly + 21], fill=so, outline=out, width=1)
        draw.rectangle([cx + 1, ly + 13, cx + 9, ly + 21], fill=so, outline=out, width=1)

    elif pose == "walk6":
        draw.rectangle([cx - 10, ly, cx - 2, ly + 14], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 2, ly - 1, cx + 9, ly + 12], fill=pt_d, outline=out, width=1)
        draw.rectangle([cx - 11, ly + 14, cx - 2, ly + 22], fill=so, outline=out, width=1)
        draw.rectangle([cx + 2, ly + 11, cx + 10, ly + 19], fill=so, outline=out, width=1)

    elif pose in ["jab1", "jab2", "hook1", "hook2"]:
        # Kuda-kuda brawler kokoh
        draw.rectangle([cx - 10, ly, cx - 2, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 2, ly, cx + 11, ly + 13], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 12, ly + 13, cx - 3, ly + 21], fill=so, outline=out, width=1)
        draw.rectangle([cx + 3, ly + 13, cx + 13, ly + 21], fill=so, outline=out, width=1)

    elif pose == "upper1":
        # Deep crouch
        draw.rectangle([cx - 11, ly + 1, cx - 2, ly + 12], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 2, ly + 1, cx + 12, ly + 12], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 13, ly + 12, cx - 3, ly + 20], fill=so, outline=out, width=1)
        draw.rectangle([cx + 3, ly + 12, cx + 14, ly + 20], fill=so, outline=out, width=1)

    elif pose == "upper2":
        # Air kick/leg stretch
        draw.rectangle([cx - 7, ly - 2, cx - 1, ly + 11], fill=pt, outline=out, width=1)
        draw.rectangle([cx + 2, ly - 2, cx + 8, ly + 11], fill=pt, outline=out, width=1)
        draw.rectangle([cx - 8, ly + 11, cx - 1, ly + 19], fill=so, outline=out, width=1)
        draw.rectangle([cx + 2, ly + 11, cx + 9, ly + 19], fill=so, outline=out, width=1)


def generate_detailed_spritesheet(pal, out_path):
    # 16 frame @ 64x64 = 1024 x 64
    im = Image.new("RGBA", (1024, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    poses = [
        "idle1", "idle2", "idle3", "idle4",      # 0..3
        "walk1", "walk2", "walk3", "walk4", "walk5", "walk6", # 4..9
        "jab1", "jab2",                         # 10..11
        "hook1", "hook2",                       # 12..13
        "upper1", "upper2",                     # 14..15
    ]
    for i, pose in enumerate(poses):
        draw_detailed_frame(draw, i * 64, 0, pose, pal)

    im.save(out_path)
    print(f"Generated 64x64 detailed spritesheet: {out_path} (1024x64)")


def main():
    # 1. Detailed Player: tanktop putih, jeans denim, sarung tinju merah
    pal_player = {
        "skin_hi": hex_to_rgba("#ffd1b3"),
        "skin": hex_to_rgba("#f0a27e"),
        "skin_dark": hex_to_rgba("#c46b49"),
        "hair": hex_to_rgba("#221a24"),
        "hair_hi": hex_to_rgba("#44384a"),
        "shirt": hex_to_rgba("#f0f2f8"),
        "shirt_shadow": hex_to_rgba("#aab0c2"),
        "pants": hex_to_rgba("#2b3a58"),
        "pants_dark": hex_to_rgba("#182236"),
        "shoes": hex_to_rgba("#141418"),
        "shoes_hi": hex_to_rgba("#383844"),
        "outline": hex_to_rgba("#000000"),
        "gloves": hex_to_rgba("#d92b2b"),
        "eye": hex_to_rgba("#268bd2"),
    }
    generate_detailed_spritesheet(pal_player, "assets/sprites/detailed_player_sheet.png")

    # 2. Detailed Enemy (Punk/Striker): Rompi hijau army, rambut mohawk oranye, sarung tinju berduri/gelap
    pal_enemy = {
        "skin_hi": hex_to_rgba("#f5be9d"),
        "skin": hex_to_rgba("#e08f6c"),
        "skin_dark": hex_to_rgba("#b55e3c"),
        "hair": hex_to_rgba("#d9531e"),
        "hair_hi": hex_to_rgba("#f57e4e"),
        "shirt": hex_to_rgba("#386b45"),
        "shirt_shadow": hex_to_rgba("#21472c"),
        "pants": hex_to_rgba("#2b2c36"),
        "pants_dark": hex_to_rgba("#17171f"),
        "shoes": hex_to_rgba("#121216"),
        "shoes_hi": hex_to_rgba("#2d2d38"),
        "outline": hex_to_rgba("#000000"),
        "gloves": hex_to_rgba("#1f1f26"),
        "eye": hex_to_rgba("#e03131"),
    }
    generate_detailed_spritesheet(pal_enemy, "assets/sprites/detailed_enemy_sheet.png")

    # 3. Detailed Boss: Setelan jas mafia hitam elegan, kemeja putih berdasi, kacamata hitam
    pal_boss = {
        "skin_hi": hex_to_rgba("#fce0d2"),
        "skin": hex_to_rgba("#e69c7e"),
        "skin_dark": hex_to_rgba("#bf6c4f"),
        "hair": hex_to_rgba("#ced3dc"),
        "hair_hi": hex_to_rgba("#eef1f6"),
        "shirt": hex_to_rgba("#14151a"),
        "shirt_shadow": hex_to_rgba("#090a0d"),
        "pants": hex_to_rgba("#14151a"),
        "pants_dark": hex_to_rgba("#090a0d"),
        "shoes": hex_to_rgba("#0b0c10"),
        "shoes_hi": hex_to_rgba("#282b36"),
        "outline": hex_to_rgba("#000000"),
        "gloves": hex_to_rgba("#14151a"),
        "eye": hex_to_rgba("#f59f00"),
    }
    generate_detailed_spritesheet(pal_boss, "assets/sprites/detailed_boss_sheet.png")


if __name__ == "__main__":
    main()
