extends Node

## TEMPORARY test harness for the equip system - delete this node and script
## once the real equip-column UI (Circle/equip, Triangle/unequip buttons)
## exists. Prints equipment changes to the log, and binds debug keys to
## exercise equip/unequip since there's no UI for it yet:
##   U - unequip_backpack() (always drops, contents intact)
##   I - equip axe.tres directly into HAND
##   P - unequip HAND (generic path: back to inventory if space, else drop)

func _ready() -> void:
	EquipmentManager.equipment_changed.connect(_on_equipment_changed)


func _on_equipment_changed(slot: BaseItem.EquipSlot, item: Resource) -> void:
	if item == null:
		print("[EquipmentManager] slot ", slot, " unequipped")
		return

	print("[EquipmentManager] slot ", slot, " -> ", item.item_name)
	if slot == BaseItem.EquipSlot.BACKPACK:
		var contents := EquipmentManager.get_backpack_inventory()
		var used := 0
		for slot_item in contents.slots:
			if not slot_item.is_empty():
				used += 1
		print("    backpack contents: ", used, "/", contents.capacity, " slots used")


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_unequip_backpack"):
		print("[debug] unequip_backpack() pressed")
		EquipmentManager.unequip_backpack()

	if Input.is_action_just_pressed("debug_equip_axe"):
		print("[debug] equip_axe() pressed")
		EquipmentManager.equip(load("res://resources/axe.tres"), BaseItem.EquipSlot.HAND)

	if Input.is_action_just_pressed("debug_unequip_hand"):
		print("[debug] unequip_hand() pressed")
		var item := EquipmentManager.unequip(BaseItem.EquipSlot.HAND)
		if item != null:
			var player := get_tree().get_first_node_in_group("player")
			var went_to_inventory: bool = InventoryUtils.add_or_drop(player.inventory, item, 1)
			print("    -> ", "returned to inventory" if went_to_inventory else "dropped on ground")
