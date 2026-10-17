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


func test_bump_reports_the_tile_we_could_not_enter() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(_t: Vector2i) -> bool: return false
	var seen: Array = []
	walker.bumped.connect(func(from: Vector2i, into: Vector2i) -> void:
		seen.append([from, into]))

	walker.request(RIGHT)
	expect_eq(seen.size(), 1, "one bump reported")
	expect_eq(seen[0][0], Vector2i(0, 0), "bumped from here")
	expect_eq(seen[0][1], Vector2i(1, 0), "into the blocked tile")


func test_holding_against_a_wall_bumps_once() -> void:
	# Held input re-requests every frame. Without the latch a sign would
	# repeat its message continuously and a one-shot prop would be spent and
	# re-reported in the same press.
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(_t: Vector2i) -> bool: return false
	# Counted into an Array on purpose: a lambda captures a local int by
	# value, so `bumps += 1` inside one would increment a copy.
	var bumps: Array = []
	walker.bumped.connect(func(_f: Vector2i, _i: Vector2i) -> void: bumps.append(1))

	for i in 20:
		walker.request(RIGHT)
	expect_eq(bumps.size(), 1, "twenty frames of held input, one bump")


func test_release_re_arms_the_bump() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(_t: Vector2i) -> bool: return false
	# Counted into an Array on purpose: a lambda captures a local int by
	# value, so `bumps += 1` inside one would increment a copy.
	var bumps: Array = []
	walker.bumped.connect(func(_f: Vector2i, _i: Vector2i) -> void: bumps.append(1))

	walker.request(RIGHT)
	walker.release()
	walker.request(RIGHT)
	expect_eq(bumps.size(), 2, "letting go and pressing again is a fresh attempt")


func test_turning_away_re_arms_the_bump() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(_t: Vector2i) -> bool: return false
	# Counted into an Array on purpose: a lambda captures a local int by
	# value, so `bumps += 1` inside one would increment a copy.
	var bumps: Array = []
	walker.bumped.connect(func(_f: Vector2i, _i: Vector2i) -> void: bumps.append(1))

	walker.request(RIGHT)
	walker.request(RIGHT)
	walker.request(DOWN)
	walker.request(RIGHT)
	expect_eq(bumps.size(), 3, "each change of direction is a new attempt")


func test_a_successful_step_clears_the_latch() -> void:
	var open_tiles := {Vector2i(1, 0): true}
	var walker := GridWalker.new(Vector2i(0, 0))
	walker.can_enter = func(t: Vector2i) -> bool: return open_tiles.has(t)
	# Counted into an Array on purpose: a lambda captures a local int by
	# value, so `bumps += 1` inside one would increment a copy.
	var bumps: Array = []
	walker.bumped.connect(func(_f: Vector2i, _i: Vector2i) -> void: bumps.append(1))

	walker.request(DOWN)          # blocked, latches DOWN
	walker.request(RIGHT)         # steps to (1,0)
	walker.finish_step()
	walker.request(DOWN)          # blocked again, but from a new tile
	expect_eq(bumps.size(), 2, "walking somewhere makes the old block stale")


func test_facing_follows_every_attempt() -> void:
	var walker := GridWalker.new(Vector2i(0, 0))
	expect_eq(walker.facing, Vector2i(0, 1), "starts facing down")

	walker.request(RIGHT)
	expect_eq(walker.facing, RIGHT, "faces where it moved")
	walker.finish_step()

	walker.can_enter = func(_t: Vector2i) -> bool: return false
	walker.request(UP)
	expect_eq(walker.facing, UP, "faces a wall it walked into")


func test_facing_tile_is_the_one_in_front() -> void:
	var walker := GridWalker.new(Vector2i(5, 5))
	walker.can_enter = func(_t: Vector2i) -> bool: return false
	walker.request(LEFT)
	expect_eq(walker.tile, Vector2i(5, 5), "blocked, so still here")
	expect_eq(walker.facing_tile(), Vector2i(4, 5), "the tile an interact press acts on")
