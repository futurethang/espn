extends Node2D
## Root scene. Holds the field and the hero for Stage 1; later stages swap the
## field for real TileMapLayers and mount generated realms here.

@onready var _player: Node2D = $Player


func _ready() -> void:
	_player.walker.step_started.connect(_on_player_step)
	print("Potion Forager — hero at tile %s" % _player.start_tile)


## Temporary Stage 1 instrumentation: prints each step so movement can be
## verified from a log when there is no screen to watch. Goes away in Stage 4
## when the HUD shows position and turn count properly.
func _on_player_step(from_tile: Vector2i, to_tile: Vector2i) -> void:
	print("step %s -> %s" % [from_tile, to_tile])
