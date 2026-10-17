extends TestBase
## Which object stands where, and whether it stops you.

const TILE := Vector2i(3, 4)
const OTHER := Vector2i(9, 9)


## The registry holds scene nodes, so the double is a Node too — a
## RefCounted stand-in would not type-check against register().
class FakeProp extends Node:
	var blocks_movement: bool = true

	func _init(blocks: bool = true) -> void:
		blocks_movement = blocks


var _made: Array[Node] = []


func after_all() -> void:
	for node in _made:
		node.free()
	_made.clear()


func _prop(blocks: bool = true) -> FakeProp:
	var prop := FakeProp.new(blocks)
	_made.append(prop)
	return prop


func test_empty_registry_finds_nothing() -> void:
	var registry := InteractableRegistry.new()
	expect(registry.at(TILE) == null, "nothing registered")
	expect(not registry.has(TILE), "and has() agrees")


func test_register_and_look_up() -> void:
	var registry := InteractableRegistry.new()
	var prop := _prop()
	registry.register(TILE, prop)
	expect(registry.at(TILE) == prop, "found at its tile")
	expect(registry.at(OTHER) == null, "not found anywhere else")


func test_unregister_removes_it() -> void:
	var registry := InteractableRegistry.new()
	registry.register(TILE, _prop())
	registry.unregister(TILE)
	expect(registry.at(TILE) == null, "gone")


func test_registering_twice_replaces() -> void:
	var registry := InteractableRegistry.new()
	var first := _prop()
	var second := _prop()
	registry.register(TILE, first)
	registry.register(TILE, second)
	expect(registry.at(TILE) == second, "the later registration wins")


func test_changed_fires_on_register_and_unregister() -> void:
	var registry := InteractableRegistry.new()
	var events: Array = []
	registry.changed.connect(func() -> void: events.append(1))

	registry.register(TILE, _prop())
	expect_eq(events.size(), 1, "registering is a change")
	registry.unregister(TILE)
	expect_eq(events.size(), 2, "unregistering is a change")
	registry.unregister(TILE)
	expect_eq(events.size(), 2, "removing nothing changes nothing")


func test_blocking_props_close_their_tile() -> void:
	var registry := InteractableRegistry.new()
	registry.register(TILE, _prop(true))
	expect(not registry.is_open(TILE), "a solid prop blocks")
	expect(registry.is_open(OTHER), "empty ground stays open")


func test_non_blocking_props_do_not() -> void:
	var registry := InteractableRegistry.new()
	registry.register(TILE, _prop(false))
	expect(registry.is_open(TILE), "you can walk over a non-blocking prop")


func test_composes_with_tile_walkability() -> void:
	# The real wiring: painted tiles and placed props both get a say.
	var registry := InteractableRegistry.new()
	registry.register(Vector2i(1, 0), _prop(true))
	var rules := MovementRules.new([
		func(t: Vector2i) -> bool: return t.y == 0,   # stands in for tile data
		registry.open_callable(),
	])
	expect(rules.can_enter(Vector2i(2, 0)), "open ground, no prop")
	expect(not rules.can_enter(Vector2i(1, 0)), "prop blocks walkable ground")
	expect(not rules.can_enter(Vector2i(2, 1)), "tile data blocks with no prop")
