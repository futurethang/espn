extends Node2D
## The hero. Turns input into requests, and hands everything else off.
##
## It owns a GridWalker for the rules and an ActorVisual for the look, and
## deliberately knows nothing about tiles, props or art. Swapping the visual
## or adding a movement rule does not touch this script.
##
## `_unhandled_input` is used rather than `_input` so UI (Stage 4's brewing
## panel) gets first refusal on key presses.

## Emitted when the hero tries to use whatever is in a tile. The world
## resolves it — the player does not know props exist.
signal wants_to_interact(tile: Vector2i)

## How long one tile step takes. Short enough to feel responsive, long
## enough to read as movement. Tune by feel.
@export var step_duration: float = 0.13

## How long the lean-and-return takes when a step is refused. Shorter than a
## step, so walking into a wall never costs you a beat.
@export var bump_duration: float = 0.16

@export var start_tile: Vector2i = Vector2i.ZERO

@onready var _visual: ActorVisual = $ActorVisual

var walker: GridWalker

var _tween: Tween


func _ready() -> void:
	walker = GridWalker.new(start_tile)
	walker.step_started.connect(_on_step_started)
	walker.bumped.connect(_on_bumped)
	position = Grid.tile_to_world(walker.tile)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed("interact"):
		wants_to_interact.emit(walker.facing_tile())
		get_viewport().set_input_as_handled()
		return

	var direction := _direction_from(event)
	if direction != Vector2i.ZERO:
		walker.request(direction)
		get_viewport().set_input_as_handled()


func _direction_from(event: InputEvent) -> Vector2i:
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
	# the pace comes from step_duration rather than the frame rate.
	if walker.is_stepping:
		return
	var held := Vector2i(
		int(Input.get_axis("move_left", "move_right")),
		int(Input.get_axis("move_up", "move_down"))
	)
	if held == Vector2i.ZERO:
		# Nothing held: a later press in a blocked direction is a fresh try.
		walker.release()
		return
	# One axis at a time: diagonal input on a 4-direction grid should pick a
	# direction rather than doing nothing.
	if held.x != 0 and held.y != 0:
		held.y = 0
	walker.request(held)


func _on_step_started(_from_tile: Vector2i, to_tile: Vector2i) -> void:
	_visual.face(walker.facing)
	_visual.play_step(step_duration)

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", Grid.tile_to_world(to_tile), step_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(walker.finish_step)


## A refused step is still a message: lean into whatever stopped us, and ask
## the world whether it was something worth using.
func _on_bumped(_from_tile: Vector2i, into_tile: Vector2i) -> void:
	_visual.face(walker.facing)
	_visual.play_bump(walker.facing, bump_duration)
	wants_to_interact.emit(into_tile)


## Called by the world when an interaction actually did something.
func acknowledge_interaction() -> void:
	_visual.play_react()
