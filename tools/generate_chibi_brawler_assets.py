#!/usr/bin/env python3
"""
tools/generate_chibi_brawler_assets.py
Modern Arcade Brawler Character & Combat FX Generator
Sheet layout: 16 frames @ 48x48 = 768x48
0-3: idle (4 frames)
4-9: walk (6 frames)
10-11: jab (2 frames: windup, punch)
12-13: hook (2 frames: windup, swing)
14-15: upper (2 frames: crouch, launch)
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

def draw_chibi_frame(draw, ox, oy, pose="idle1", pal=None):
    if pal is None:
        pal = {
            "skin": hex_to_rgba("#f4ab89"),
            "skin_dark": hex_to_rgba("#cf7b5c"),
            "hair": hex_to_rgba("#181822"),
            "hair_hi": hex_to_rgba("#2e2e42"),
            "shirt": hex_to_rgba("#ffffff"),
            "shirt_dark": hex_to_rgba("#c5c8d6"),
            "pants": hex_to_rgba("#252834"),
            "pants_dark": hex_to_rgba("#171822"),
            "shoes": hex_to_rgba("#0f0f14"),
            "eye": hex_to_rgba("#38b6ff"),
            "outline": hex_to_rgba("#000000"),
        }

    out = pal["outline"]
    sk = pal["skin"]
    sk_d = pal["skin_dark"]
    hr = pal["hair"]
    hr_h = pal["hair_hi"]
    sh = pal["shirt"]
    sh_d = pal["shirt_dark"]
    pt = pal["pants"]
    pt_d = pal["pants_dark"]
    so = pal["shoes"]
    eye_c = pal["eye"]

    bob_y = 0
    if pose in ["idle2", "walk2", "walk5"]:
        bob_y = -1
    elif pose in ["idle4", "upper1"]:
        bob_y = 2
    elif pose in ["walk3", "walk6"]:
        bob_y = 1
    elif pose == "upper2":
        bob_y = -3

    bx = ox + 14
    by = oy + 6 + bob_y

    # 1. Rambut & Kepala
    draw.rectangle([bx + 1, by, bx + 19, by + 18], fill=hr)
    draw.rectangle([bx, by + 3, bx + 20, by + 16], fill=hr)
    draw.rectangle([bx + 1, by - 1, bx + 19, by], fill=out)
    draw.rectangle([bx - 1, by + 3, bx, by + 16], fill=out)
    draw.rectangle([bx + 20, by + 3, bx + 21, by + 16], fill=out)

    # 2. Wajah & Ekspresi
    draw.rectangle([bx + 5, by + 7, bx + 18, by + 16], fill=sk)
    draw.rectangle([bx + 4, by + 9, bx + 17, by + 16], fill=sk)
    draw.rectangle([bx + 6, by + 16, bx + 16, by + 17], fill=sk_d)

    draw.rectangle([bx + 12, by + 10, bx + 15, by + 13], fill=(255, 255, 255, 255))
    draw.rectangle([bx + 13, by + 10, bx + 15, by + 13], fill=eye_c)
    draw.rectangle([bx + 14, by + 10, bx + 15, by + 12], fill=out)

    draw.rectangle([bx + 6, by + 10, bx + 8, by + 13], fill=(255, 255, 255, 255))
    draw.rectangle([bx + 7, by + 10, bx + 8, by + 13], fill=eye_c)
    draw.rectangle([bx + 7, by + 10, bx + 8, by + 12], fill=out)

    draw.line([(bx + 11, by + 9), (bx + 16, by + 9)], fill=out, width=1)
    draw.line([(bx + 5, by + 9), (bx + 9, by + 9)], fill=out, width=1)
    draw.point((bx + 17, by + 12), fill=sk_d)
    draw.line([(bx + 13, by + 15), (bx + 15, by + 15)], fill=out, width=1)

    draw.polygon([(bx + 3, by + 4), (bx + 8, by + 9), (bx + 10, by + 5), (bx + 14, by + 8), (bx + 16, by + 4)], fill=hr)
    draw.point((bx + 8, by + 8), fill=hr_h)
    draw.point((bx + 14, by + 7), fill=hr_h)

    # 3. Torso / Kaos
    ty = by + 18
    draw.rectangle([bx + 5, ty, bx + 16, ty + 9], fill=sh)
    draw.rectangle([bx + 4, ty + 3, bx + 5, ty + 9], fill=sh_d)
    draw.line([(bx + 4, ty), (bx + 4, ty + 9)], fill=out, width=1)
    draw.line([(bx + 17, ty), (bx + 17, ty + 9)], fill=out, width=1)
    draw.line([(bx + 7, ty), (bx + 14, ty)], fill=sk, width=2)
    draw.line([(bx + 7, ty + 2), (bx + 14, ty + 2)], fill=sk_d, width=1)

    # 4. Tangan sesuai aksi
    if pose.startswith("idle"):
        arm_sway = 1 if pose in ["idle2", "idle3"] else 0
        draw.rectangle([bx + 16, ty + 1 + arm_sway, bx + 20, ty + 6 + arm_sway], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 2, ty + 2, bx + 6, ty + 7], fill=sk_d, outline=out, width=1)

    elif pose in ["walk1", "walk2", "walk3"]:
        draw.rectangle([bx + 17, ty + 2, bx + 21, ty + 7], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 1, ty + 1, bx + 5, ty + 6], fill=sk_d, outline=out, width=1)

    elif pose in ["walk4", "walk5", "walk6"]:
        draw.rectangle([bx + 15, ty, bx + 19, ty + 5], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 3, ty + 3, bx + 7, ty + 8], fill=sk_d, outline=out, width=1)

    elif pose == "jab1":
        # Windup
        draw.rectangle([bx + 12, ty + 2, bx + 17, ty + 7], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 3, ty + 2, bx + 7, ty + 7], fill=sk_d, outline=out, width=1)

    elif pose == "jab2":
        # Snap Punch dengan motion speed lines
        draw.rectangle([bx + 16, ty + 1, bx + 28, ty + 6], fill=sk)
        draw.rectangle([bx + 22, ty, bx + 28, ty + 7], fill=sk, outline=out, width=1)
        draw.line([(bx + 16, ty + 1), (bx + 22, ty + 1)], fill=out, width=1)
        draw.line([(bx + 16, ty + 6), (bx + 22, ty + 6)], fill=out, width=1)
        draw.line([(bx + 18, ty - 1), (bx + 27, ty - 1)], fill=(255, 255, 255, 220), width=1)
        draw.rectangle([bx + 4, ty + 2, bx + 8, ty + 7], fill=sk_d, outline=out, width=1)

    elif pose == "hook1":
        # Hook windup
        draw.rectangle([bx + 13, ty + 1, bx + 17, ty + 6], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 1, ty + 3, bx + 5, ty + 8], fill=sk_d, outline=out, width=1)

    elif pose == "hook2":
        # Wide hook swing
        draw.rectangle([bx + 16, ty - 3, bx + 26, ty + 4], fill=sk, outline=out, width=1)
        draw.arc([bx + 14, ty - 6, bx + 30, ty + 8], start=270, end=90, fill=(255, 255, 255, 220), width=2)
        draw.rectangle([bx + 2, ty + 3, bx + 6, ty + 8], fill=sk_d, outline=out, width=1)

    elif pose == "upper1":
        # Uppercut crouch prep
        draw.rectangle([bx + 14, ty + 5, bx + 19, ty + 10], fill=sk, outline=out, width=1)
        draw.rectangle([bx + 2, ty + 4, bx + 6, ty + 9], fill=sk_d, outline=out, width=1)

    elif pose == "upper2":
        # Uppercut release air
        draw.rectangle([bx + 15, ty - 8, bx + 22, ty], fill=sk, outline=out, width=1)
        draw.line([(bx + 18, ty + 2), (bx + 18, ty + 12)], fill=(255, 255, 255, 200), width=2)
        draw.rectangle([bx + 2, ty + 1, bx + 6, ty + 6], fill=sk_d, outline=out, width=1)

    # 5. Celana & Kaki
    py = ty + 9
    draw.rectangle([bx + 4, py, bx + 16, py + 5], fill=pt, outline=out, width=1)

    if pose in ["idle1", "idle2"]:
        draw.rectangle([bx + 5, py + 5, bx + 9, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 11, py + 5, bx + 15, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 4, py + 10, bx + 10, py + 13], fill=so, outline=out, width=1)
        draw.rectangle([bx + 10, py + 10, bx + 16, py + 13], fill=so, outline=out, width=1)

    elif pose in ["idle3", "idle4"]:
        draw.rectangle([bx + 4, py + 4, bx + 9, py + 9], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 11, py + 4, bx + 16, py + 9], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 3, py + 9, bx + 9, py + 12], fill=so, outline=out, width=1)
        draw.rectangle([bx + 11, py + 9, bx + 17, py + 12], fill=so, outline=out, width=1)

    elif pose in ["walk1", "walk2"]:
        draw.rectangle([bx + 12, py + 4, bx + 18, py + 9], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 2, py + 4, bx + 7, py + 9], fill=pt_d, outline=out, width=1)
        draw.rectangle([bx + 13, py + 9, bx + 20, py + 12], fill=so, outline=out, width=1)
        draw.rectangle([bx + 1, py + 9, bx + 7, py + 12], fill=so, outline=out, width=1)

    elif pose == "walk3":
        draw.rectangle([bx + 13, py + 5, bx + 19, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 1, py + 3, bx + 6, py + 8], fill=pt_d, outline=out, width=1)
        draw.rectangle([bx + 14, py + 10, bx + 21, py + 13], fill=so, outline=out, width=1)
        draw.rectangle([bx, py + 8, bx + 6, py + 11], fill=so, outline=out, width=1)

    elif pose in ["walk4", "walk5"]:
        draw.rectangle([bx + 6, py + 4, bx + 11, py + 9], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 10, py + 4, bx + 15, py + 9], fill=pt_d, outline=out, width=1)
        draw.rectangle([bx + 5, py + 9, bx + 11, py + 12], fill=so, outline=out, width=1)
        draw.rectangle([bx + 10, py + 9, bx + 16, py + 12], fill=so, outline=out, width=1)

    elif pose == "walk6":
        draw.rectangle([bx + 2, py + 5, bx + 8, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 12, py + 3, bx + 17, py + 8], fill=pt_d, outline=out, width=1)
        draw.rectangle([bx + 1, py + 10, bx + 8, py + 13], fill=so, outline=out, width=1)
        draw.rectangle([bx + 12, py + 8, bx + 18, py + 11], fill=so, outline=out, width=1)

    elif pose in ["jab1", "jab2", "hook1", "hook2"]:
        draw.rectangle([bx + 3, py + 4, bx + 8, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 11, py + 4, bx + 17, py + 10], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 1, py + 10, bx + 8, py + 13], fill=so, outline=out, width=1)
        draw.rectangle([bx + 12, py + 10, bx + 19, py + 13], fill=so, outline=out, width=1)

    elif pose == "upper1":
        draw.rectangle([bx + 2, py + 5, bx + 8, py + 11], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 12, py + 5, bx + 18, py + 11], fill=pt, outline=out, width=1)
        draw.rectangle([bx, py + 11, bx + 8, py + 14], fill=so, outline=out, width=1)
        draw.rectangle([bx + 12, py + 11, bx + 20, py + 14], fill=so, outline=out, width=1)

    elif pose == "upper2":
        draw.rectangle([bx + 4, py + 2, bx + 9, py + 8], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 11, py + 2, bx + 16, py + 8], fill=pt, outline=out, width=1)
        draw.rectangle([bx + 3, py + 8, bx + 9, py + 11], fill=so, outline=out, width=1)
        draw.rectangle([bx + 11, py + 8, bx + 17, py + 11], fill=so, outline=out, width=1)


def generate_modern_spritesheet(pal, out_path):
    # 16 frame @ 48x48 = 768 x 48
    im = Image.new("RGBA", (768, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    poses = [
        "idle1", "idle2", "idle3", "idle4",      # 0..3
        "walk1", "walk2", "walk3", "walk4", "walk5", "walk6", # 4..9
        "jab1", "jab2",                         # 10..11
        "hook1", "hook2",                       # 12..13
        "upper1", "upper2",                     # 14..15
    ]
    for i, pose in enumerate(poses):
        draw_chibi_frame(draw, i * 48, 0, pose, pal)

    im.save(out_path)
    print(f"Generated 16-frame modern spritesheet: {out_path} (768x48)")


def generate_slash_arc_fx(out_path):
    # 96x48: frame 0 = horizontal slash arc, frame 1 = vertical uppercut arc
    im = Image.new("RGBA", (96, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Frame 0: Horizontal crescent slash
    draw.arc([10, 8, 44, 40], start=280, end=80, fill=(255, 255, 255, 255), width=3)
    draw.arc([8, 6, 46, 42], start=290, end=70, fill=(80, 200, 255, 200), width=2)
    draw.arc([6, 4, 48, 44], start=300, end=60, fill=(0, 140, 255, 120), width=1)

    # Frame 1: Vertical rising uppercut crescent
    ox = 48
    draw.arc([ox + 8, 4, ox + 40, 42], start=170, end=330, fill=(255, 255, 255, 255), width=3)
    draw.arc([ox + 6, 2, ox + 42, 44], start=180, end=320, fill=(255, 200, 80, 200), width=2)
    draw.arc([ox + 4, 0, ox + 44, 46], start=190, end=310, fill=(255, 100, 30, 120), width=1)

    im.save(out_path)
    print(f"Generated slash arc FX: {out_path} (96x48)")


def generate_dust_puff_fx(out_path):
    # 96x32: 3 frames @ 32x32 of dust puffs
    im = Image.new("RGBA", (96, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Frame 0: tight pop
    draw.ellipse([8, 14, 20, 26], fill=(220, 225, 235, 210))
    draw.ellipse([16, 16, 24, 24], fill=(180, 190, 205, 180))

    # Frame 1: expanding cloud
    ox = 32
    draw.ellipse([ox + 4, 10, ox + 18, 24], fill=(210, 215, 225, 160))
    draw.ellipse([ox + 14, 8, ox + 28, 22], fill=(210, 215, 225, 160))
    draw.ellipse([ox + 8, 14, ox + 22, 28], fill=(170, 180, 195, 140))

    # Frame 2: dissipating specks
    ox = 64
    draw.ellipse([ox + 2, 8, ox + 12, 18], fill=(200, 205, 215, 90))
    draw.ellipse([ox + 18, 6, ox + 26, 14], fill=(200, 205, 215, 80))
    draw.ellipse([ox + 12, 16, ox + 22, 26], fill=(160, 170, 185, 70))

    im.save(out_path)
    print(f"Generated dust puff FX: {out_path} (96x32)")


def main():
    pal_player = {
        "skin": hex_to_rgba("#f4ab89"),
        "skin_dark": hex_to_rgba("#cf7b5c"),
        "hair": hex_to_rgba("#181822"),
        "hair_hi": hex_to_rgba("#2e2e42"),
        "shirt": hex_to_rgba("#ffffff"),
        "shirt_dark": hex_to_rgba("#c5c8d6"),
        "pants": hex_to_rgba("#252834"),
        "pants_dark": hex_to_rgba("#171822"),
        "shoes": hex_to_rgba("#0f0f14"),
        "eye": hex_to_rgba("#38b6ff"),
        "outline": hex_to_rgba("#000000"),
    }
    generate_modern_spritesheet(pal_player, "assets/sprites/chibi_player_sheet.png")

    pal_enemy = {
        "skin": hex_to_rgba("#e8a582"),
        "skin_dark": hex_to_rgba("#c47352"),
        "hair": hex_to_rgba("#d9572b"),
        "hair_hi": hex_to_rgba("#f0784d"),
        "shirt": hex_to_rgba("#387346"),
        "shirt_dark": hex_to_rgba("#255230"),
        "pants": hex_to_rgba("#33333e"),
        "pants_dark": hex_to_rgba("#1c1c24"),
        "shoes": hex_to_rgba("#111116"),
        "eye": hex_to_rgba("#ff3838"),
        "outline": hex_to_rgba("#000000"),
    }
    generate_modern_spritesheet(pal_enemy, "assets/sprites/chibi_enemy_sheet.png")

    pal_boss = {
        "skin": hex_to_rgba("#f2b291"),
        "skin_dark": hex_to_rgba("#c98161"),
        "hair": hex_to_rgba("#d0d4dc"),
        "hair_hi": hex_to_rgba("#f0f2f6"),
        "shirt": hex_to_rgba("#1b1c24"),
        "shirt_dark": hex_to_rgba("#101116"),
        "pants": hex_to_rgba("#1b1c24"),
        "pants_dark": hex_to_rgba("#101116"),
        "shoes": hex_to_rgba("#09090c"),
        "eye": hex_to_rgba("#ffb703"),
        "outline": hex_to_rgba("#000000"),
    }
    generate_modern_spritesheet(pal_boss, "assets/sprites/chibi_boss_sheet.png")

    generate_slash_arc_fx("assets/sprites/slash_arc_fx.png")
    generate_dust_puff_fx("assets/sprites/dust_puff_fx.png")


if __name__ == "__main__":
    main()
