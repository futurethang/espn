extends SceneTree
## Capture a PNG of any scene, without a desktop. Driven by shoot.sh.
##
## Reads --scene, --out and --frames from the command line, mounts the scene
## under the root, lets it run for a few frames so tweens and _ready work
## settle, then writes the viewport to disk and quits.

var _scene_path: String = "res://scenes/main/main.tscn"
var _out_path: String = "user://shot.png"
var _frames: int = 10
var _elapsed: int = 0


func _initialize() -> void:
	_parse_args()

	var packed: PackedScene = load(_scene_path)
	if packed == null:
		push_error("Cannot load scene: %s" % _scene_path)
		quit(1)
		return

	root.add_child(packed.instantiate())
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _process(_delta: float) -> bool:
	_elapsed += 1
	if _elapsed < _frames:
		return false

	await process_frame
	var image: Image = root.get_texture().get_image()
	var error: int = image.save_png(_out_path)
	if error != OK:
		push_error("Failed to write %s (error %d)" % [_out_path, error])
		quit(1)
		return true

	print("wrote %s (%dx%d)" % [_out_path, image.get_width(), image.get_height()])
	quit(0)
	return true


func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--scene":
				if i + 1 < args.size():
					_scene_path = args[i + 1]
			"--out":
				if i + 1 < args.size():
					_out_path = args[i + 1]
			"--frames":
				if i + 1 < args.size():
					_frames = int(args[i + 1])
