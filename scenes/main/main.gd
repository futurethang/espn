extends Node2D
## Root scene. For Stage 0 this only proves the project boots at the right
## scale with the right clear colour; later stages mount the world here.

func _ready() -> void:
	var size: Vector2i = get_viewport().get_visible_rect().size
	print("Potion Forager booted — viewport %dx%d" % [size.x, size.y])
