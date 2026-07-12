extends Control

## Equip UI panel (spec §3/§7.3): 4 fixed slots, vertical column, top-right,
## always visible. Order top to bottom: Head, Torso, Backpack, Hand.
## Redraws icons whenever EquipmentManager reports a change - this script
## owns no equip state itself, just reflects it.

const SLOT_ORDER := [
	BaseItem.EquipSlot.HEAD,
	BaseItem.EquipSlot.TORSO,
	BaseItem.EquipSlot.BACKPACK,
	BaseItem.EquipSlot.HAND,
]

@onready var _icons: Dictionary = {
	BaseItem.EquipSlot.HEAD: $VBoxContainer/HeadSlot/Icon,
	BaseItem.EquipSlot.TORSO: $VBoxContainer/TorsoSlot/Icon,
	BaseItem.EquipSlot.BACKPACK: $VBoxContainer/BackpackSlot/Icon,
	BaseItem.EquipSlot.HAND: $VBoxContainer/HandSlot/Icon,
}

@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var _cursor: TextureRect = $Selector


func _ready() -> void:
	EquipmentManager.equipment_changed.connect(_on_equipment_changed)
	for slot in SLOT_ORDER:
		_refresh_slot(slot)


## Cursor navigation API used by inventorySprite.gd (spec §4) - this script
## owns its own cursor visual so callers never need to know EquipUI's
## internal node layout.

## index is 0..3, matching SLOT_ORDER's top-to-bottom order (Head/Torso/
## Backpack/Hand) - same convention the row cursor uses for its slots.
##
## Matches the inventory row cursor's own technique exactly (see
## inventorySprite.gd's "cursor" node): stay at the texture's native size and
## scale the whole node down to fit, rather than fighting Control's
## size/expand_mode/stretch_mode - the size-based approach doesn't hold
## because TextureRect keeps recomputing its rect from the texture's native
## size, which is what made the cursor render oversized outside the slot.
func set_cursor_index(index: int) -> void:
	if index < 0 or index >= SLOT_ORDER.size():
		return
	var slot_node: Control = _vbox.get_child(index)
	var texture_size: Vector2 = _cursor.texture.get_size()
	_cursor.scale = slot_node.size / texture_size
	_cursor.position = slot_node.position


func set_cursor_visible(should_show: bool) -> void:
	_cursor.visible = should_show


## Which BaseItem.EquipSlot a column index (0..3) refers to - lets callers
## (the contextual action menu) work in the same index space as
## set_cursor_index() without duplicating SLOT_ORDER themselves.
func get_slot_at_index(index: int) -> BaseItem.EquipSlot:
	return SLOT_ORDER[index]


## Global screen position of the column cursor, for positioning the
## contextual action menu above whichever equip slot is focused.
func get_cursor_global_position() -> Vector2:
	return _cursor.global_position


func _on_equipment_changed(slot: BaseItem.EquipSlot, _item: Resource) -> void:
	_refresh_slot(slot)


func _refresh_slot(slot: BaseItem.EquipSlot) -> void:
	var icon: TextureRect = _icons.get(slot)
	if icon == null:
		return
	var equipped: Resource = EquipmentManager.get_equipped(slot)
	icon.texture = equipped.item_texture if equipped != null else null
