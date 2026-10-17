extends TestBase
## Prop behaviour, which is entirely data-driven — these tests are really
## checking that a new object needs no new code.

const PROP_SCENE := "res://scenes/prop/prop.tscn"
const SIGN := "res://data/interactables/sign.tres"
const BUSH := "res://data/interactables/berry_bush.tres"

var _made: Array[Node] = []


func after_all() -> void:
	for node in _made:
		node.free()
	_made.clear()


## Built without entering the tree: _ready has not run, so the sprite is
## absent and only the data-driven behaviour is exercised.
func _prop(data_path: String) -> Node:
	var scene: PackedScene = load(PROP_SCENE)
	var prop: Node = scene.instantiate()
	prop.data = load(data_path)
	_made.append(prop)
	return prop


func test_data_resources_load() -> void:
	for path in [SIGN, BUSH, "res://data/interactables/standing_stone.tres"]:
		var data: InteractableData = load(path)
		expect(data != null, "%s loads" % path)
		expect(not data.display_name.is_empty(), "%s is named" % path)


func test_a_reusable_prop_repeats_itself() -> void:
	var prop := _prop(SIGN)
	expect_eq(prop.interact(), "East: the thicket", "first read")
	expect_eq(prop.interact(), "East: the thicket", "reads the same again")
	expect(not prop.is_spent, "a sign is never used up")


func test_a_one_shot_prop_is_spent_after_use() -> void:
	var prop := _prop(BUSH)
	expect(not prop.is_spent, "starts unpicked")
	expect_eq(prop.interact(), "Sunberries!", "picked")
	expect(prop.is_spent, "now spent")
	expect_eq(prop.interact(), "Picked clean.", "says so on a second try")
	expect_eq(prop.interact(), "Picked clean.", "and keeps saying so")


func test_interacted_fires_only_on_a_real_use() -> void:
	var prop := _prop(BUSH)
	var fired: Array = []
	prop.interacted.connect(func(_p: Node, message: String) -> void: fired.append(message))

	prop.interact()
	prop.interact()
	expect_eq(fired.size(), 1, "picking a bush twice is one event")


func test_blocks_movement_comes_from_data() -> void:
	expect(_prop(SIGN).blocks_movement, "a sign is solid")


func test_a_prop_without_data_does_nothing() -> void:
	var scene: PackedScene = load(PROP_SCENE)
	var prop: Node = scene.instantiate()
	_made.append(prop)
	expect_eq(prop.interact(), "", "no data, no message")
	expect(not prop.blocks_movement, "and nothing to walk into")
