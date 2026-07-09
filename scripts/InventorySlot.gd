class_name InventorySlot
extends Resource

## The item occupying this slot, or null if the slot is empty.
@export var item : Resource
@export var quantity : int = 0

func is_empty() -> bool:
	return item == null or quantity <= 0

func clear() -> void:
	item = null
	quantity = 0
