extends TestBase
## The stepping rules. This is where "movement feels crisp" is actually
## decided, and none of it is visible in a screenshot.

const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const LEFT := Vector2i(-1, 0)
const RIGHT := Vector2i(1, 0)


func test_starts_where_it_is_placed() -> void:
	var walker := GridWalker.new(Vector2i(3, 7))
	expect_eq(walker.tile, Vector2i(3, 7), "start tile")
	expect(not walker.is_stepping, "not stepping before any input")


func test_a_step_moves_one_tile() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	expect(walker.request(RIGHT), "step accepted")
	expect_eq(walker.tile, Vector2i(1, 0), "moved one tile right")
	expect(walker.is_stepping, "stepping until the renderer finishes")


func test_zero_direction_is_ignored() -> void:
	var walker := GridWalker.new(Vector2i(4, 4))
	expect(not walker.request(Vector2i.ZERO), "no step for no direction")
	expect_eq(walker.tile, Vector2i(4, 4), "did not move")


func test_input_mid_step_is_buffered_and_spent_once() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.request(RIGHT)
	expect(not walker.request(DOWN), "second input does not step immediately")
	expect_eq(walker.tile, Vector2i(1, 0), "still at the first target mid-step")

	walker.finish_step()
	expect_eq(walker.tile, Vector2i(1, 1), "buffered step spent on landing")
	expect(walker.is_stepping, "the buffered step is now in flight")

	walker.finish_step()
	expect_eq(walker.tile, Vector2i(1, 1), "buffer is empty, no third step")
	expect(not walker.is_stepping, "came to rest")


func test_buffer_keeps_only_the_latest_intent() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.request(RIGHT)
	walker.request(DOWN)
	walker.request(UP)
	walker.finish_step()
	expect_eq(walker.tile, Vector2i(1, -1), "the last direction pressed is the one taken")


func test_finish_step_without_a_step_is_harmless() -> void:
	var walker := GridWalker.new(Vector2i(2, 2))
	walker.finish_step()
	expect_eq(walker.tile, Vector2i(2, 2), "did not move")
	expect(not walker.is_stepping, "still at rest")


func test_blocked_tiles_are_refused() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(target: Vector2i) -> bool: return target.x < 2

	expect(walker.request(RIGHT), "first step into open ground")
	walker.finish_step()
	expect_eq(walker.tile, Vector2i(1, 0), "at the edge of the open area")

	expect(not walker.request(RIGHT), "step into a blocker refused")
	expect_eq(walker.tile, Vector2i(1, 0), "did not move into the blocker")
	expect(not walker.is_stepping, "a refused step does not start an animation")


func test_blocked_input_is_not_buffered() -> void:
	# Holding a key against a wall must not fire the moment the wall opens.
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(target: Vector2i) -> bool: return target != Vector2i(1, 1)

	walker.request(RIGHT)          # steps to (1,0)
	walker.request(DOWN)           # buffers DOWN, which lands on the blocker
	walker.finish_step()           # tries the buffered step, which is refused
	expect_eq(walker.tile, Vector2i(1, 0), "blocked buffered step leaves us put")
	expect(not walker.is_stepping, "and does not start an animation")


func test_teleport_clears_motion_and_buffer() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.request(RIGHT)
	walker.request(DOWN)
	walker.teleport(Vector2i(9, 9))

	expect_eq(walker.tile, Vector2i(9, 9), "arrived at the portal target")
	expect(not walker.is_stepping, "not mid-step after a teleport")

	walker.finish_step()
	expect_eq(walker.tile, Vector2i(9, 9), "the pre-teleport buffer did not survive")


func test_step_started_reports_both_tiles() -> void:
	var walker := GridWalker.new(Vector2i(5, 5))
	var seen: Array = []
	walker.step_started.connect(func(from: Vector2i, to: Vector2i) -> void:
		seen.append([from, to]))

	walker.request(LEFT)
	expect_eq(seen.size(), 1, "one step reported")
	expect_eq(seen[0][0], Vector2i(5, 5), "from tile")
	expect_eq(seen[0][1], Vector2i(4, 5), "to tile")
