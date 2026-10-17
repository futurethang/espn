extends TestBase
## The determinism guarantee everything else leans on: a seed reproduces a run.

const RngScript := preload("res://systems/rng.gd")


var _made: Array[Node] = []


func _fresh(seed_value: int) -> Node:
	var rng: Node = RngScript.new()
	rng.reseed(seed_value)
	_made.append(rng)
	return rng


func after_all() -> void:
	for node in _made:
		node.free()
	_made.clear()


func test_same_seed_gives_same_sequence() -> void:
	var a := _fresh(12345)
	var b := _fresh(12345)
	for i in 50:
		expect_eq(a.randi_range(0, 999), b.randi_range(0, 999), "draw %d matches" % i)


func test_different_seeds_diverge() -> void:
	var a := _fresh(1)
	var b := _fresh(2)
	var same := 0
	for i in 50:
		if a.randi_range(0, 999) == b.randi_range(0, 999):
			same += 1
	expect(same < 10, "distinct seeds should rarely collide (collided %d/50)" % same)


func test_reseed_rewinds_the_stream() -> void:
	var rng := _fresh(777)
	var first: Array[int] = []
	for i in 10:
		first.append(rng.randi_range(0, 999))
	rng.reseed(777)
	for i in 10:
		expect_eq(rng.randi_range(0, 999), first[i], "draw %d after reseed" % i)


func test_randi_range_stays_in_bounds() -> void:
	var rng := _fresh(42)
	for i in 200:
		var v: int = rng.randi_range(3, 7)
		expect(v >= 3 and v <= 7, "value %d within [3, 7]" % v)


func test_pick_weighted_respects_zero_weights() -> void:
	var rng := _fresh(99)
	var weights := PackedFloat32Array([0.0, 1.0, 0.0])
	for i in 100:
		expect_eq(rng.pick_weighted(weights), 1, "only the non-zero weight is picked")


func test_pick_weighted_handles_empty() -> void:
	var rng := _fresh(5)
	expect_eq(rng.pick_weighted(PackedFloat32Array([])), -1, "empty weights give -1")
	expect_eq(rng.pick_weighted(PackedFloat32Array([0.0, 0.0])), -1, "all-zero weights give -1")


func test_pick_returns_null_on_empty() -> void:
	var rng := _fresh(5)
	expect_eq(rng.pick([]), null, "picking from nothing gives null")
