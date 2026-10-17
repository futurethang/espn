extends TestBase
## Painted tiles deciding where the hero can go. The layer precedence matters:
## an obstacle painted over grass has to win, or every tree is decorative.

const TILESET_PATH := "res://data/tilesets/home.tres"

const GRASS := Vector2i(0, 0)
const WATER := Vector2i(7, 0)
const FLOWERS := Vector2i(0, 1)
const TREE := Vector2i(0, 2)

# Held so the TileSet is not freed while its layers are still being read.
var _tile_set: TileSet

var _layers: Array[TileMapLayer] = []


func before_all() -> void:
	_tile_set = load(TILESET_PATH)


func after_all() -> void:
	for layer in _layers:
		layer.free()
	_layers.clear()


func _layer(cells: Dictionary) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _tile_set
	for tile in cells:
		layer.set_cell(tile, 0, cells[tile])
	_layers.append(layer)
	return layer


func test_painted_ground_is_walkable() -> void:
	var ground := _layer({Vector2i(0, 0): GRASS, Vector2i(1, 0): GRASS})
	var walkability := TileMapWalkability.new([ground])
	expect(walkability.is_walkable(Vector2i(0, 0)), "grass is open")
	expect(walkability.is_walkable(Vector2i(1, 0)), "grass is open")


func test_unpainted_cells_are_not_walkable() -> void:
	# Off the edge of the painted world. Without this the hero walks into
	# nothing for as long as you hold the key.
	var ground := _layer({Vector2i(0, 0): GRASS})
	var walkability := TileMapWalkability.new([ground])
	expect(not walkability.is_walkable(Vector2i(5, 5)), "unpainted cell blocks")
	expect(not walkability.is_walkable(Vector2i(-1, 0)), "negative cell blocks")


func test_water_blocks_even_though_it_is_ground() -> void:
	var ground := _layer({Vector2i(0, 0): WATER})
	var walkability := TileMapWalkability.new([ground])
	expect(not walkability.is_walkable(Vector2i(0, 0)), "water blocks")


func test_obstacle_layer_beats_ground() -> void:
	var ground := _layer({Vector2i(0, 0): GRASS, Vector2i(1, 0): GRASS})
	var obstacles := _layer({Vector2i(1, 0): TREE})
	var walkability := TileMapWalkability.new([obstacles, ground])
	expect(walkability.is_walkable(Vector2i(0, 0)), "open grass stays open")
	expect(not walkability.is_walkable(Vector2i(1, 0)), "tree over grass blocks")


func test_layer_order_is_respected() -> void:
	# Ground first would let the grass underneath answer for the tree.
	var ground := _layer({Vector2i(0, 0): GRASS})
	var obstacles := _layer({Vector2i(0, 0): TREE})
	var wrong_way := TileMapWalkability.new([ground, obstacles])
	expect(wrong_way.is_walkable(Vector2i(0, 0)),
		"ground-first lets the tree be walked through — which is why order matters")


func test_decor_does_not_block() -> void:
	var ground := _layer({Vector2i(0, 0): GRASS})
	var decor := _layer({Vector2i(0, 0): FLOWERS})
	var walkability := TileMapWalkability.new([decor, ground])
	expect(walkability.is_walkable(Vector2i(0, 0)), "you can walk through flowers")


func test_empty_layer_list_blocks_everything() -> void:
	var walkability := TileMapWalkability.new([])
	expect(not walkability.is_walkable(Vector2i(0, 0)), "nothing painted, nowhere to go")


func test_drives_a_grid_walker() -> void:
	# The actual contract: hand is_walkable to GridWalker and the hero stops.
	var ground := _layer({
		Vector2i(0, 0): GRASS, Vector2i(1, 0): GRASS, Vector2i(2, 0): GRASS,
	})
	var obstacles := _layer({Vector2i(2, 0): TREE})
	var walkability := TileMapWalkability.new([obstacles, ground])

	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = walkability.as_callable()

	expect(walker.request(Vector2i(1, 0)), "first step onto grass")
	walker.finish_step()
	expect_eq(walker.tile, Vector2i(1, 0), "moved")

	expect(not walker.request(Vector2i(1, 0)), "step into the tree refused")
	expect_eq(walker.tile, Vector2i(1, 0), "stayed put")
