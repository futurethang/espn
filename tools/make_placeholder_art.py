#!/usr/bin/env python3
"""Generate placeholder art from the locked palette.

    python3 tools/make_placeholder_art.py

Writes 16px PNGs into art/placeholder/. Everything here is temporary — Stage 5
replaces these files with Firefly Graph exports under the same names, so no
code changes when the real art lands. The point of generating rather than
drawing is that the palette stays the single source of truth.
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "placeholder"
TILE = 16

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow is required: pip install Pillow")


def load_palette() -> dict[str, tuple[int, int, int, int]]:
    raw = json.loads((ROOT / "data" / "palette.json").read_text())
    out = {}
    for name, hex_code in raw["colors"].items():
        h = hex_code.lstrip("#")
        out[name] = (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
    return out


def draw(size: int, pixels: dict[tuple[int, int], tuple[int, int, int, int]],
         background: tuple[int, int, int, int] | None = None) -> Image.Image:
    img = Image.new("RGBA", (size, size), background or (0, 0, 0, 0))
    for (x, y), colour in pixels.items():
        if 0 <= x < size and 0 <= y < size:
            img.putpixel((x, y), colour)
    return img


def ground_tile(p) -> Image.Image:
    """Grass with a scatter of lighter blades. Tiles seamlessly by construction:
    every speckle sits at least one pixel inside the edge."""
    px = {}
    speckles = [(3, 4), (9, 2), (13, 6), (5, 11), (11, 13), (2, 9), (7, 7)]
    for x, y in speckles:
        px[(x, y)] = p["grass_light"]
        px[(x, y + 1)] = p["grass_dark"]
    return draw(TILE, px, background=p["grass"])


def hero_sprite(p) -> Image.Image:
    """A 16x16 placeholder hero. Warm against green so it reads at a glance —
    silhouette and value contrast matter more than detail at this size."""
    rows = [
        "................",
        "................",
        ".....HHHHHH.....",
        "....HHHHHHHH....",
        "....HLLHHLLH....",
        "....HHHHHHHH....",
        "....HHIIIIHH....",
        ".....HHHHHH.....",
        "....SSSSSSSS....",
        "...SSSSSSSSSS...",
        "...SSSSSSSSSS...",
        "....SSSSSSSS....",
        ".....SS..SS.....",
        ".....SS..SS.....",
        "....III..III....",
        "................",
    ]
    key = {"H": p["hero"], "L": p["light"], "I": p["ink"], "S": p["shadow"]}
    px = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in key:
                px[(x, y)] = key[ch]
    return draw(TILE, px)


def stone(p) -> Image.Image:
    """A landmark. Uniform ground gives the eye nothing to measure movement
    against, which makes screenshots useless for judging motion."""
    rows = [
        "................",
        "................",
        "................",
        "................",
        ".....EEEE.......",
        "....EDDDDE......",
        "...EDDDDDDE.....",
        "...EDDDDDDE.....",
        "....EDDDDE......",
        ".....EEEE.......",
        "......II........",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]
    key = {"E": p["earth"], "D": p["light"], "I": p["ink"]}
    px = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in key:
                px[(x, y)] = key[ch]
    return draw(TILE, px)


def main() -> None:
    p = load_palette()
    OUT.mkdir(parents=True, exist_ok=True)
    art = (
        ("ground.png", ground_tile(p)),
        ("hero.png", hero_sprite(p)),
        ("stone.png", stone(p)),
    )
    for name, image in art:
        image.save(OUT / name)
        print(f"wrote art/placeholder/{name}")


if __name__ == "__main__":
    main()
