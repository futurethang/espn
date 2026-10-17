extends RefCounted
## Which object, if any, occupies a tile.
##
## Objects are scenes placed in the world, not tiles, so walkability data
## cannot answer for them. The registry is the lookup that bump-to-interact
## and the blocking movement rule both read.
class_name InteractableRegistry

## Emitted when the set of occupied tiles changes, so anything caching
## reachability can invalidate. Act II's generators will want this.
signal changed

var _by_tile: Dictionary = {}


## Register `node` at `tile`. Registering over an occupied tile replaces the
## previous occupant — two objects on one tile is an authoring mistake, and
## silently keeping the older one hides it.
func register(tile: Vector2i, node: Node) -> void:
	_by_tile[tile] = node
	changed.emit()


func unregister(tile: Vector2i) -> void:
	if _by_tile.erase(tile):
		changed.emit()


## The object at `tile`, or null.
func at(tile: Vector2i) -> Node:
	return _by_tile.get(tile)


func has(tile: Vector2i) -> bool:
	return _by_tile.has(tile)


func occupied_tiles() -> Array:
	return _by_tile.keys()


## A MovementRules predicate: false where a blocking object stands.
## Non-blocking objects (a sign you can read, a plant you brush past) do not
## stop movement, so they are not consulted here.
func is_open(tile: Vector2i) -> bool:
	var node: Node = _by_tile.get(tile)
	if node == null:
		return true
	return not node.blocks_movement


func open_callable() -> Callable:
	return is_open
