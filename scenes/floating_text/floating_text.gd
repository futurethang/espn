extends Node2D
## A line of text that drifts up and fades. The cheapest possible feedback
## that an interaction happened, and enough to make the world answer back
## before there is any HUD.
##
## Stage 4 replaces this with real UI; until then it keeps interaction
## visible in a screenshot, which is the only way to check it from here.
##
## It sits on an absolute z_index rather than joining the y-sort: text drawn
## above a prop would otherwise sort by that prop's y, and anything painted
## further south would cover it.
class_name FloatingText

@export var rise_pixels: float = 14.0
@export var lifetime: float = 1.4

@onready var _label: Label = $Label


## Spawn one above `world_position` under `parent`.
##
## Position and text are set before the drift starts. Doing it the other way
## round animates from wherever the node happened to be — which, since
## add_child runs _ready immediately, is the origin.
static func show_at(parent: Node, world_position: Vector2, text: String) -> FloatingText:
	var scene: PackedScene = load("res://scenes/floating_text/floating_text.tscn")
	var instance: FloatingText = scene.instantiate()
	parent.add_child(instance)
	instance.global_position = world_position
	instance.set_text(text)
	instance.begin()
	return instance


func set_text(text: String) -> void:
	_label.text = text


## Start the drift. Separate from _ready so the caller can place and fill it
## first.
func begin() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_pixels, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
