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

## How many times this item can be used before it breaks/is consumed by wear.
## -1 = unlimited (default for almost everything). Only set a real number for
## items with limited durability or uses (e.g. a found rifle with limited shots,
## or tools that eventually wear out).
@export var item_max_uses : int = -1

enum EquipSlot { NONE, HAND, TORSO, HEAD, BACKPACK }
## Which equip slot this item goes into when equipped. Leave NONE for items
## that only ever live in the inventory (berries, logs, twigs, etc).
@export var equip_slot : EquipSlot = EquipSlot.NONE

## Returns an independent physical copy of this item, safe to hand to a
## player as a brand-new instance (crafted, or a world pickup's default
## load() fallback). load() returns Godot's cached Resource singleton for a
## given path, so without this every copy of an item ever crafted or found
## would otherwise be the exact same object - harmless for stateless items
## (flint, twigs, berries...) but a real bug for anything with per-instance
## mutable state. Overridden by item types that carry such state (see
## BackpackItem.fresh_copy()) - the base implementation just returns self,
## since sharing the template causes no harm for plain data-only items.
func fresh_copy() -> Resource:
	return self
