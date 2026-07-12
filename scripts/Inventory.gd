class_name Inventory
extends Resource

## Emitted whenever slot contents change, so UI can redraw.
signal inventory_changed()

@export var slots : Array[InventorySlot] = []
@export var capacity : int = 5

func _init(start_capacity : int = 5) -> void:
	capacity = start_capacity
	_resize_slots()

func _resize_slots() -> void:
	while slots.size() < capacity:
		slots.append(InventorySlot.new())
	while slots.size() > capacity:
		slots.pop_back()

## Grows or shrinks the inventory (e.g. equipping/unequipping a backpack
## upgrade, if you ever use that model elsewhere). Returns false if shrinking
## would discard occupied slots — caller should block the action in that case.
func set_capacity(new_capacity : int) -> bool:
	if new_capacity < capacity:
		for i in range(new_capacity, slots.size()):
			if not slots[i].is_empty():
				return false
	capacity = new_capacity
	_resize_slots()
	return true

## Returns true if `qty` of `item` could be added right now without actually
## adding it. Use this to enforce "can't pick up if full" before playing any
## collection animation.
func can_fit(item : Resource, qty : int) -> bool:
	var remaining = qty
	if item.item_stackable:
		for slot in slots:
			if not slot.is_empty() and slot.item.item_id == item.item_id:
				remaining -= item.item_stack_limit - slot.quantity
	if remaining <= 0:
		return true
	for slot in slots:
		if slot.is_empty():
			remaining -= item.item_stack_limit
			if remaining <= 0:
				return true
	return remaining <= 0

## Adds qty of item, filling existing stacks first, then empty slots.
## Returns the leftover quantity that did NOT fit (0 means fully added).
func add_item(item : Resource, qty : int) -> int:
	var remaining = qty

	if item.item_stackable:
		for slot in slots:
			if remaining <= 0:
				break
			if not slot.is_empty() and slot.item.item_id == item.item_id:
				var space = item.item_stack_limit - slot.quantity
				if space > 0:
					var amount_to_add = min(space, remaining)
					slot.quantity += amount_to_add
					remaining -= amount_to_add

	for slot in slots:
		if remaining <= 0:
			break
		if slot.is_empty():
			var amount_to_add = min(item.item_stack_limit, remaining)
			slot.item = item
			slot.quantity = amount_to_add
			remaining -= amount_to_add

	if remaining < qty:
		inventory_changed.emit()

	return remaining

## Removes qty of the item matching item_id. Returns false (and removes
## nothing) if there isn't enough total quantity across all slots.
func remove_item(item_id : String, qty : int) -> bool:
	if count_item(item_id) < qty:
		return false

	var remaining = qty
	for slot in slots:
		if remaining <= 0:
			break
		if not slot.is_empty() and slot.item.item_id == item_id:
			var amount_to_remove = min(slot.quantity, remaining)
			slot.quantity -= amount_to_remove
			remaining -= amount_to_remove
			if slot.quantity <= 0:
				slot.clear()

	inventory_changed.emit()
	return true

## Removes qty from a specific slot index directly, rather than scanning for
## the first slot matching an item_id (see remove_item()) - needed wherever
## the caller already knows exactly which slot the player has selected (e.g.
## the inventory cursor), since two stacks of the same item can sit in
## different slots and remove_item() would always deplete the leftmost one
## regardless of which the player is actually looking at.
func remove_from_slot(slot_index : int, qty : int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: InventorySlot = slots[slot_index]
	if slot.is_empty() or slot.quantity < qty:
		return false
	slot.quantity -= qty
	if slot.quantity <= 0:
		slot.clear()
	inventory_changed.emit()
	return true


func count_item(item_id : String) -> int:
	var total = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			total += slot.quantity
	return total

func has_item(item_id : String, qty : int = 1) -> bool:
	return count_item(item_id) >= qty
