class_name BackpackItem
extends "res://scripts/base_item.gd"

## How many slots this backpack's internal storage has.
@export var extra_slots : int = 8

## This specific backpack's own storage. Each physical backpack (crafted or
## found) is its own duplicated Resource instance, so this is never shared
## across backpacks - contents travel with the instance across equip,
## unequip/drop, and re-pickup. Lazily created (rather than built in _init)
## so it always reflects extra_slots as actually loaded from the .tres file,
## not the script's default value.
var inventory : Inventory

func get_inventory() -> Inventory:
	if inventory == null:
		inventory = Inventory.new(extra_slots)
	return inventory


## See BaseItem.fresh_copy(). A shallow duplicate() alone isn't enough here:
## if the template this was copied from ever had its own inventory lazily
## created (e.g. someone equipped and used it directly), a shallow copy would
## still point at that exact same Inventory object, so two "different"
## backpacks would end up sharing one bag. Clearing inventory forces the
## fresh copy to lazily build its own, independent Inventory on first use.
func fresh_copy() -> BackpackItem:
	var copy: BackpackItem = duplicate(false)
	copy.inventory = null
	return copy
