extends Resource
## What an object is, separate from how it looks or where it stands.
##
## A sign, a berry bush and a locked gate differ only in these fields, so new
## props are new .tres files under data/interactables/ rather than new scenes
## or new scripts.
class_name InteractableData

## Shown when the player interacts. Flavour only for now; Stage 4's HUD will
## render it properly.
@export var display_name: String = "Thing"
@export_multiline var message: String = "..."

## Whether standing here is possible. A sign blocks; long grass does not.
@export var blocks_movement: bool = true

## One-shot things can be used once — a bush you pick, a chest you open.
@export var one_shot: bool = false
@export_multiline var spent_message: String = "Nothing left."

## Atlas cell in the placeholder tileset to draw, and the cell to switch to
## once spent. Stage 5 replaces these with real textures; keeping them as
## data means the swap does not touch any script.
@export var atlas_coords: Vector2i = Vector2i(2, 2)
@export var spent_atlas_coords: Vector2i = Vector2i(-1, -1)
