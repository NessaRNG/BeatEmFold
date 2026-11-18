#!/usr/bin/env python3
"""
Pixel Art Tool & Generator for Godot 4
Provides utilities to:
- Generate pixel art from ASCII/Color matrices or palette definitions
- Combine frame sequences into spritesheets
- Slice spritesheets into frames
- Generate Godot-ready metadata (JSON)
"""

import sys
import os
import json
import argparse
from pathlib import Path
from PIL import Image

# Popular Retro Palettes (HEX)
PALETTES = {
    "db16": [
        "#140c1c", "#442434", "#30346d", "#4e4a4e", "#854c30", "#346524",
        "#d04648", "#757161", "#597dce", "#d27d2c", "#8595a1", "#6daa2c",
        "#d2aa99", "#6dc2ca", "#dad45e", "#deeed6"
    ],
    "gameboy": [
        "#0f380f", "#306230", "#8bac0f", "#9bbc0f"
    ],
    "pico8": [
        "#000000", "#1D2B53", "#7E2553", "#008751", "#AB5236", "#5F574F",
        "#C2C3C7", "#FFF1E8", "#FF004D", "#FFA300", "#FFEC27", "#00E436",
        "#29ADFF", "#83769C", "#FF77A8", "#FFCCAA"
    ]
}

def hex_to_rgba(hex_code, alpha=255):
    hex_code = hex_code.lstrip('#')
    if len(hex_code) == 6:
        r, g, b = tuple(int(hex_code[i:i+2], 16) for i in (0, 2, 4))
        return (r, g, b, alpha)
    elif len(hex_code) == 8:
        return tuple(int(hex_code[i:i+2], 16) for i in (0, 2, 4, 6))
    return (0, 0, 0, 0)

def create_sprite_from_matrix(matrix, color_map, output_path, scale=1):
    """
    matrix: list of strings or list of lists of keys
    color_map: dict mapping key to hex color or None for transparent
    """
    height = len(matrix)
    width = len(matrix[0]) if height > 0 else 0
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    for y, row in enumerate(matrix):
        for x, key in enumerate(row):
            if key in color_map and color_map[key] is not None:
                color = color_map[key]
                if isinstance(color, str):
                    rgba = hex_to_rgba(color)
                elif isinstance(color, (list, tuple)):
                    rgba = tuple(color)
                else:
                    rgba = (0, 0, 0, 0)
                img.putpixel((x, y), rgba)

    if scale > 1:
        img = img.resize((width * scale, height * scale), Image.NEAREST)

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"[OK] Sprite saved: {output_path} ({img.size[0]}x{img.size[1]})")
    return img

def create_spritesheet(frame_paths, output_path, columns=0, spacing=0):
    """
    Stitches multiple PNG frames into a single spritesheet.
    """
    if not frame_paths:
        print("[Error] No frame paths provided.")
        return

    frames = [Image.open(p).convert("RGBA") for p in frame_paths]
    w, h = frames[0].size
    n_frames = len(frames)

    cols = columns if columns > 0 else n_frames
    import math
    rows = math.ceil(n_frames / cols)

    sheet_w = (w * cols) + (spacing * (cols - 1))
    sheet_h = (h * rows) + (spacing * (rows - 1))

    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))

    meta_frames = []
    for idx, frame in enumerate(frames):
        c = idx % cols
        r = idx // cols
        x = c * (w + spacing)
        y = r * (h + spacing)
        sheet.paste(frame, (x, y))
        meta_frames.append({
            "index": idx,
            "x": x, "y": y,
            "width": w, "height": h
        })

    out_file = Path(output_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_file, "PNG")

    json_file = out_file.with_suffix(".json")
    with open(json_file, "w") as f:
        json.dump({
            "spritesheet": out_file.name,
            "frame_width": w,
            "frame_height": h,
            "columns": cols,
            "rows": rows,
            "total_frames": n_frames,
            "frames": meta_frames
        }, f, indent=2)

    print(f"[OK] Spritesheet created: {out_file} ({sheet_w}x{sheet_h}) with metadata: {json_file}")

def slice_spritesheet(sheet_path, frame_w, frame_h, output_dir, prefix="frame"):
    """
    Slices a spritesheet into separate frame images.
    """
    sheet = Image.open(sheet_path).convert("RGBA")
    sw, sh = sheet.size
    cols = sw // frame_w
    rows = sh // frame_h

    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for r in range(rows):
        for c in range(cols):
            box = (c * frame_w, r * frame_h, (c + 1) * frame_w, (r + 1) * frame_h)
            frame = sheet.crop(box)
            frame_name = out_dir / f"{prefix}_{count:03d}.png"
            frame.save(frame_name, "PNG")
            count += 1

    print(f"[OK] Sliced {count} frames to {out_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pixel Art Sprite Utility")
    subparsers = parser.add_subparsers(dest="command")

    # Command: sheet
    p_sheet = subparsers.add_parser("sheet", help="Create spritesheet from images")
    p_sheet.add_argument("output", help="Output spritesheet PNG path")
    p_sheet.add_argument("frames", nargs="+", help="Input frame image paths")
    p_sheet.add_argument("--cols", type=int, default=0, help="Number of columns (default horizontal)")

    # Command: slice
    p_slice = subparsers.add_parser("slice", help="Slice spritesheet into frames")
    p_slice.add_argument("sheet", help="Spritesheet PNG path")
    p_slice.add_argument("width", type=int, help="Frame width")
    p_slice.add_argument("height", type=int, help="Frame height")
    p_slice.add_argument("outdir", help="Output directory")

    args = parser.parse_args()
    if args.command == "sheet":
        create_spritesheet(args.frames, args.output, columns=args.cols)
    elif args.command == "slice":
        slice_spritesheet(args.sheet, args.width, args.height, args.outdir)
    else:
        parser.print_help()
