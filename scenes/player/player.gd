extends Node2D
## The hero. Owns a GridWalker for the rules and renders what it reports.
##
## `_unhandled_input` is used rather than `_input` so that UI (the brewing
## panel in Stage 4) gets first refusal on key presses — anything a Control
## node consumes never reaches here.

## How long one tile step takes. Short enough to feel responsive, long enough
## to read as movement rather than a teleport. Tune by feel, not by theory.
@export var step_duration: float = 0.12

## Where the hero starts, in tiles.
@export var start_tile: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = $Sprite2D

var walker: GridWalker

var _tween: Tween


func _ready() -> void:
	walker = GridWalker.new(start_tile)
	walker.step_started.connect(_on_step_started)
	position = Grid.tile_to_world(walker.tile)


func _unhandled_input(event: InputEvent) -> void:
	var direction := _direction_from(event)
	if direction != Vector2i.ZERO:
		walker.request(direction)
		get_viewport().set_input_as_handled()


## Map the four movement actions to grid directions. Returns ZERO for anything
## that is not a fresh movement press.
func _direction_from(event: InputEvent) -> Vector2i:
	if event.is_echo():
		# Key repeat would fire far faster than one step; holding a key is
		# handled by _process instead, at exactly one step per animation.
		return Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	if event.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	if event.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	if event.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func _process(_delta: float) -> void:
	# Holding a direction keeps you walking. Only consulted between steps, so
	# the pace is set by step_duration rather than the frame rate.
	if walker.is_stepping:
		return
	var held := Vector2i(
		int(Input.get_axis("move_left", "move_right")),
		int(Input.get_axis("move_up", "move_down"))
	)
	if held == Vector2i.ZERO:
		return
	# Favour one axis at a time: diagonal input on a 4-direction grid should
	# pick a single direction rather than doing nothing.
	if held.x != 0 and held.y != 0:
		held.y = 0
	walker.request(held)


func _on_step_started(_from_tile: Vector2i, to_tile: Vector2i) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# A Tween is a throwaway object that animates a property over time; it is
	# created fresh per step and cleans itself up when finished.
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "position", Grid.tile_to_world(to_tile), step_duration)
	_tween.finished.connect(walker.finish_step)
