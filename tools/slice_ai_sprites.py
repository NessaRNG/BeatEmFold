#!/usr/bin/env python3
"""
tools/slice_ai_sprites.py

Normalize a raw AI-generated 4x4 sprite-sheet grid into a Godot-ready sheet.

Pipeline:
  1. Chroma-key the solid background using a border flood-fill, so only the
     connected background is removed (a same-coloured costume inside the
     character survives).
  2. Slice the grid into cells.
  3. For each cell: crop to its alpha content, scale to a uniform size with a
     single shared factor, and align feet to the bottom-center of the cell.
  4. Reassemble into a horizontal strip: N frames * 128x96.

Usage:
  python3 tools/slice_ai_sprites.py RAW.png OUT.png \
      --rows 4 --cols 4 --frames 16 \
      --chroma green --out-w 128 --out-h 96
"""

import argparse
from collections import deque

from PIL import Image


def make_is_key(chroma):
    presets = {
        "green": lambda r, g, b: g > r + 35 and g > b + 35 and g > 110,
        "magenta": lambda r, g, b: r > 110 and b > 110 and r > g + 40 and b > g + 40,
        "blue": lambda r, g, b: b > 110 and b > r + 40 and b > g + 30,
    }
    if chroma not in presets:
        raise SystemExit(f"unknown chroma {chroma!r}; choose from {list(presets)}")
    return presets[chroma]


def chroma_key_border(im, is_key):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    visited = bytearray(w * h)
    q = deque()

    def seed(x, y):
        i = y * w + x
        if not visited[i]:
            r, g, b, a = px[x, y]
            if is_key(r, g, b):
                visited[i] = 1
                q.append((x, y))

    for x in range(w):
        seed(x, 0)
        seed(x, h - 1)
    for y in range(h):
        seed(0, y)
        seed(w - 1, y)

    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                i = ny * w + nx
                if not visited[i]:
                    r, g, b, a = px[nx, ny]
                    if is_key(r, g, b):
                        visited[i] = 1
                        q.append((nx, ny))

    removed = 0
    for i in range(w * h):
        if visited[i]:
            x = i % w
            y = i // w
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 0)
            removed += 1
    return im, removed


def slice_grid(im, rows, cols, frames):
    w, h = im.size
    cw, ch = w // cols, h // rows
    cells = []
    for i in range(frames):
        r, c = divmod(i, cols)
        cells.append(im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)))
    return cells, cw, ch


def content_box(cell):
    a = cell.getchannel("A")
    bb = a.getbbox()
    if bb is None:
        return None
    # pad by 1px so antialiased edges are not clipped
    x0, y0, x1, y1 = bb
    return (max(0, x0 - 1), max(0, y0 - 1), min(cell.width, x1 + 1), min(cell.height, y1 + 1))


def scale_cell(cell, box, out_w, out_h, fill_ratio, max_upscale, resample):
    content = cell.crop(box)
    if content.width < 1 or content.height < 1:
        return Image.new("RGBA", (out_w, out_h))
    scale = min(
        (out_w - 6) / content.width,
        (out_h * fill_ratio) / content.height,
        max_upscale,
    )
    nw = max(1, int(round(content.width * scale)))
    nh = max(1, int(round(content.height * scale)))
    content = content.resize((nw, nh), resample)
    frame = Image.new("RGBA", (out_w, out_h))
    x = (out_w - nw) // 2
    y = out_h - nh - 2  # feet near the bottom of the cell
    frame.paste(content, (x, y), content)
    return frame


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("raw")
    ap.add_argument("out")
    ap.add_argument("--rows", type=int, default=4)
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--frames", type=int, default=16)
    ap.add_argument("--chroma", default="green")
    ap.add_argument("--out-w", type=int, default=128)
    ap.add_argument("--out-h", type=int, default=96)
    ap.add_argument("--fill-ratio", type=float, default=0.94)
    ap.add_argument("--max-upscale", type=float, default=2.5)
    ap.add_argument("--resample", default="nearest", choices=["nearest", "lanczos"])
    args = ap.parse_args()

    im = Image.open(args.raw).convert("RGBA")
    print(f"raw: {args.raw} size={im.size}")

    keyed, removed = chroma_key_border(im, make_is_key(args.chroma))
    print(f"chroma removed pixels: {removed}")

    cells, cw, ch = slice_grid(keyed, args.rows, args.cols, args.frames)
    print(f"cell size: {cw}x{ch}, cells: {len(cells)}")

    boxes = [content_box(c) for c in cells]
    empty = sum(1 for b in boxes if b is None)
    if empty:
        print(f"warning: {empty} empty cells")

    resample = Image.NEAREST if args.resample == "nearest" else Image.LANCZOS
    frames = []
    for c, b in zip(cells, boxes):
        if b is None:
            frames.append(Image.new("RGBA", (args.out_w, args.out_h)))
        else:
            frames.append(scale_cell(c, b, args.out_w, args.out_h,
                                     args.fill_ratio, args.max_upscale, resample))

    sheet = Image.new("RGBA", (args.out_w * len(frames), args.out_h))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * args.out_w, 0), f)
    sheet.save(args.out)
    print(f"saved: {args.out} size={sheet.size}")


if __name__ == "__main__":
    main()
