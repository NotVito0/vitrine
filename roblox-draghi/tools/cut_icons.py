#!/usr/bin/env python3
"""Ritaglia il foglio di icone 4x4 in 16 PNG con sfondo trasparente.

Uso:  python3 tools/cut_icons.py <foglio.png> <cartella di uscita>
Lo sfondo (il colore dell'angolo in alto a sinistra) diventa trasparente partendo dai bordi,
così il contorno bianco delle icone resta intatto.
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

NAMES = [
    "dragons", "shop", "gifts", "eggs",
    "quests", "daily", "skills", "style",
    "potions", "nest", "market", "rebirth",
    "coin", "gem", "trophy", "settings",
]


def clear_background(img, tolerance=38):
    rgba = np.array(img.convert("RGBA")).astype(np.int32)
    h, w = rgba.shape[:2]
    bg = rgba[2, 2, :3]
    diff = np.abs(rgba[:, :, :3] - bg).sum(axis=2)
    close = diff < tolerance
    seen = np.zeros((h, w), bool)
    queue = deque()
    for x in range(w):
        queue.append((0, x))
        queue.append((h - 1, x))
    for y in range(h):
        queue.append((y, 0))
        queue.append((y, w - 1))
    while queue:
        y, x = queue.popleft()
        if y < 0 or y >= h or x < 0 or x >= w or seen[y, x] or not close[y, x]:
            continue
        seen[y, x] = True
        queue.extend(((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)))
    rgba[seen, 3] = 0
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def main():
    sheet = Image.open(sys.argv[1])
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    cell = sheet.width // 4
    for i, name in enumerate(NAMES):
        x, y = (i % 4) * cell, (i // 4) * cell
        tile = sheet.crop((x, y, x + cell, y + cell))
        tile = clear_background(tile)
        box = tile.getbbox()
        if box:
            tile = tile.crop(box)
        side = max(tile.size) + 16
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(tile, ((side - tile.width) // 2, (side - tile.height) // 2))
        canvas = canvas.resize((256, 256), Image.LANCZOS)
        canvas.save(os.path.join(out, name + ".png"))
        print("ok", name)


if __name__ == "__main__":
    main()
