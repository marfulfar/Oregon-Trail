class_name BackpackItem
extends "res://scripts/base_item.gd"

## How many slots this backpack's internal storage has.
@export var extra_slots : int = 8

## This backpack instance's own storage. Lazily created (see get_inventory)
## rather than built in _init, so it always reflects extra_slots as actually
## loaded from the .tres file, not the script's default value.
var inventory : Inventory

func get_inventory() -> Inventory:
	if inventory == null:
		inventory = Inventory.new(extra_slots)
	return inventory
