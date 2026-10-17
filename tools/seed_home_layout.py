#!/usr/bin/env python3
"""Bootstrap a first pass at the home realm's three tile layers.

    python3 tools/seed_home_layout.py

This writes scenes/main/main.tscn. It exists so that work done away from the
Godot editor has a home worth looking at — it is NOT a pipeline. Once the home
is painted properly in the editor, this script is dead weight: delete it rather
than re-running it over hand-painted work.

TileMapLayer stores its cells as a PackedByteArray: a uint16 format header
(0), then twelve bytes per cell — x, y, source_id, atlas_x, atlas_y and
alternative, each a little-endian uint16.
"""

import base64
import pathlib
import random
import struct

ROOT = pathlib.Path(__file__).resolve().parent.parent
WIDTH, HEIGHT = 40, 30
SEED = 20261017

GRASS = [(0, 0), (1, 0), (2, 0), (3, 0)]
PATH = [(4, 0), (5, 0)]
DIRT = (6, 0)
WATER = (7, 0)
FLOWERS, PEBBLES, MUSHROOM, TUFT = (0, 1), (1, 1), (2, 1), (3, 1)
TREE, ROCK, STUMP, FENCE = (0, 2), (1, 2), (2, 2), (3, 2)


def pack(cells: dict[tuple[int, int], tuple[int, int]]) -> str:
    """Encode {(x, y): (atlas_x, atlas_y)} as a tile_map_data literal."""
    blob = struct.pack("<H", 0)  # format version
    for (x, y), (ax, ay) in sorted(cells.items()):
        # Coordinates are stored unsigned; negatives would wrap, but the home
        # realm is laid out from the origin outward so none occur.
        blob += struct.pack("<HHHHHH", x, y, 0, ax, ay, 0)
    return 'PackedByteArray("' + base64.b64encode(blob).decode() + '")'


def build() -> tuple[dict, dict, dict]:
    rng = random.Random(SEED)
    ground, obstacles, decor = {}, {}, {}

    for y in range(HEIGHT):
        for x in range(WIDTH):
            # Weighted so one variant dominates; the rest break up the repeat.
            ground[(x, y)] = rng.choices(GRASS, weights=[6, 2, 2, 1])[0]

    # A pond. Water is painted on the ground layer but is not walkable, which
    # is the point of putting the rule in tile data rather than in a layer.
    for y in range(6, 11):
        for x in range(7, 14):
            if 7 < x < 13 or 6 < y < 10:
                ground[(x, y)] = WATER
    for x in range(6, 15):
        for y in (5, 11):
            if (x, y) in ground and ground[(x, y)] != WATER:
                ground[(x, y)] = DIRT

    # A path east-west through the middle, with a spur north toward the pond.
    for x in range(WIDTH):
        y = 20 + (1 if 12 < x < 26 else 0)
        ground[(x, y)] = rng.choice(PATH)
        ground[(x, y + 1)] = rng.choice(PATH)
    for y in range(12, 21):
        ground[(10, y)] = rng.choice(PATH)

    def clear(x: int, y: int, pad: int = 0) -> bool:
        """Keep obstacles off the path, the pond and the hero's start tile."""
        for dy in range(-pad, pad + 1):
            for dx in range(-pad, pad + 1):
                cell = ground.get((x + dx, y + dy))
                if cell is None or cell in PATH or cell == WATER or cell == DIRT:
                    return False
        if abs(x - 20) <= 1 and abs(y - 20) <= 1:
            return False
        if (x, y) in {(18, 21), (22, 19), (23, 22), (17, 19)}:
            return False
        return (x, y) not in obstacles

    # Trees in loose clumps — things in nature appear in groups, and scattered
    # singles read as noise.
    for _ in range(14):
        cx, cy = rng.randrange(2, WIDTH - 2), rng.randrange(2, HEIGHT - 2)
        for _ in range(rng.randint(2, 5)):
            x, y = cx + rng.randint(-2, 2), cy + rng.randint(-2, 2)
            if 1 <= x < WIDTH - 1 and 2 <= y < HEIGHT - 1 and clear(x, y, 1):
                obstacles[(x, y)] = TREE

    for _ in range(12):
        x, y = rng.randrange(1, WIDTH - 1), rng.randrange(1, HEIGHT - 1)
        if clear(x, y):
            obstacles[(x, y)] = rng.choice([ROCK, STUMP])

    # A short fence run beside the path, so there is something obviously
    # man-made to walk around.
    for x in range(24, 30):
        if clear(x, 17):
            obstacles[(x, 17)] = FENCE

    # Decor sits on walkable ground: mushrooms near trees, flowers in the open.
    for _ in range(70):
        x, y = rng.randrange(WIDTH), rng.randrange(HEIGHT)
        if (x, y) in obstacles or ground.get((x, y)) in (WATER, DIRT):
            continue
        near_tree = any(
            obstacles.get((x + dx, y + dy)) == TREE
            for dx in (-1, 0, 1) for dy in (-1, 0, 1)
        )
        if near_tree:
            decor[(x, y)] = rng.choice([MUSHROOM, TUFT])
        elif ground.get((x, y)) not in PATH:
            decor[(x, y)] = rng.choice([FLOWERS, TUFT, PEBBLES])

    return ground, obstacles, decor


def main() -> None:
    ground, obstacles, decor = build()
    # Props sit beside the hero's start so there is always something to walk
    # into. Placement is deliberate, not seeded — these are landmarks.
    props = [
        ("Sign", "4_sign", (18, 21)),
        ("BerryBush", "5_bush", (22, 19)),
        ("BerryBush2", "5_bush", (23, 22)),
        ("Stone", "6_stone", (17, 19)),
    ]
    prop_nodes = "\n".join(
        f'''[node name="{name}" parent="Props" instance=ExtResource("3_prop")]
tile = Vector2i({tx}, {ty})
data = ExtResource("{res}")
'''
        for name, res, (tx, ty) in props
    )

    scene = f'''[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scenes/main/main.gd" id="1_main"]
[ext_resource type="TileSet" path="res://data/tilesets/home.tres" id="2_tileset"]
[ext_resource type="PackedScene" path="res://scenes/prop/prop.tscn" id="3_prop"]
[ext_resource type="Resource" path="res://data/interactables/sign.tres" id="4_sign"]
[ext_resource type="Resource" path="res://data/interactables/berry_bush.tres" id="5_bush"]
[ext_resource type="Resource" path="res://data/interactables/standing_stone.tres" id="6_stone"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="7_player"]

[node name="Main" type="Node2D"]
y_sort_enabled = true
script = ExtResource("1_main")

[node name="Ground" type="TileMapLayer" parent="."]
tile_map_data = {pack(ground)}
tile_set = ExtResource("2_tileset")

[node name="Decor" type="TileMapLayer" parent="."]
tile_map_data = {pack(decor)}
tile_set = ExtResource("2_tileset")

[node name="Obstacles" type="TileMapLayer" parent="."]
y_sort_enabled = true
tile_map_data = {pack(obstacles)}
tile_set = ExtResource("2_tileset")

[node name="Props" type="Node2D" parent="."]
y_sort_enabled = true

{prop_nodes}
[node name="Player" parent="." instance=ExtResource("7_player")]
start_tile = Vector2i(20, 20)
'''
    (ROOT / "scenes" / "main" / "main.tscn").write_text(scene)
    print(f"wrote scenes/main/main.tscn — "
          f"{len(ground)} ground, {len(obstacles)} obstacle, {len(decor)} decor cells")


if __name__ == "__main__":
    main()
