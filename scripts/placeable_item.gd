class_name PlaceableItem
extends "res://scripts/base_item.gd"

## Crafted structures (e.g. a firepit) that get placed in the world via a
## movable blueprint on craft, instead of going straight into the inventory.
## Uses item_scene_path (inherited from BaseItem) as the scene to
## instance/preview. See PlacementManager and crafting_menu.gd's
## craft_recipe() for how the "is PlaceableItem" check drives this.
