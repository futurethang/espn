extends Node2D
## One scene for every bumpable object in the world.
##
## A sign, a berry bush and a boulder differ only in their InteractableData,
## so adding a prop is a .tres file and a placement — not a new scene or
## script. That is the whole point: when Firefly art lands, props change by
## pointing at different atlas cells.
class_name Prop

## Emitted on every successful interaction. The world listens, not the prop,
## so a prop never needs to know about the HUD, the inventory or the player.
signal interacted(prop: Prop, message: String)

@export var data: InteractableData

## Which tile this prop stands on. Set by the author in the editor; the prop
## snaps itself to the tile centre so placement cannot drift off-grid.
@export var tile: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = $Sprite2D

## True once a one-shot prop has been used.
var is_spent: bool = false

var blocks_movement: bool:
	get:
		return data != null and data.blocks_movement


func _ready() -> void:
	add_to_group("props")
	position = Grid.tile_to_world(tile)
	_refresh_sprite()


## Use this prop. Returns the message to show, or an empty string when there
## was nothing to do.
func interact() -> String:
	if data == null:
		return ""
	if is_spent:
		return data.spent_message
	if data.one_shot:
		is_spent = true
		_refresh_sprite()
	interacted.emit(self, data.message)
	return data.message


## Point the sprite at the right atlas cell. Spent props fall back to their
## normal look when no spent cell is given.
func _refresh_sprite() -> void:
	if data == null or _sprite == null:
		return
	var coords: Vector2i = data.atlas_coords
	if is_spent and data.spent_atlas_coords.x >= 0:
		coords = data.spent_atlas_coords
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(
		coords.x * Grid.TILE_SIZE, coords.y * Grid.TILE_SIZE,
		Grid.TILE_SIZE, Grid.TILE_SIZE
	)
