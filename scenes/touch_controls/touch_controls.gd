extends CanvasLayer
## On-screen controls for touch devices.
##
## This is an input layer and nothing more: it synthesises the same actions a
## keyboard produces, so the Player, the walker and the rules never learn that
## touch exists. Adding a gamepad later works the same way.
##
## Actions are sent as parsed InputEventActions rather than Input.action_press
## because only a parsed event travels the real pipeline into
## _unhandled_input — which is where `interact` is handled. action_press alone
## sets the held state and would silently do nothing for it.
class_name TouchControls

## Show the pad even without a touchscreen. Useful for checking layout in a
## desktop browser, where the buttons also respond to the mouse.
@export var always_visible: bool = false

@onready var _root: Control = $Root


func _ready() -> void:
	visible = always_visible or DisplayServer.is_touchscreen_available()
	if not visible:
		return
	for button in _find_buttons(_root):
		var action: StringName = StringName(button.name.to_snake_case())
		if not InputMap.has_action(action):
			push_warning("TouchControls: no action named '%s'" % action)
			continue
		button.button_down.connect(_send.bind(action, true))
		button.button_up.connect(_send.bind(action, false))


## Every Button under `node`, whatever the container nesting.
func _find_buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	for child in node.get_children():
		if child is Button:
			found.append(child)
		found.append_array(_find_buttons(child))
	return found


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
