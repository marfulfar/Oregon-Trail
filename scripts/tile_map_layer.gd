extends TileMapLayer

@export var map_width: int = 60
@export var map_height: int = 60

@export var grass_source_ids: Array[int] = [2]
@export var yellow_grass_source_ids: Array[int] = [4]
@export var forest_source_ids: Array[int] = [3]

## Single-cell atlas sources for the boundary blend art (see
## TRANSITION_TRANSFORMS below for how these get rotated to face the
## neighbor they're blending into).
@export var grass_transition_source_id: int = 7
@export var forest_transition_source_id: int = 8

@export var noise_frequency: float = 0.03
@export var noise_seed: int = 0

## Controls how big/frequent the yellow-grass patches are within the green
## grass biome. Higher frequency = smaller, more scattered patches.
@export var yellow_patch_frequency: float = 0.06
@export var yellow_patch_threshold: float = 0.25

var noise := FastNoiseLite.new()
var yellow_noise := FastNoiseLite.new()

enum Biome { FOREST, GRASS_GREEN, GRASS_YELLOW }

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

## Both transition textures have their "special" color (yellow, or dark
## forest) on the west half and green on the east half at identity
## transform. This maps "direction from a transition cell to the neighbor
## it's blending into" to the flip/transpose combo that rotates the special
## half to face that neighbor.
const TRANSITION_TRANSFORMS = {
	Vector2i(-1, 0): 0,
	Vector2i(1, 0): TileSetAtlasSource.TRANSFORM_FLIP_H,
	Vector2i(0, -1): TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	Vector2i(0, 1): TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
]

func _ready() -> void:
	generate_terrain()


## Two passes: first decide every cell's biome from noise, then paint.
## Painting needs the whole biome map up front so a cell can look at its
## neighbors' *final* biomes when deciding whether it needs a transition
## tile instead of a plain one.
func generate_terrain() -> void:
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.frequency = noise_frequency

	yellow_noise.seed = noise.seed + 1
	yellow_noise.frequency = yellow_patch_frequency

	var half_w = map_width / 2
	var half_h = map_height / 2

	var biomes: Dictionary = {}
	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			var cell = Vector2i(x, y)
			biomes[cell] = _biome_at(cell)

	# Yellow grass must never sit directly next to forest - the only path
	# between them is yellow -> [grass transition] -> green -> [forest
	# transition] -> forest. Demote any yellow cell caught bordering forest
	# straight to green so the painting pass below gives it a proper
	# transition tile on the forest side instead.
	for cell in biomes.keys():
		if biomes[cell] != Biome.GRASS_YELLOW:
			continue
		for offset in NEIGHBOR_OFFSETS:
			if biomes.get(cell + offset, Biome.GRASS_GREEN) == Biome.FOREST:
				biomes[cell] = Biome.GRASS_GREEN
				break

	for cell in biomes.keys():
		_paint_cell(cell, biomes)


func _biome_at(cell: Vector2i) -> Biome:
	if noise.get_noise_2d(cell.x, cell.y) >= 0.1:
		return Biome.FOREST
	if yellow_noise.get_noise_2d(cell.x, cell.y) >= yellow_patch_threshold:
		return Biome.GRASS_YELLOW
	return Biome.GRASS_GREEN


## Paints one cell: a plain tile for interior cells, or the correct
## transition tile (rotated to face the bordering biome) for green cells
## sitting right at a boundary. Yellow takes priority over forest in the
## rare case a single green cell borders both.
func _paint_cell(cell: Vector2i, biomes: Dictionary) -> void:
	var biome: Biome = biomes[cell]

	if biome == Biome.FOREST:
		_set_random_tile(cell, forest_source_ids)
		return

	if biome == Biome.GRASS_YELLOW:
		_set_random_tile(cell, yellow_grass_source_ids)
		return

	var yellow_dir := _find_neighbor_direction(cell, biomes, Biome.GRASS_YELLOW)
	if yellow_dir != Vector2i.ZERO:
		set_cell(cell, grass_transition_source_id, Vector2i(0, 0), TRANSITION_TRANSFORMS[yellow_dir])
		return

	var forest_dir := _find_neighbor_direction(cell, biomes, Biome.FOREST)
	if forest_dir != Vector2i.ZERO:
		set_cell(cell, forest_transition_source_id, Vector2i(0, 0), TRANSITION_TRANSFORMS[forest_dir])
		return

	_set_random_tile(cell, grass_source_ids)


## Returns the offset to the first orthogonal neighbor matching `target`
## biome, or Vector2i.ZERO if none border this cell.
func _find_neighbor_direction(cell: Vector2i, biomes: Dictionary, target: Biome) -> Vector2i:
	for offset in NEIGHBOR_OFFSETS:
		if biomes.get(cell + offset, Biome.GRASS_GREEN) == target:
			return offset
	return Vector2i.ZERO


func _set_random_tile(cell: Vector2i, source_ids: Array[int]) -> void:
	var source_id = source_ids[randi() % source_ids.size()]
	var orientation = ORIENTATIONS[randi() % ORIENTATIONS.size()]
	set_cell(cell, source_id, Vector2i(0, 0), orientation)
