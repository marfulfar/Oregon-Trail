extends Node2D

@export var ground_layer: TileMapLayer

@export var evergreen_scene: PackedScene
@export var bush_scene: PackedScene
@export var mushroom_scene: PackedScene

var spawn_rules := {
	"forest": {
		"tree": 0.3,
		"bush": 0.10,
		"mushroom": 0.20
	},
	"grassland": {
		"tree": 0.05,
		"bush": 0.2
	}
}	

func _ready() -> void:
	scatter_vegetation()

func scatter_vegetation() -> void:
	var used_cells = ground_layer.get_used_cells()

	for cell in used_cells:
		var tile_data = ground_layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		var terrain_type = tile_data.get_custom_data("terrain_type")
		if not spawn_rules.has(terrain_type):
			continue

		var rules = spawn_rules[terrain_type]
		_try_spawn(cell, evergreen_scene, rules.get("tree", 0.0))
		_try_spawn(cell, bush_scene, rules.get("bush", 0.0))
		_try_spawn(cell, mushroom_scene, rules.get("mushroom", 0.0))

func _try_spawn(cell: Vector2i, scene: PackedScene, chance: float) -> void:
	if scene == null or chance <= 0.0:
		return
	if randf() > chance:
		return

	var instance = scene.instantiate()
	var base_pos = ground_layer.map_to_local(cell)
	var jitter = Vector2(randf_range(-6, 6), randf_range(-6, 6))
	instance.position = base_pos + jitter
	add_child(instance)
