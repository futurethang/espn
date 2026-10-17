extends TestBase
## Tile <-> pixel conversion. Off-by-one here would misalign every sprite in
## the game, and negative coordinates are the case that usually breaks.


func test_tile_to_world_centres_the_tile() -> void:
	expect_eq(Grid.tile_to_world(Vector2i(0, 0)), Vector2(8, 8), "origin tile centre")
	expect_eq(Grid.tile_to_world(Vector2i(1, 2)), Vector2(24, 40), "tile (1,2) centre")


func test_tile_to_world_handles_negatives() -> void:
	expect_eq(Grid.tile_to_world(Vector2i(-1, -1)), Vector2(-8, -8), "tile (-1,-1) centre")


func test_world_to_tile_floors_consistently() -> void:
	expect_eq(Grid.world_to_tile(Vector2(0, 0)), Vector2i(0, 0), "top-left of origin tile")
	expect_eq(Grid.world_to_tile(Vector2(15.9, 15.9)), Vector2i(0, 0), "bottom-right of origin tile")
	expect_eq(Grid.world_to_tile(Vector2(16, 16)), Vector2i(1, 1), "first pixel of next tile")


func test_world_to_tile_negatives_do_not_collapse() -> void:
	# int() truncation would put -0.5 and 0.5 in the same tile. Floor must not.
	expect_eq(Grid.world_to_tile(Vector2(-1, -1)), Vector2i(-1, -1), "just left of origin")
	expect_eq(Grid.world_to_tile(Vector2(-16, -16)), Vector2i(-1, -1), "start of tile (-1,-1)")
	expect_eq(Grid.world_to_tile(Vector2(-17, -17)), Vector2i(-2, -2), "start of tile (-2,-2)")


func test_round_trip_through_pixels() -> void:
	for x in range(-5, 6):
		for y in range(-5, 6):
			var tile := Vector2i(x, y)
			expect_eq(Grid.world_to_tile(Grid.tile_to_world(tile)), tile,
				"round trip for %s" % tile)


func test_step_distance_is_manhattan() -> void:
	expect_eq(Grid.step_distance(Vector2i(0, 0), Vector2i(3, 4)), 7, "3 across, 4 down")
	expect_eq(Grid.step_distance(Vector2i(2, 2), Vector2i(2, 2)), 0, "same tile")
	expect_eq(Grid.step_distance(Vector2i(-2, 0), Vector2i(2, 0)), 4, "across the origin")


func test_directions_are_the_four_orthogonals() -> void:
	expect_eq(Grid.DIRECTIONS.size(), 4, "four directions")
	for direction in Grid.DIRECTIONS:
		expect_eq(absi(direction.x) + absi(direction.y), 1, "%s is one step" % direction)
