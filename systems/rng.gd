extends Node
## Seeded randomness for the whole game. Autoloaded as `Rng`.
##
## Every random decision — map generation, loot, critter parts — goes through
## here so that a run is reproducible from its seed alone. Nothing should call
## randi() or randf() directly.

var seed_value: int = 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if seed_value == 0:
		reseed(Time.get_unix_time_from_system() as int)


## Restart the stream from `new_seed`. Same seed in, same sequence out.
## Assigning `seed` also rewinds `state`; setting state separately would
## discard the seed and make every run identical.
func reseed(new_seed: int) -> void:
	seed_value = new_seed
	_rng.seed = new_seed


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf_value() -> float:
	return _rng.randf()


## Pick one element with uniform probability.
func pick(options: Array) -> Variant:
	if options.is_empty():
		return null
	return options[_rng.randi_range(0, options.size() - 1)]


## Pick one index from `weights`, proportional to each weight.
## Returns -1 when every weight is zero or the array is empty.
func pick_weighted(weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for w in weights:
		total += maxf(w, 0.0)
	if total <= 0.0:
		return -1
	var roll: float = _rng.randf() * total
	for i in weights.size():
		roll -= maxf(weights[i], 0.0)
		if roll < 0.0:
			return i
	return weights.size() - 1
