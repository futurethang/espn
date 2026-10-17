extends RefCounted
## Reads the `walkable` custom data layer off a stack of TileMapLayers.
##
## This is the bridge between painted art and movement rules: a tile is
## walkable because its TileSet data says so, not because a script has a list
## of coordinates. Paint a tree, and it blocks.
##
## Layers are checked in order and the first one with a tile at that cell
## wins, so an obstacle painted over grass blocks even though the grass
## underneath is open.
class_name TileMapWalkability

const DATA_LAYER := "walkable"

var _layers: Array[TileMapLayer] = []


## `layers` should run from topmost to bottommost (obstacles before ground).
func _init(layers: Array[TileMapLayer] = []) -> void:
	_layers = layers


## True when `tile` can be stepped into. A cell with no tile in any layer is
## off the edge of the painted world, and is not walkable — otherwise the
## hero wanders into the void.
func is_walkable(tile: Vector2i) -> bool:
	for layer in _layers:
		if layer == null:
			continue
		var data: TileData = layer.get_cell_tile_data(tile)
		if data == null:
			continue
		return bool(data.get_custom_data(DATA_LAYER))
	return false


## Convenience for handing straight to GridWalker.can_enter.
func as_callable() -> Callable:
	return is_walkable
