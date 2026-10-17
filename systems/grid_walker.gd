extends RefCounted
## The stepping rules for anything that moves one tile at a time.
##
## This holds no nodes and draws nothing — it is the decision layer, so it can
## be tested without running the game. The Player scene owns one of these and
## renders whatever it reports. Critters in Act III will do the same.
##
## The buffer is what makes movement feel crisp rather than sticky: a key
## pressed part-way through a step is remembered and spent the moment that
## step lands, instead of being dropped.
class_name GridWalker

## Emitted when a step is accepted. The renderer tweens between these.
signal step_started(from_tile: Vector2i, to_tile: Vector2i)

## Emitted when a step is refused. The walker stays put; whoever is listening
## decides what that means — a nudge against a wall, or interacting with
## whatever is standing there. Keeping that decision outside the walker is
## what lets the same rules drive the player and, later, critters.
signal bumped(from_tile: Vector2i, into_tile: Vector2i)

var tile: Vector2i:
	get:
		return _tile

## True while a step is in flight. Input arriving now goes to the buffer.
var is_stepping: bool:
	get:
		return _is_stepping

## Decides whether a tile may be entered. Replaced in Stage 2 by a check
## against the TileMapLayer's `walkable` custom data layer. Until then every
## tile is open.
var can_enter: Callable = func(_target: Vector2i) -> bool: return true

## The last direction asked for, whether or not the step succeeded. You turn
## to face a wall you walked into.
var facing: Vector2i:
	get:
		return _facing

var _tile: Vector2i = Vector2i.ZERO
var _is_stepping: bool = false
var _buffered: Vector2i = Vector2i.ZERO
var _facing: Vector2i = Vector2i(0, 1)

## The direction we are currently stuck in. Latched so that holding a key
## against a wall bumps once rather than once per frame — without it, a sign
## would repeat its message six times a second and a one-shot bush would be
## picked and re-reported in the same breath. Cleared by a successful step,
## by trying a different direction, or by release().
var _blocked_direction: Vector2i = Vector2i.ZERO


func _init(start_tile: Vector2i = Vector2i.ZERO) -> void:
	_tile = start_tile


## Ask to move one tile in `direction`. Mid-step the request is buffered
## instead, replacing whatever was buffered before — the most recent intent
## is the one the player meant.
## Returns true if the step began immediately.
func request(direction: Vector2i) -> bool:
	if direction == Vector2i.ZERO:
		return false
	if _is_stepping:
		_buffered = direction
		return false
	return _begin(direction)


## Call when the renderer has finished animating the current step. Spends the
## buffered direction if there is one, which may start the next step at once.
func finish_step() -> void:
	if not _is_stepping:
		return
	_is_stepping = false
	var next := _buffered
	_buffered = Vector2i.ZERO
	if next != Vector2i.ZERO:
		_begin(next)


## The tile the walker is facing. What an explicit interact press acts on.
func facing_tile() -> Vector2i:
	return _tile + _facing


## Place the walker without animating, for spawning and portal arrivals.
func teleport(to_tile: Vector2i) -> void:
	_tile = to_tile
	_is_stepping = false
	_buffered = Vector2i.ZERO
	_blocked_direction = Vector2i.ZERO


## Report that nothing is being asked for right now, so the next press in a
## direction we are stuck in counts as a fresh attempt. Driven by input, which
## is why the walker cannot work it out for itself.
func release() -> void:
	_blocked_direction = Vector2i.ZERO


func _begin(direction: Vector2i) -> bool:
	_facing = direction
	var target: Vector2i = _tile + direction
	if not can_enter.call(target):
		# Blocked: drop the input rather than queueing it, so holding a key
		# against a wall does not fire the instant the wall goes away.
		if direction != _blocked_direction:
			_blocked_direction = direction
			bumped.emit(_tile, target)
		return false
	var from: Vector2i = _tile
	_tile = target
	_blocked_direction = Vector2i.ZERO
	_is_stepping = true
	step_started.emit(from, target)
	return true
