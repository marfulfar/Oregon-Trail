class_name BaseItem
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

## True for structures (e.g. a firepit) that get placed in the world via a
## movable blueprint on craft, instead of going straight into the inventory.
## Uses item_scene_path as the scene to instance/preview.
@export var item_placeable : bool = false

## How many times this item can be used before it breaks/is consumed by wear.
## -1 = unlimited (default for almost everything). Only set a real number for
## items with limited durability or uses (e.g. a found rifle with limited shots,
## or tools that eventually wear out).
@export var item_max_uses : int = -1

enum EquipSlot { NONE, HAND, TORSO, HEAD, BACKPACK }
## Which equip slot this item goes into when equipped. Leave NONE for items
## that only ever live in the inventory (berries, logs, twigs, etc).
@export var equip_slot : EquipSlot = EquipSlot.NONE
