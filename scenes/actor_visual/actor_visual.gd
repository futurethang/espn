extends Node2D
## How an actor looks and reacts, with no idea where it is or what it may do.
##
## Everything that decides something — rules, stepping, interaction — talks to
## this through four methods and never touches a Sprite2D. That boundary is
## what makes art swappable: replacing the placeholder with Firefly Graph
## exports, or giving critters a different visual entirely, means a different
## scene behind the same API, not edits to movement code.
##
##     face(direction)                 turn to look that way
##     play_step(duration)             a step is under way
##     play_bump(direction, duration)  a step was refused
##     play_react()                    something here responded to us
class_name ActorVisual

## Squash at the start of a step, easing back to rest. Small numbers: the
## point is to suggest weight, not to bounce.
@export var step_squash: Vector2 = Vector2(1.12, 0.88)

## How far toward a blocked tile to lean, as a fraction of a tile.
@export var bump_distance: float = 0.28

## Flip the sprite horizontally when facing left. Fine for a symmetrical
## placeholder; real directional art replaces this scene instead.
@export var flip_when_facing_left: bool = true

@onready var _sprite: Sprite2D = $Sprite2D

var _rest_position: Vector2
var _tween: Tween


func _ready() -> void:
	_rest_position = _sprite.position


func face(direction: Vector2i) -> void:
	if flip_when_facing_left and direction.x != 0:
		_sprite.flip_h = direction.x < 0


## Squash on departure and settle over the step. Called once per step, with
## the same duration the position tween uses, so the two stay in sync.
func play_step(duration: float) -> void:
	_restart_tween()
	_sprite.scale = step_squash
	_tween.tween_property(_sprite, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Lean into the obstruction and come back. Reads as "I tried", which is the
## difference between a wall and an unresponsive game.
func play_bump(direction: Vector2i, duration: float) -> void:
	_restart_tween()
	var lean: Vector2 = Vector2(direction) * Grid.TILE_SIZE * bump_distance
	_tween.tween_property(_sprite, "position", _rest_position + lean, duration * 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sprite, "position", _rest_position, duration * 0.65) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A small acknowledgement that something responded — used on interaction, so
## picking a berry feels different from walking into a rock.
func play_react() -> void:
	_restart_tween()
	_sprite.scale = Vector2(0.82, 1.18)
	_tween.tween_property(_sprite, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## One tween at a time: a bump arriving mid-step must cancel the step's
## easing, or the two fight over scale and position.
func _restart_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_sprite.position = _rest_position
	_tween = create_tween()
