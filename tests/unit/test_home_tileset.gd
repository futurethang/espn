extends TestBase
## Guards the hand-authored TileSet. Its text format is easy to get subtly
## wrong in ways that look almost right on screen — a tile that is one row
## short, or a blocker you can walk through.

const TILESET_PATH := "res://data/tilesets/home.tres"

const GRASS := Vector2i(0, 0)
const PATH_A := Vector2i(4, 0)
const DIRT := Vector2i(6, 0)
const WATER := Vector2i(7, 0)
const FLOWERS := Vector2i(0, 1)
const TREE := Vector2i(0, 2)
const ROCK := Vector2i(1, 2)
const FENCE := Vector2i(3, 2)

## Held deliberately. A TileSetAtlasSource keeps only a non-owning pointer
## back to its TileSet, and TileData reads custom data through it — so if the
## TileSet is allowed to free, every lookup quietly starts returning null
## instead of failing loudly.
var _tile_set: TileSet

var _source: TileSetAtlasSource


func before_all() -> void:
	_tile_set = load(TILESET_PATH)
	if _tile_set != null and _tile_set.get_source_count() > 0:
		_source = _tile_set.get_source(_tile_set.get_source_id(0))


func _walkable(coords: Vector2i) -> Variant:
	var data: TileData = _source.get_tile_data(coords, 0)
	if data == null:
		return null
	return data.get_custom_data("walkable")


func test_tileset_loads_with_one_atlas_source() -> void:
	expect(_tile_set != null, "home.tres loads as a TileSet")
	expect_eq(_tile_set.get_source_count(), 1, "one atlas source")
	expect_eq(_tile_set.tile_size, Vector2i(16, 16), "16px tiles")


func test_walkable_data_layer_exists() -> void:
	expect_eq(_tile_set.get_custom_data_layers_count(), 1, "one custom data layer")
	expect_eq(_tile_set.get_custom_data_layer_by_name("walkable"), 0, "named 'walkable'")


func test_ground_and_decor_are_walkable() -> void:
	for coords in [GRASS, Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
			PATH_A, Vector2i(5, 0), DIRT, FLOWERS, Vector2i(1, 1),
			Vector2i(2, 1), Vector2i(3, 1)]:
		expect_eq(_walkable(coords), true, "%s is walkable" % coords)


func test_blockers_are_not_walkable() -> void:
	for coords in [WATER, TREE, ROCK, Vector2i(2, 2), FENCE]:
		expect_eq(_walkable(coords), false, "%s blocks" % coords)


func test_every_tile_declares_walkability() -> void:
	# A tile that forgot the custom data reads as null, and bool(null) is
	# false — so a missing value silently turns ground into a wall.
	for i in _source.get_tiles_count():
		var coords: Vector2i = _source.get_tile_id(i)
		expect(_walkable(coords) is bool, "%s declares walkable" % coords)


func test_tree_is_two_tiles_tall_and_sits_on_its_base() -> void:
	expect_eq(_source.get_tile_size_in_atlas(TREE), Vector2i(1, 2),
		"tree occupies two atlas rows")
	# A two-row tile is drawn straddling its cell, half above and half below,
	# so without the lift the trunk sits half a tile south of the cell that
	# actually blocks movement. Positive moves the art up.
	var data: TileData = _source.get_tile_data(TREE, 0)
	expect_eq(data.texture_origin, Vector2i(0, 8),
		"tree lifted so its trunk stands in the blocked cell")


func test_single_tiles_are_not_offset() -> void:
	for coords in [GRASS, PATH_A, ROCK, FENCE, FLOWERS]:
		var data: TileData = _source.get_tile_data(coords, 0)
		expect_eq(data.texture_origin, Vector2i(0, 0), "%s has no offset" % coords)
