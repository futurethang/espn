extends SceneTree
## Headless test runner. Usage:
##   godot --headless --script res://tools/run_tests.gd
##
## Discovers every tests/unit/test_*.gd, instances it, and calls each method
## named test_*. A test fails by calling expect() with a false condition.
## Exit code is 0 only when every test passes, so CI can gate on it.

const TESTS_DIR := "res://tests/unit"

var _failures: PackedStringArray = []
var _passed: int = 0
var _current: String = ""


func _initialize() -> void:
	var files := _discover()
	if files.is_empty():
		push_warning("No test files found in %s" % TESTS_DIR)

	for path in files:
		var script: GDScript = load(path)
		if script == null:
			_failures.append("%s — failed to load" % path)
			continue
		var suite: Object = script.new()
		if suite.has_method("before_all"):
			suite.call("before_all")
		for method in _test_methods(script):
			_current = "%s::%s" % [path.get_file(), method]
			suite.call("expect_sink_set", Callable(self, "_record"))
			var before := _failures.size()
			suite.call(method)
			if _failures.size() == before:
				_passed += 1
		if suite.has_method("after_all"):
			suite.call("after_all")

	_report()
	quit(0 if _failures.is_empty() else 1)


func _discover() -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		return found
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			found.append("%s/%s" % [TESTS_DIR, file])
	found.sort()
	return found


func _test_methods(script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = []
	for entry in script.get_script_method_list():
		var method_name: String = entry["name"]
		if method_name.begins_with("test_"):
			names.append(method_name)
	names.sort()
	return names


func _record(ok: bool, message: String) -> void:
	if ok:
		return
	_failures.append("%s — %s" % [_current, message])


func _report() -> void:
	print("")
	print("%d passed, %d failed" % [_passed, _failures.size()])
	for failure in _failures:
		print("  FAIL  %s" % failure)
