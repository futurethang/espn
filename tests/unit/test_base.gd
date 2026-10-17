extends RefCounted
## Base class for test suites. Subclass it, then write methods named test_*.
class_name TestBase

var _sink: Callable = Callable()


## The runner injects where assertion results go. Not called by tests.
func expect_sink_set(sink: Callable) -> void:
	_sink = sink


## Assert that `condition` holds. `message` describes what was expected.
func expect(condition: bool, message: String) -> void:
	if _sink.is_valid():
		_sink.call(condition, message)


func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	expect(actual == expected, "%s (got %s, expected %s)" % [message, actual, expected])
