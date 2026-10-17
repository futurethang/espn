extends TestBase
## Rule composition. The point of MovementRules is that a new reason to be
## blocked never edits GridWalker — these tests pin that down.

const A := Vector2i(1, 1)
const B := Vector2i(2, 2)


func test_no_rules_means_everything_is_open() -> void:
	var rules := MovementRules.new()
	expect(rules.can_enter(A), "a bare walker is unconstrained")


func test_a_single_rule_decides() -> void:
	var rules := MovementRules.new([func(t: Vector2i) -> bool: return t == A])
	expect(rules.can_enter(A), "allowed tile")
	expect(not rules.can_enter(B), "everything else blocked")


func test_every_rule_must_agree() -> void:
	var rules := MovementRules.new([
		func(t: Vector2i) -> bool: return t.x > 0,
		func(t: Vector2i) -> bool: return t.y > 0,
	])
	expect(rules.can_enter(Vector2i(1, 1)), "both rules satisfied")
	expect(not rules.can_enter(Vector2i(-1, 1)), "first rule refuses")
	expect(not rules.can_enter(Vector2i(1, -1)), "second rule refuses")


func test_rules_can_be_added_later() -> void:
	var rules := MovementRules.new()
	expect(rules.can_enter(B), "open before the rule exists")
	rules.add(func(t: Vector2i) -> bool: return t != B)
	expect(not rules.can_enter(B), "closed once it is added")


func test_add_returns_self_for_chaining() -> void:
	var rules := MovementRules.new()
	var returned: MovementRules = rules.add(func(_t: Vector2i) -> bool: return true)
	expect(returned == rules, "add() chains")


func test_the_rule_list_is_copied_on_construction() -> void:
	# Otherwise a caller mutating the array it passed in silently rewrites
	# the movement rules of a live game.
	var source: Array[Callable] = [func(_t: Vector2i) -> bool: return true]
	var rules := MovementRules.new(source)
	source.append(func(_t: Vector2i) -> bool: return false)
	expect(rules.can_enter(A), "later edits to the source array do not leak in")


func test_drives_a_grid_walker() -> void:
	var rules := MovementRules.new([func(t: Vector2i) -> bool: return t.x <= 1])
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = rules.as_callable()

	expect(walker.request(Vector2i(1, 0)), "into the open")
	walker.finish_step()
	expect(not walker.request(Vector2i(1, 0)), "into the rule")
	expect_eq(walker.tile, Vector2i(1, 0), "stayed put")
