extends TileMapLayer

@export var map_width: int = 60
@export var map_height: int = 60

@export var grass_source_ids: Array[int] = [2]
@export var forest_source_ids: Array[int] = [3]

@export var noise_frequency: float = 0.03
@export var noise_seed: int = 0

var noise := FastNoiseLite.new()

const ORIENTATIONS = [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H,
	TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
]

func _ready() -> void:
	generate_terrain()

func generate_terrain() -> void:
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.frequency = noise_frequency

	var half_w = map_width / 2
	var half_h = map_height / 2

	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			var value = noise.get_noise_2d(x, y)
			var cell = Vector2i(x, y)
			var orientation = ORIENTATIONS[randi() % ORIENTATIONS.size()]

			if value < 0.1:
				var source_id = grass_source_ids[randi() % grass_source_ids.size()]
				set_cell(cell, source_id, Vector2i(0, 0), orientation)
			else:
				var source_id = forest_source_ids[randi() % forest_source_ids.size()]
				set_cell(cell, source_id, Vector2i(0, 0), orientation)
