extends Resource

## Stable identifier used for inventory stacking, save data, and recipe
## references. Set manually per item, e.g. "berry", "axe_stone", "grass_bundle".
## Keep it lowercase_snake_case and unique across all items.
@export var item_id : String = ""

@export var item_name : String = ""
@export var item_texture : Texture2D
@export var item_desc : String = ""
@export var item_edible : bool = false
@export var item_stackable : bool = true
@export var item_stack_limit : int = 10
@export var item_ingredient : bool = false
@export var item_scene_path : String
@export var item_qty_per_item : int = 1

enum EquipSlot { NONE, HAND, TORSO, HEAD, BACKPACK }
## Which equip slot this item goes into when equipped. Leave NONE for items
## that only ever live in the inventory (berries, logs, twigs, etc).
@export var equip_slot : EquipSlot = EquipSlot.NONE
