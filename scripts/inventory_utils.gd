extends Node

## Shared "try to fit into inventory, else drop on the ground next to the
## player" behavior (the 3-tier priority used throughout the equip system).
## Used by: equip-column unequip, equip-slot displacement, and
## crafting_menu.gd's craft_recipe() ground-drop fallback - implemented once
## here instead of three times.


## Adds qty of item to inventory if it fits; otherwise spawns item's world
## scene next to the player instead. Returns true if it ended up in the
## inventory, false if it was dropped on the ground.
func add_or_drop(inventory: Inventory, item: Resource, qty: int) -> bool:
	if inventory.can_fit(item, qty):
		inventory.add_item(item, qty)
		return true

	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		spawn_in_world(item, player.global_position)
	return false


## Instantiates item's world scene (item_scene_path) at world_position, as a
## sibling of the player. If the scene's own script exposes a `resource`
## property (the convention flint.gd/log.gd/tree.gd use), it's set to this
## exact item instance AFTER add_child - this is what lets a dropped
## BackpackItem's contents (or any other per-instance item state) survive a
## drop/re-pickup instead of resetting to a fresh template. Returns the
## spawned node, or null if there was nothing to spawn into.
func spawn_in_world(item: Resource, world_position: Vector2) -> Node:
	if item.item_scene_path.is_empty():
		return null

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null

	var instance: Node = load(item.item_scene_path).instantiate()
	player.get_parent().add_child(instance)
	instance.global_position = world_position
	if "resource" in instance:
		instance.resource = item
	return instance
