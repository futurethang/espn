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

var _tile: Vector2i = Vector2i.ZERO
var _is_stepping: bool = false
var _buffered: Vector2i = Vector2i.ZERO


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


## Place the walker without animating, for spawning and portal arrivals.
func teleport(to_tile: Vector2i) -> void:
	_tile = to_tile
	_is_stepping = false
	_buffered = Vector2i.ZERO


func _begin(direction: Vector2i) -> bool:
	var target: Vector2i = _tile + direction
	if not can_enter.call(target):
		# Blocked: drop the input rather than queueing it, so holding a key
		# against a wall does not fire the instant the wall goes away.
		return false
	var from: Vector2i = _tile
	_tile = target
	_is_stepping = true
	step_started.emit(from, target)
	return true
