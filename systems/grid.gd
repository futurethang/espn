extends RefCounted
## Tile <-> pixel conversion. The one place that knows how big a tile is.
##
## Game logic works in tile coordinates (Vector2i) and only converts to pixels
## when something has to be drawn. Keeping that boundary sharp is what lets the
## generators in Act II reason about maps without caring how they look.
class_name Grid

const TILE_SIZE: int = 16

## The four steps a grid walker may take. Order is stable so that anything
## iterating them (pathfinding, critter AI) behaves the same across runs.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),  # up
	Vector2i(0, 1),   # down
	Vector2i(-1, 0),  # left
	Vector2i(1, 0),   # right
]


## Centre of `tile` in pixels. Sprites sit in the middle of their tile, so a
## 16px sprite with a centred origin lines up with the grid exactly.
static func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		tile.x * TILE_SIZE + TILE_SIZE / 2.0,
		tile.y * TILE_SIZE + TILE_SIZE / 2.0
	)


## Which tile contains `world`. Uses floor division so that negative
## coordinates round the same way as positive ones — int() would round -0.5
## toward zero and put two different pixels in the same tile.
static func world_to_tile(world: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world.x / TILE_SIZE)),
		int(floor(world.y / TILE_SIZE))
	)


## Manhattan distance: how many orthogonal steps from `a` to `b`. This is the
## right distance measure for a 4-direction grid, and Act III's critter AI
## uses it for line-of-sight falloff and fleeing.
static func step_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
