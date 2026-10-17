extends Node
## Development screenshot hook. Autoloaded, but inert unless asked for.
##
## Running the real game and capturing from inside it means the shot goes
## through the project's own stretch settings, camera and renderer — so what
## lands in the PNG is what the window shows. Reconstructing that from
## outside is how you get screenshots that quietly lie.
##
##   godot -- --capture out.png [--scene res://scenes/x/x.tscn]
##                               [--input right,right,down] [--settle 0.3]
##                               [--shot-delay 0.05]
##
## --input presses movement actions in order before the shot, which is how
## behaviour that only exists in response to input can be verified without a
## keyboard.
##
## Driven by shoot.sh. Does nothing in a normal run.

var _out_path: String = ""
var _scene_path: String = ""
## Seconds to wait after each input and before the shot. Measured in time,
## not frames: with no vsync this runs at hundreds of frames per second, so a
## frame count that looks generous can be a couple of milliseconds and catch
## every tween mid-flight.
var _settle: float = 0.3

## How long to wait after the last action before shooting. Separate from
## _settle so a short-lived animation — a bump lasts about a sixth of a
## second — can be caught mid-flight without rushing the steps before it.
var _shot_delay: float = -1.0

var _input_actions: PackedStringArray = []


func _ready() -> void:
	_parse_args()
	if _out_path.is_empty():
		return
	# Run after everything else so the captured frame includes the whole tree.
	process_priority = 1000
	_run.call_deferred()


func _run() -> void:
	if not _scene_path.is_empty():
		var error: int = get_tree().change_scene_to_file(_scene_path)
		if error != OK:
			push_error("Cannot load scene %s (error %d)" % [_scene_path, error])
			get_tree().quit(1)
			return

	# Let _ready work finish, then play any requested input.
	await get_tree().process_frame
	await _play_input()

	# Let the last action's animation play for as long as asked.
	var delay: float = _shot_delay if _shot_delay >= 0.0 else _settle
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	# Camera smoothing eases toward its target and never quite arrives, so a
	# shot taken mid-ease frames the wrong part of the world. Snap it.
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		camera.reset_smoothing()
		camera.force_update_scroll()
		await get_tree().process_frame

	# Wait for the frame currently being drawn to actually hit the buffer,
	# otherwise get_image() can read a partially rendered viewport.
	await RenderingServer.frame_post_draw

	var image: Image = get_viewport().get_texture().get_image()
	var save_error: int = image.save_png(_out_path)
	if save_error != OK:
		push_error("Failed to write %s (error %d)" % [_out_path, save_error])
		get_tree().quit(1)
		return

	print("wrote %s (%dx%d)" % [_out_path, image.get_width(), image.get_height()])
	get_tree().quit(0)


## Fire each requested action as a press/release pair, leaving enough frames
## between them for a step to animate and land.
##
## Uses parse_input_event rather than Input.action_press: only a parsed event
## travels the real pipeline into _unhandled_input, which is the path the game
## actually uses. action_press sets the held state alone, which would test
## something the player never does.
func _play_input() -> void:
	for action in _input_actions:
		if not InputMap.has_action(action):
			push_error("Unknown input action: %s" % action)
			get_tree().quit(1)
			return
		await _send(action, true)
		await _send(action, false)
		# Let the step animate and land before the next press.
		await get_tree().create_timer(_settle).timeout


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await get_tree().process_frame


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		if i + 1 >= args.size():
			break
		match args[i]:
			"--capture":
				_out_path = args[i + 1]
			"--scene":
				_scene_path = args[i + 1]
			"--settle":
				_settle = float(args[i + 1])
			"--shot-delay":
				_shot_delay = float(args[i + 1])
			"--input":
				for name in args[i + 1].split(",", false):
					_input_actions.append("move_" + name.strip_edges())
