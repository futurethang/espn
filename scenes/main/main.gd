extends Node2D
## The home realm. Three painted layers plus the hero.
##
## Ground holds the walkable surface, Obstacles holds anything that blocks,
## and Decor holds things you walk over. Movement rules come from the TileSet
## itself — see TileMapWalkability — so painting is the only thing that
## decides where the hero can go.

@onready var _ground: TileMapLayer = $Ground
@onready var _obstacles: TileMapLayer = $Obstacles
@onready var _player: Node2D = $Player

var _walkability: TileMapWalkability


func _ready() -> void:
	# Obstacles first: a tree painted over grass must win.
	_walkability = TileMapWalkability.new([_obstacles, _ground])
	_player.walker.can_enter = _walkability.as_callable()
	_player.walker.step_started.connect(_on_player_step)
	print("Potion Forager — hero at tile %s" % _player.start_tile)


## Temporary Stage 2 instrumentation: prints each step, and refused steps, so
## movement and collision can be checked from a log when there is no screen to
## watch. The Stage 4 HUD replaces this.
func _on_player_step(from_tile: Vector2i, to_tile: Vector2i) -> void:
	print("step %s -> %s" % [from_tile, to_tile])
