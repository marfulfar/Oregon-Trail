extends Node

## Central lookup for every item Resource by item_id. Scans res://resources
## once at boot so nothing else in the game needs to hardcode a .tres path -
## recipes, inventory, loot tables, etc. all reference items by item_id only.

const ITEMS_DIR := "res://resources"

var _items: Dictionary = {}

func _ready() -> void:
	_index_directory(ITEMS_DIR)

func _index_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("ItemDatabase: could not open %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := path + "/" + file_name
			var resource: Resource = load(resource_path)
			if resource != null and "item_id" in resource and resource.item_id != "":
				if _items.has(resource.item_id):
					push_warning("ItemDatabase: duplicate item_id '%s' (%s and %s)" % [
						resource.item_id, _items[resource.item_id].resource_path, resource_path
					])
				_items[resource.item_id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()

## Returns the item Resource for item_id, or null (with a warning) if it
## isn't registered yet - e.g. the recipe references an item whose .tres
## hasn't been created.
func get_item(item_id: String) -> Resource:
	if not _items.has(item_id):
		push_warning("ItemDatabase: unknown item_id '%s'" % item_id)
		return null
	return _items[item_id]

func has_item(item_id: String) -> bool:
	return _items.has(item_id)
