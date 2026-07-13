extends Node

## Autoload tracking which item currently occupies each equip slot, following
## the same dictionary + signal pattern as StationManager/PlacementManager.
## UI (equip column) and gameplay code (hand.gd, tool-use gating) listen to
## equipment_changed to stay in sync - nothing needs to poll this per frame.
##
## BACKPACK is handled separately from HEAD/TORSO/HAND (see equip_backpack()/
## unequip_backpack() below): a backpack carries its own independent
## Inventory (BackpackItem.get_inventory()) rather than merging extra slots
## into the player's own inventory, so it can never sit "in" the inventory
## row - only equipped or out in the world as its own pickup, contents
## intact either way. Equipping a new one while one is worn always drops the
## old one (with its contents) rather than trying to stash it anywhere.

signal equipment_changed(slot: BaseItem.EquipSlot, item: Resource)

var _equipped: Dictionary = {} # EquipSlot -> Resource


func get_equipped(slot: BaseItem.EquipSlot) -> Resource:
	return _equipped.get(slot)


## Puts item into slot. Does NOT displace a previous occupant - callers that
## need the "return to inventory, else drop" priority for whatever was there
## before should call get_equipped(slot) and hand it to
## InventoryUtils.add_or_drop() themselves before calling equip(). Not valid
## for BACKPACK - use equip_backpack() instead.
func equip(item: Resource, slot: BaseItem.EquipSlot) -> void:
	if slot == BaseItem.EquipSlot.BACKPACK:
		push_error("EquipmentManager.equip(): use equip_backpack() for BACKPACK")
		return
	_equipped[slot] = item
	equipment_changed.emit(slot, item)


## Clears slot and returns whatever was equipped there (null if already
## empty) so the caller can decide what to do with it (e.g.
## InventoryUtils.add_or_drop()). Not valid for BACKPACK - use
## unequip_backpack() instead.
func unequip(slot: BaseItem.EquipSlot) -> Resource:
	if slot == BaseItem.EquipSlot.BACKPACK:
		push_error("EquipmentManager.unequip(): use unequip_backpack() for BACKPACK")
		return null
	var item: Resource = _equipped.get(slot)
	if item == null:
		return null
	_equipped.erase(slot)
	equipment_changed.emit(slot, null)
	return item


## Contents of whichever backpack is currently equipped, or null if none.
func get_backpack_inventory() -> Inventory:
	var backpack: BackpackItem = _equipped.get(BaseItem.EquipSlot.BACKPACK)
	return backpack.get_inventory() if backpack != null else null


## Equips new_backpack. If a backpack is already worn, it's dropped into the
## world first, contents intact - backpacks always swap, never stack or wait
## in the inventory.
func equip_backpack(new_backpack: BackpackItem) -> void:
	## load() returns Godot's cached Resource singleton for a given path, so a
	## ground pickup can carry the exact same BackpackItem instance as the one
	## already worn (e.g. re-touching a dropped copy of your own backpack).
	## Without this check, unequip_backpack() below would pointlessly drop a
	## fresh world instance and immediately re-equip it - a new pickup Node
	## spawned on every single press for no actual state change.
	if _equipped.get(BaseItem.EquipSlot.BACKPACK) == new_backpack:
		return
	if _equipped.has(BaseItem.EquipSlot.BACKPACK):
		unequip_backpack()
	_equipped[BaseItem.EquipSlot.BACKPACK] = new_backpack
	equipment_changed.emit(BaseItem.EquipSlot.BACKPACK, new_backpack)


## Drops the currently equipped backpack into the world - contents travel
## with it, since it's the same Resource instance, not a fresh copy. No-op
## if nothing is equipped.
func unequip_backpack() -> void:
	var backpack: BackpackItem = _equipped.get(BaseItem.EquipSlot.BACKPACK)
	if backpack == null:
		return
	_equipped.erase(BaseItem.EquipSlot.BACKPACK)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		InventoryUtils.spawn_in_world(backpack, player.global_position)
	equipment_changed.emit(BaseItem.EquipSlot.BACKPACK, null)
