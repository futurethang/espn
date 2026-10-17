extends Node2D
## The home realm: it wires the pieces together and owns nothing else.
##
## This is where composition happens. Movement rules are assembled here from
## independent sources (painted tiles, placed props), and interaction is
## resolved here — so neither the player nor a prop has to know the other
## exists. Adding a rule or a kind of object is a change to this wiring, not
## to the parts.

@onready var _ground: TileMapLayer = $Ground
@onready var _obstacles: TileMapLayer = $Obstacles
@onready var _props: Node2D = $Props
@onready var _player: Node2D = $Player

var _walkability: TileMapWalkability
var _registry: InteractableRegistry
var _rules: MovementRules


func _ready() -> void:
	# Obstacles before ground: a tree painted over grass must win.
	_walkability = TileMapWalkability.new([_obstacles, _ground])
	_registry = _build_registry()

	# A tile is open when the painted world allows it AND nothing solid
	# stands there. Act III adds a third rule for critters.
	_rules = MovementRules.new([
		_walkability.as_callable(),
		_registry.open_callable(),
	])

	_player.walker.can_enter = _rules.as_callable()
	_player.walker.step_started.connect(_on_player_step)
	_player.wants_to_interact.connect(_on_wants_to_interact)


func _build_registry() -> InteractableRegistry:
	var registry := InteractableRegistry.new()
	for prop in _props.get_children():
		if prop is Prop:
			registry.register(prop.tile, prop)
	return registry


## Resolve an interaction request against whatever stands on that tile.
## Nothing there is a perfectly normal outcome — bumping a rock should not
## produce a message.
func _on_wants_to_interact(tile: Vector2i) -> void:
	var prop: Node = _registry.at(tile)
	if prop == null:
		return
	var message: String = prop.interact()
	if message.is_empty():
		return
	print("interact %s at %s: %s" % [prop.data.display_name, tile, message])
	FloatingText.show_at(self, prop.global_position, message)
	_player.acknowledge_interaction()


## Temporary instrumentation so movement is checkable from a log when there
## is no screen to watch. The Stage 4 HUD replaces this.
func _on_player_step(from_tile: Vector2i, to_tile: Vector2i) -> void:
	print("step %s -> %s" % [from_tile, to_tile])
