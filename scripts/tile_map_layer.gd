extends TileMapLayer

@export var map_width: int = 60
@export var map_height: int = 60

## Indices into the ground TileSet's terrain_set 0 (see resources/ground_tileset.tres).
## Godot's own terrain autotiler picks and rotates whichever registered tile
## matches a cell's actual neighbors - straight edges, single-corner
## diagonal touches, everything - so this script only ever needs to say
## "these cells are forest/green/yellow", never which specific tile or
## rotation to use.
const TERRAIN_FOREST := 0
const TERRAIN_GREEN := 1
const TERRAIN_YELLOW := 2

@export var noise_frequency: float = 0.03
@export var noise_seed: int = 0

## Controls how big/frequent the yellow-grass patches are within the green
## grass biome. Higher frequency = smaller, more scattered patches, which
## means a tighter-curving boundary that leans on corner tiles far more
## than a straight edge - kept at or below noise_frequency so yellow
## patches read as calm blobs like the forest/green boundary does, not a
## "bubbly" speckle of little corners.
@export var yellow_patch_frequency: float = 0.025
@export var yellow_patch_threshold: float = 0.25

## Raw per-cell noise thresholding leaves behind small (1-8 cell) specks of
## the minority biome scattered inside a larger patch. Each pass has a cell
## adopt whichever biome is most common among its 8 neighbors, which erodes
## those stray specks while leaving genuine patch boundaries alone.
@export var biome_smoothing_passes: int = 4

var noise := FastNoiseLite.new()
var yellow_noise := FastNoiseLite.new()

enum Biome { FOREST, GRASS_GREEN, GRASS_YELLOW }

const BIOME_TO_TERRAIN := {
	Biome.FOREST: TERRAIN_FOREST,
	Biome.GRASS_GREEN: TERRAIN_GREEN,
	Biome.GRASS_YELLOW: TERRAIN_YELLOW,
}

## Every neighbor offset (straight + diagonal) - used for the yellow/forest
## exclusion repair pass, which must catch corner-only touches too.
const ALL_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

func _ready() -> void:
	generate_terrain()


## Decides every cell's biome from noise (smoothed, then repaired so yellow
## never touches forest), then hands the whole map to Godot's terrain
## autotiler one biome at a time.
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

	for i in range(biome_smoothing_passes):
		_smooth_biomes(biomes)

	# Yellow grass must never touch forest, not even at a corner - the only
	# path between them is yellow -> green -> forest. Demote any yellow cell
	# caught bordering forest (straight or diagonal) straight to green.
	for cell in biomes.keys():
		if biomes[cell] != Biome.GRASS_YELLOW:
			continue
		for offset in ALL_OFFSETS:
			if biomes.get(cell + offset, Biome.GRASS_GREEN) == Biome.FOREST:
				biomes[cell] = Biome.GRASS_GREEN
				break

	var cells_by_terrain: Dictionary = {TERRAIN_FOREST: [], TERRAIN_GREEN: [], TERRAIN_YELLOW: []}
	for cell in biomes.keys():
		var terrain: int = BIOME_TO_TERRAIN[biomes[cell]]
		cells_by_terrain[terrain].append(cell)

	# Order matters for terrain-connect: laying down green first gives forest
	# and yellow a fully-formed background to blend into on their own passes.
	set_cells_terrain_connect(cells_by_terrain[TERRAIN_GREEN], 0, TERRAIN_GREEN, false)
	set_cells_terrain_connect(cells_by_terrain[TERRAIN_FOREST], 0, TERRAIN_FOREST, false)
	set_cells_terrain_connect(cells_by_terrain[TERRAIN_YELLOW], 0, TERRAIN_YELLOW, false)


## One majority-vote pass over every cell: a cell flips to whichever biome
## is most common among its 8 neighbors, but only on a strict majority (ties
## keep the current biome) so this converges instead of oscillating forever.
## Reads and writes happen against a snapshot so every cell in this pass
## votes using the same "before" state.
func _smooth_biomes(biomes: Dictionary) -> void:
	var before := biomes.duplicate()
	for cell in before.keys():
		var counts: Dictionary = {}
		for offset in ALL_OFFSETS:
			var neighbor_biome = before.get(cell + offset, before[cell])
			counts[neighbor_biome] = counts.get(neighbor_biome, 0) + 1

		var current: Biome = before[cell]
		var best_biome: Biome = current
		var best_count: int = counts.get(current, 0)
		for candidate in counts.keys():
			if counts[candidate] > best_count:
				best_biome = candidate
				best_count = counts[candidate]

		biomes[cell] = best_biome


func _biome_at(cell: Vector2i) -> Biome:
	if noise.get_noise_2d(cell.x, cell.y) >= 0.1:
		return Biome.FOREST
	if yellow_noise.get_noise_2d(cell.x, cell.y) >= yellow_patch_threshold:
		return Biome.GRASS_YELLOW
	return Biome.GRASS_GREEN
