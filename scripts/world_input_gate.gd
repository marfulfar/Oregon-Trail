extends Node

## Central "is world input currently allowed" check. The inventory panel
## deliberately doesn't pause the game (spec §4), but its menu-context
## actions (menu_use/menu_drop/menu_equip) share physical buttons with
## world-context actions (collect/world_tool_use) - see spec §5's naming
## note. Without this, a single button press fires both a menu action AND
## whatever world interactable happens to be in range at the same time.
## Every world-interaction script (gathering pickups, tool pickups) guards
## its own collect/world_tool_use check with this instead of each
## independently querying the inventory UI.

func is_blocked() -> bool:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	return inventory_ui != null and inventory_ui.is_inventory_open
