extends Node

## Autoload that drives placing a crafted "structure" item (e.g. a firepit)
## into the world as a movable blueprint that follows the player, then
## finalizes it in place on confirm. Triggered from crafting_menu.gd's
## craft_recipe() when the crafted result_item.item_placeable is true.
##
## Ingredients for a placement recipe are NOT consumed by craft_recipe() -
## they're only spent in _confirm() below, so cancel() never needs to
## refund anything (nothing was ever taken).

## Distance (px) the blueprint sits in front of the player, along whichever
## direction they're currently facing (player.dir).
@export var placement_offset: float = 100.0

var _blueprint: Node2D = null
var _recipe: Dictionary = {}
var _player: Node2D = null

## True for the one _process() frame right after start_placement() - the
## "action" press that confirmed the craft is still is_action_just_pressed()
## on that same frame, so without this it would be read a second time here
## as an instant placement confirm.
var _just_started: bool = false

const FACING_OFFSETS := {
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT,
	"up": Vector2.UP,
	"down": Vector2.DOWN,
}


## Starts placement mode for result_item (needs item_placeable = true and a
## valid item_scene_path). recipe is kept around so confirm knows which
## ingredients to consume.
func start_placement(result_item: Resource, recipe: Dictionary) -> void:
	if _blueprint != null:
		cancel()

	_player = get_tree().get_first_node_in_group("player")
	if _player == null or result_item.item_scene_path.is_empty():
		_player = null
		return

	var scene: PackedScene = load(result_item.item_scene_path)
	_blueprint = scene.instantiate()
	if "is_blueprint" in _blueprint:
		_blueprint.is_blueprint = true
	_blueprint.modulate = Color(1, 1, 1, 0.5)

	_recipe = recipe
	_just_started = true
	_player.get_parent().add_child(_blueprint)
	_update_blueprint_position()


func _process(_delta: float) -> void:
	if _blueprint == null:
		return

	_update_blueprint_position()

	if _just_started:
		_just_started = false
		return

	if Input.is_action_just_pressed("action"):
		_confirm()
	elif Input.is_action_just_pressed("back"):
		cancel()


func _update_blueprint_position() -> void:
	var facing: Vector2 = FACING_OFFSETS.get(_player.dir, Vector2.DOWN)
	_blueprint.global_position = _player.global_position + facing * placement_offset


## Re-checks ingredients (nothing was reserved while the blueprint was being
## moved around) and that the spot is clear, then consumes the ingredients
## and finalizes the blueprint in place.
func _confirm() -> void:
	var inventory: Inventory = _player.inventory
	var ingredients: Array = _recipe.get("ingredients", [])
	for ingredient in ingredients:
		if not inventory.has_item(ingredient["item_id"], ingredient["quantity"]):
			return

	if not _is_valid_placement():
		return

	for ingredient in ingredients:
		inventory.remove_item(ingredient["item_id"], ingredient["quantity"])
	_player.emit_signal("inventory_updated", inventory)

	if "is_blueprint" in _blueprint:
		_blueprint.is_blueprint = false

	_blueprint = null
	_recipe = {}
	_player = null


## True unless the blueprint scene defines its own "placement_blockers"
## Area2D and it's currently overlapping something other than its own body
## (placement_blockers is a child of the blueprint's root body, so it always
## picks up that root body's own CollisionShape2D as an "overlap").
func _is_valid_placement() -> bool:
	var blockers := _blueprint.get_node_or_null("placement_blockers")
	if blockers == null:
		return true
	for body in blockers.get_overlapping_bodies():
		if body != _blueprint:
			return false
	return true


## Cancels placement mode. Ingredients were never consumed, so there's
## nothing to refund - just discard the blueprint.
func cancel() -> void:
	if _blueprint != null:
		_blueprint.queue_free()
	_blueprint = null
	_recipe = {}
	_player = null
