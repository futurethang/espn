#!/usr/bin/env python3
"""Generate data/tilesets/home.tres from the placeholder atlas layout.

    python3 tools/make_home_tileset.py

Writing the TileSet by hand is error-prone — a missing `custom_data_0` turns
ground into a wall, and the offsets for multi-tile art are easy to get
backwards. Generating it keeps the atlas layout (make_placeholder_art.py) and
the tile rules in step.

Once the home is painted in the editor and tiles get hand-tuned, this becomes
a bootstrap rather than a pipeline — same caveat as seed_home_layout.py.
"""

import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "tilesets" / "home.tres"

# (atlas_x, atlas_y, walkable, rows_tall)
#
# Row 0 ground, row 1 decor, row 2 blockers — matching build_atlas().
TILES = (
    [(x, 0, True, 1) for x in range(7)]        # grass x4, path x2, dirt
    + [(7, 0, False, 1)]                       # water: looks like ground, is not
    + [(x, 1, True, 1) for x in range(4)]      # decor is walked over
    + [(0, 2, False, 2)]                       # tree, two rows tall
    + [(x, 2, False, 1) for x in (1, 2, 3)]    # rock, stump, fence
)

# A tile taller than one cell is drawn straddling its cell — half above, half
# below — so it needs lifting by half its overhang to stand ON the cell that
# blocks movement. Positive moves the art up.
LIFT_PER_EXTRA_ROW = 8


def main() -> None:
    lines = []
    for ax, ay, walkable, rows in TILES:
        tile = f"{ax}:{ay}"
        lines.append(f"{tile}/0 = 0")
        if rows != 1:
            lines.append(f"{tile}/size_in_atlas = Vector2i(1, {rows})")
            lines.append(
                f"{tile}/0/texture_origin = "
                f"Vector2i(0, {LIFT_PER_EXTRA_ROW * (rows - 1)})"
            )
        lines.append(f"{tile}/0/custom_data_0 = {'true' if walkable else 'false'}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text('''[gd_resource type="TileSet" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://art/placeholder/tileset.png" id="1_atlas"]

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_home"]
texture = ExtResource("1_atlas")
texture_region_size = Vector2i(16, 16)
''' + "\n".join(lines) + '''

[resource]
resource_name = "Home"
tile_size = Vector2i(16, 16)
custom_data_layer_0/name = "walkable"
custom_data_layer_0/type = 1
sources/0 = SubResource("TileSetAtlasSource_home")
''')
    print(f"wrote data/tilesets/home.tres — {len(TILES)} tiles")


if __name__ == "__main__":
    main()
