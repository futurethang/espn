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


# The tileset atlas, one row per tile role. Keeping roles in rows rather than
# scattered is what lets Stage 6 describe a biome as "ground is row 0" instead
# of listing coordinates.
#
# Row 0  ground   grass x4, path x2, dirt, water-ish
# Row 1  blocker  tree, rock, stump, fence
# Row 2  decor    flowers, pebbles, mushroom, tuft
ATLAS_COLUMNS = 8
ATLAS_ROWS = 4


def _speckled(p, base: str, fleck: str, seed: int, count: int) -> dict:
    """Scatter `count` flecks deterministically. Pseudo-random from `seed`
    rather than random.random() so re-running the script is a no-op in git."""
    px = {}
    value = seed * 2654435761 % 2147483647
    for _ in range(count):
        value = (value * 1103515245 + 12345) % 2147483648
        x = 1 + value % (TILE - 2)
        value = (value * 1103515245 + 12345) % 2147483648
        y = 1 + value % (TILE - 2)
        px[(x, y)] = p[fleck]
    return px


def ground_tiles(p) -> list[Image.Image]:
    """Four grass variants. Variance is what makes movement legible: on a
    single repeating tile a camera that follows the hero produces a frame that
    never changes."""
    out = []
    for i, (fleck, count) in enumerate(
        [("grass_light", 5), ("grass_dark", 7), ("grass_light", 2), ("grass_dark", 3)]
    ):
        out.append(draw(TILE, _speckled(p, "grass", fleck, i + 1, count), background=p["grass"]))
    return out


def path_tiles(p) -> list[Image.Image]:
    out = []
    for i in range(2):
        out.append(draw(TILE, _speckled(p, "earth", "light", i + 11, 4), background=p["earth"]))
    return out


def dirt_tile(p) -> Image.Image:
    return draw(TILE, _speckled(p, "grass_dark", "earth", 21, 6), background=p["grass_dark"])


def water_tile(p) -> Image.Image:
    px = {}
    for x in range(TILE):
        for y in range(TILE):
            if (x + y * 3) % 7 == 0:
                px[(x, y)] = p["light"]
    return draw(TILE, px, background=p["shadow"])


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


def _from_rows(p, rows: list[str], key: dict) -> Image.Image:
    px = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in key:
                px[(x, y)] = p[key[ch]]
    return draw(TILE, px)


def tree(p) -> Image.Image:
    """16x32 — two tiles tall. The canopy overhangs the tile above the trunk,
    which is the whole reason y-sorting exists: walk north of the trunk and
    the hero should pass behind the leaves."""
    rows = [
        "................",
        ".....DDDDDD.....",
        "...DDGGGGGGDD...",
        "..DGGGGGGGGGGD..",
        ".DGGGGLLGGGGGGD.",
        ".DGGGLLLLGGGGGD.",
        "DGGGGGLLGGGGGGGD",
        "DGGGGGGGGGGGGGGD",
        "DGGGGGGGGGGGGGGD",
        ".DGGGGGGGGGGGGD.",
        ".DDGGGGGGGGGGDD.",
        "..DDGGGGGGGGDD..",
        "....DDGGGGDD....",
        "......DDDD......",
        "................",
        "................",
        ".......EE.......",
        ".......EE.......",
        "......EEEE......",
        "......EIIE......",
        "......EIIE......",
        "......EIIE......",
        ".....EEIIEE.....",
        ".....EE..EE.....",
        "....EE....EE....",
        "...DD......DD...",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]
    key = {"D": "grass_dark", "G": "grass_light", "L": "light", "E": "earth", "I": "ink"}
    px = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in key:
                px[(x, y)] = p[key[ch]]
    img = Image.new("RGBA", (TILE, TILE * 2), (0, 0, 0, 0))
    for (x, y), colour in px.items():
        img.putpixel((x, y), colour)
    return img


def rock(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "................",
        ".....SSSS.......",
        "....SLLLLS......",
        "...SLLLLLLS.....",
        "...SLLLLLLS.....",
        "....SLLLLS......",
        ".....SSSS.......",
        "......II........",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'S': 'shadow', 'L': 'light', 'I': 'ink'})


def stump(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "................",
        "................",
        "......EEEE......",
        ".....EDDDDE.....",
        ".....EDIIDE.....",
        ".....EDDDDE.....",
        "......EEEE......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'E': 'ink', 'D': 'earth', 'I': 'shadow'})


def fence(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "..E..........E..",
        "..E..........E..",
        ".EEEEEEEEEEEEEE.",
        "..E..........E..",
        "..E..........E..",
        ".EEEEEEEEEEEEEE.",
        "..E..........E..",
        "..E..........E..",
        "..I..........I..",
        "................",
        "................",
        "................",
        "................",
    ], {'E': 'earth', 'I': 'ink'})


def flowers(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "....L......L....",
        "...LHL....LHL...",
        "....L..L...L....",
        "....D.LHL..D....",
        "....D..L...D....",
        ".......D........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'L': 'light', 'H': 'hero', 'D': 'grass_dark'})


def pebbles(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "................",
        "................",
        "...SS......S....",
        "...SS.....SS....",
        "................",
        "........SS......",
        "......S.SS......",
        "......S.........",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'S': 'shadow'})


def mushroom(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "................",
        "......HHH.......",
        ".....HHLHH......",
        ".....HHHHH......",
        "......LLL.......",
        "......L.L.......",
        "......LLL.......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'H': 'hero', 'L': 'light'})


def tuft(p) -> Image.Image:
    return _from_rows(p, [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "...G...G..G.....",
        "..G.G.G.G.G.G...",
        "..G.G.G.G.G.G...",
        "...D...D..D.....",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {'G': 'grass_light', 'D': 'grass_dark'})


def build_atlas(p) -> Image.Image:
    """Lay every tile into one atlas, grouped by role.

    Row 0   ground    grass x4, path x2, dirt, water
    Row 1   decor     flowers, pebbles, mushroom, tuft
    Rows 2-3 blockers tree (one column, two rows tall), rock, stump, fence

    The TileSet resource reads coordinates out of this grid, so the order is
    load-bearing. Stage 6 turns these rows into named tile roles.
    """
    atlas = Image.new("RGBA", (ATLAS_COLUMNS * TILE, ATLAS_ROWS * TILE), (0, 0, 0, 0))

    ground = ground_tiles(p) + path_tiles(p) + [dirt_tile(p), water_tile(p)]
    for x, tile in enumerate(ground):
        atlas.paste(tile, (x * TILE, 0))

    for x, tile in enumerate([flowers(p), pebbles(p), mushroom(p), tuft(p)]):
        atlas.paste(tile, (x * TILE, TILE))

    atlas.paste(tree(p), (0, TILE * 2))
    for i, tile in enumerate([rock(p), stump(p), fence(p)]):
        atlas.paste(tile, ((i + 1) * TILE, TILE * 2))

    return atlas


def main() -> None:
    p = load_palette()
    OUT.mkdir(parents=True, exist_ok=True)
    art = (
        ("tileset.png", build_atlas(p)),
        ("hero.png", hero_sprite(p)),
    )
    for name, image in art:
        image.save(OUT / name)
        print(f"wrote art/placeholder/{name}")


if __name__ == "__main__":
    main()
