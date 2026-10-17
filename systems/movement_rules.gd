extends RefCounted
## Composes the question "may this tile be entered?" out of independent rules.
##
## Each rule is a Callable taking a Vector2i and returning bool. A tile is
## open only when every rule agrees. Adding a reason to be blocked — a closed
## gate, a critter standing there, a potion that lets you cross water — means
## appending a rule, never editing GridWalker or the Player.
##
##     var rules := MovementRules.new([
##         walkability.as_callable(),
##         registry.open_callable(),
##     ])
##     walker.can_enter = rules.as_callable()
class_name MovementRules

var _rules: Array[Callable] = []


func _init(rules: Array[Callable] = []) -> void:
	_rules = rules.duplicate()


## Append a rule. Returns self so rules can be chained at a call site.
func add(rule: Callable) -> MovementRules:
	_rules.append(rule)
	return self


## True only when every rule says yes. With no rules at all nothing is
## blocked, which keeps a bare walker usable in tests.
func can_enter(tile: Vector2i) -> bool:
	for rule in _rules:
		if not rule.call(tile):
			return false
	return true


func as_callable() -> Callable:
	return can_enter
