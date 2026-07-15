extends TileMapLayer

@export var map_width: int = 60
@export var map_height: int = 60

@export var grass_source_ids: Array[int] = [2]
@export var yellow_grass_source_ids: Array[int] = [4]
@export var forest_source_ids: Array[int] = [3]

## Single-cell atlas sources for the boundary blend art (see
## TRANSITION_TRANSFORMS/CORNER_TRANSFORMS below for how these get rotated
## to face the neighbor they're blending into). Forest has two straight-edge
## variants, picked at random, purely for visual variety along long borders.
@export var grass_transition_source_id: int = 7
@export var forest_transition_source_ids: Array[int] = [8, 9]

## Each boundary (forest/green, yellow/green) gets a corner tile hosted on
## *each* side, so a diagonal-only touch rounds off on both cells instead of
## just one.
@export var forest_corner_source_id: int = 10 # forest cell, green notch
@export var green_forest_corner_source_id: int = 11 # green cell, forest notch
@export var green_yellow_corner_source_id: int = 12 # green cell, yellow notch
@export var yellow_corner_source_id: int = 13 # yellow cell, green notch

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

## Both straight-edge transition textures have their "special" color (yellow,
## or dark forest) on the west half and green on the east half at identity
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

## The 4 diagonal directions a corner tile's odd-one-out corner can face.
const CORNER_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

## Every neighbor offset (straight + diagonal) - used only for the yellow/
## forest exclusion repair pass, which must catch corner-only touches too.
const ALL_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

## Which corner of each corner texture is the odd-one-out at identity
## transform:
## - HM_forest_3corner128:      green notch, top-left (NW)
## - HM_greengrass_3corner128:  forest notch, top-left (NW)
## - HM_yellowgrass_1corner128: yellow notch, bottom-left (SW)
## - HM_yellowgrass_3corner128: green notch, top-left (NW)
const FOREST_CORNER_DEFAULT := Vector2i(-1, -1)
const GREEN_FOREST_CORNER_DEFAULT := Vector2i(-1, -1)
const GREEN_YELLOW_CORNER_DEFAULT := Vector2i(-1, 1)
const YELLOW_CORNER_DEFAULT := Vector2i(-1, -1)

func _ready() -> void:
	generate_terrain()


## Two passes: first decide every cell's biome from noise, then paint.
## Painting needs the whole biome map up front so a cell can look at its
## neighbors' *final* biomes when deciding whether it needs a transition or
## corner tile instead of a plain one.
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

	# Yellow grass must never touch forest, not even at a corner - the only
	# path between them is yellow -> [grass transition/corner] -> green ->
	# [forest transition/corner] -> forest. Demote any yellow cell caught
	# bordering forest (straight or diagonal) straight to green so the
	# painting pass below gives it a proper transition/corner tile on the
	# forest side instead.
	for cell in biomes.keys():
		if biomes[cell] != Biome.GRASS_YELLOW:
			continue
		for offset in ALL_OFFSETS:
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


func _paint_cell(cell: Vector2i, biomes: Dictionary) -> void:
	var biome: Biome = biomes[cell]

	if biome == Biome.FOREST:
		_paint_forest_cell(cell, biomes)
		return

	if biome == Biome.GRASS_YELLOW:
		_paint_yellow_cell(cell, biomes)
		return

	_paint_grass_cell(cell, biomes)


## Forest cells only ever need the corner treatment (the straight edge
## between forest and green grass is handled entirely from the grass side,
## see _paint_grass_cell) - and only when this forest cell has no straight
## green neighbor of its own, so it isn't already sitting right at a
## straight border.
func _paint_forest_cell(cell: Vector2i, biomes: Dictionary) -> void:
	if _find_neighbor_direction(cell, biomes, NEIGHBOR_OFFSETS, Biome.GRASS_GREEN) == Vector2i.ZERO:
		var corner_dir := _find_neighbor_direction(cell, biomes, CORNER_OFFSETS, Biome.GRASS_GREEN)
		if corner_dir != Vector2i.ZERO:
			var transform := _corner_transform(FOREST_CORNER_DEFAULT, corner_dir)
			set_cell(cell, forest_corner_source_id, Vector2i(0, 0), transform)
			return

	_set_random_tile(cell, forest_source_ids)


## Yellow cells only ever need the corner treatment (same reasoning as
## forest above - the straight edge is entirely owned by the grass side).
func _paint_yellow_cell(cell: Vector2i, biomes: Dictionary) -> void:
	if _find_neighbor_direction(cell, biomes, NEIGHBOR_OFFSETS, Biome.GRASS_GREEN) == Vector2i.ZERO:
		var corner_dir := _find_neighbor_direction(cell, biomes, CORNER_OFFSETS, Biome.GRASS_GREEN)
		if corner_dir != Vector2i.ZERO:
			var transform := _corner_transform(YELLOW_CORNER_DEFAULT, corner_dir)
			set_cell(cell, yellow_corner_source_id, Vector2i(0, 0), transform)
			return

	_set_random_tile(cell, yellow_grass_source_ids)


## Green grass cells check straight neighbors first (yellow, then forest),
## then corner neighbors (yellow, then forest) for a diagonal-only touch,
## and finally fall back to a plain tile. Yellow takes priority over forest
## throughout, in the rare case a single green cell borders both.
func _paint_grass_cell(cell: Vector2i, biomes: Dictionary) -> void:
	var yellow_dir := _find_neighbor_direction(cell, biomes, NEIGHBOR_OFFSETS, Biome.GRASS_YELLOW)
	if yellow_dir != Vector2i.ZERO:
		set_cell(cell, grass_transition_source_id, Vector2i(0, 0), TRANSITION_TRANSFORMS[yellow_dir])
		return

	var forest_dir := _find_neighbor_direction(cell, biomes, NEIGHBOR_OFFSETS, Biome.FOREST)
	if forest_dir != Vector2i.ZERO:
		var source_id = forest_transition_source_ids[randi() % forest_transition_source_ids.size()]
		set_cell(cell, source_id, Vector2i(0, 0), TRANSITION_TRANSFORMS[forest_dir])
		return

	var yellow_corner_dir := _find_neighbor_direction(cell, biomes, CORNER_OFFSETS, Biome.GRASS_YELLOW)
	if yellow_corner_dir != Vector2i.ZERO:
		var transform := _corner_transform(GREEN_YELLOW_CORNER_DEFAULT, yellow_corner_dir)
		set_cell(cell, green_yellow_corner_source_id, Vector2i(0, 0), transform)
		return

	var forest_corner_dir := _find_neighbor_direction(cell, biomes, CORNER_OFFSETS, Biome.FOREST)
	if forest_corner_dir != Vector2i.ZERO:
		var transform := _corner_transform(GREEN_FOREST_CORNER_DEFAULT, forest_corner_dir)
		set_cell(cell, green_forest_corner_source_id, Vector2i(0, 0), transform)
		return

	_set_random_tile(cell, grass_source_ids)


## Returns the offset to the first neighbor (checked among `offsets`)
## matching `target` biome, or Vector2i.ZERO if none border this cell.
func _find_neighbor_direction(cell: Vector2i, biomes: Dictionary, offsets: Array[Vector2i], target: Biome) -> Vector2i:
	for offset in offsets:
		if biomes.get(cell + offset, Biome.GRASS_GREEN) == target:
			return offset
	return Vector2i.ZERO


## A corner is fully described by the sign of its x/y offset, and FLIP_H/
## FLIP_V independently negate exactly one of those signs - so, unlike the
## straight edges, no TRANSPOSE is ever needed here to reach any of the 4
## corners from any starting corner.
func _corner_transform(default_corner: Vector2i, target_corner: Vector2i) -> int:
	var transform := 0
	if target_corner.x != default_corner.x:
		transform |= TileSetAtlasSource.TRANSFORM_FLIP_H
	if target_corner.y != default_corner.y:
		transform |= TileSetAtlasSource.TRANSFORM_FLIP_V
	return transform


func _set_random_tile(cell: Vector2i, source_ids: Array[int]) -> void:
	var source_id = source_ids[randi() % source_ids.size()]
	var orientation = ORIENTATIONS[randi() % ORIENTATIONS.size()]
	set_cell(cell, source_id, Vector2i(0, 0), orientation)
