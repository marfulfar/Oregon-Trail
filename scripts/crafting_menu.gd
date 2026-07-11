extends Control

## Left-docked crafting menu. Browses categories -> recipes -> ingredient
## detail, entirely driven by crafting_recipes.json and ItemDatabase. Adding
## a recipe or a whole new category only requires editing the JSON - this
## script never hardcodes a recipe list or a category count.
##
## Navigation reuses the same input actions as the rest of the game's menus
## (menu_up/menu_down/action/back), toggled open with crafting_menu.

const RECIPES_PATH := "res://crafting_recipes.json"

## Maps a recipe's short category code (from the JSON) to the label shown in
## the category list. A code that isn't listed here still works - it just
## falls back to showing the raw code - so adding a 6th category to the JSON
## never breaks the menu, it just looks a little less polished until this
## map is updated too.
const CATEGORY_LABELS := {
	"REF": "Refining",
	"TOL": "Tools",
	"CAM": "Camp",
	"WAG": "Wagon",
	"MED": "Medicine",
}

## Maps a recipe's required_station code (from the JSON) to the label shown
## in the "Requires: ..." hint. Separate from CATEGORY_LABELS because station
## codes and category codes are different vocabularies that only happen to
## overlap in spelling for "WAG" vs "SCHOONER" not matching - stations are
## physical world objects, categories are recipe groupings.
const STATION_LABELS := {
	"SCHOONER": "Wagon",
	"FIRE": "Campfire",
}

const COLOR_ROW_SELECTED := Color(0.30, 0.48, 0.78)
const COLOR_ROW_NORMAL := Color(0.16, 0.16, 0.19)
const COLOR_TEXT_AVAILABLE := Color(1, 1, 1)
const COLOR_TEXT_UNAVAILABLE := Color(0.55, 0.55, 0.55)
const COLOR_REQUIREMENT_TEXT := Color(0.9, 0.65, 0.25)

@onready var menu_panel: PanelContainer = $MenuPanel
@onready var category_list: VBoxContainer = $MenuPanel/Margin/Columns/CategoryColumn/CategoryList
@onready var recipe_column: VBoxContainer = $MenuPanel/Margin/Columns/RecipeColumn
@onready var recipe_scroll: ScrollContainer = $MenuPanel/Margin/Columns/RecipeColumn/RecipeScroll
@onready var recipe_list: VBoxContainer = $MenuPanel/Margin/Columns/RecipeColumn/RecipeScroll/RecipeList
@onready var detail_column: VBoxContainer = $MenuPanel/Margin/Columns/DetailColumn
@onready var result_icon: TextureRect = $MenuPanel/Margin/Columns/DetailColumn/ResultRow/ResultIcon
@onready var result_name: Label = $MenuPanel/Margin/Columns/DetailColumn/ResultRow/ResultInfo/ResultName
@onready var result_quantity: Label = $MenuPanel/Margin/Columns/DetailColumn/ResultRow/ResultInfo/ResultQuantity
@onready var result_description: Label = $MenuPanel/Margin/Columns/DetailColumn/ResultDescription
@onready var requirement_label: Label = $MenuPanel/Margin/Columns/DetailColumn/RequirementLabel
@onready var ingredients_list: VBoxContainer = $MenuPanel/Margin/Columns/DetailColumn/IngredientsList

## True while the menu overlay is visible and consuming navigation input.
var is_open: bool = false

## True once a category has been drilled into, i.e. the recipe list and
## detail panel are showing instead of just the category list.
var is_browsing_recipes: bool = false

## recipe_id -> category code. Populated once from the JSON in _ready().
var recipes_by_category: Dictionary = {}

## Category codes present in the JSON, sorted for a stable display order.
var category_order: Array = []

var selected_category_index: int = 0
var selected_recipe_index: int = 0

## Row Controls in on-screen order, kept so navigation can restyle the
## previously/newly selected row without rebuilding the whole list.
var category_rows: Array = []
var recipe_rows: Array = []


func _ready() -> void:
	_load_recipes()
	_build_category_list()
	hide()
	# The menu pauses the tree while open (see _toggle_menu), so it needs to
	# keep processing input itself to hear the close/craft presses that get
	# the game un-paused again.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("crafting_menu"):
		_toggle_menu()
		return

	if not is_open:
		return

	if event.is_action_pressed("back"):
		if is_browsing_recipes:
			_show_category_list()
		else:
			_toggle_menu()
	elif event.is_action_pressed("menu_down"):
		_move_selection(1)
	elif event.is_action_pressed("menu_up"):
		_move_selection(-1)
	elif event.is_action_pressed("action") and not is_browsing_recipes:
		_show_recipe_list()
	elif event.is_action_pressed("action") and is_browsing_recipes:
		_craft_selected_recipe()


## Opens or closes the whole menu, always resetting back to the top-level
## category list so it never reopens mid-way through a previous session.
func _toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	get_tree().paused = is_open
	if is_open:
		_show_category_list()


## Moves the cursor by `direction` (-1 or 1) within whichever list is
## currently active (categories, or the selected category's recipes).
func _move_selection(direction: int) -> void:
	if is_browsing_recipes:
		var recipes := get_current_category_recipes()
		if recipes.is_empty():
			return
		selected_recipe_index = clampi(selected_recipe_index + direction, 0, recipes.size() - 1)
		_refresh_recipe_row_styles()
		_update_detail_panel()
		recipe_scroll.ensure_control_visible(recipe_rows[selected_recipe_index])
	else:
		if category_order.is_empty():
			return
		selected_category_index = clampi(selected_category_index + direction, 0, category_order.size() - 1)
		_refresh_category_row_styles()


## Reads crafting_recipes.json and groups every recipe under its category
## code, so the rest of the script never touches the file again.
func _load_recipes() -> void:
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if file == null:
		push_error("CraftingMenu: could not open %s" % RECIPES_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Array):
		push_error("CraftingMenu: %s did not contain a JSON array" % RECIPES_PATH)
		return

	for recipe in parsed:
		var category: String = recipe.get("category", "")
		if not recipes_by_category.has(category):
			recipes_by_category[category] = []
			category_order.append(category)
		recipes_by_category[category].append(recipe)

	category_order.sort()


## Recipes belonging to whichever category is currently selected, or an
## empty array if nothing is selected yet.
func get_current_category_recipes() -> Array:
	if selected_category_index < 0 or selected_category_index >= category_order.size():
		return []
	return recipes_by_category.get(category_order[selected_category_index], [])


## True if the recipe's station requirement (if any) is currently met AND
## the player has enough of every ingredient in their inventory right now.
## Drives which recipe rows get greyed out, and whether craft_recipe() will
## actually succeed.
func is_recipe_available(recipe: Dictionary) -> bool:
	var station: String = recipe.get("required_station", "NONE")
	if station != "NONE" and not StationManager.is_near(station):
		return false

	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.inventory == null:
		return false

	var inventory: Inventory = player.inventory
	for ingredient in recipe.get("ingredients", []):
		if not inventory.has_item(ingredient["item_id"], ingredient["quantity"]):
			return false

	return true


## Builds the (static) list of category rows once. The list of categories
## doesn't change at runtime, so unlike the recipe list this never needs to
## be rebuilt after _ready().
func _build_category_list() -> void:
	for child in category_list.get_children():
		child.queue_free()
	category_rows.clear()

	for category_code in category_order:
		var label_text: String = CATEGORY_LABELS.get(category_code, category_code)
		var row := _create_row(null, label_text)
		category_list.add_child(row)
		category_rows.append(row)

	_refresh_category_row_styles()


## Rebuilds the recipe list for whichever category is currently selected.
## Called every time the player drills into a category, since each category
## has a different number of recipes.
func _populate_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	recipe_rows.clear()

	for recipe in get_current_category_recipes():
		var result_item := ItemDatabase.get_item(recipe.get("result", {}).get("item_id", ""))
		var icon: Texture2D = result_item.item_texture if result_item else null
		var display_name: String = result_item.item_name if result_item else recipe.get("result", {}).get("item_id", "?")

		var row := _create_row(icon, display_name)
		recipe_list.add_child(row)
		recipe_rows.append(row)

	_refresh_recipe_row_styles()


## Shows the top-level category list and hides the recipe/detail columns.
## Used both when first opening the menu and when backing out of a category.
func _show_category_list() -> void:
	is_browsing_recipes = false
	recipe_column.hide()
	detail_column.hide()
	_refresh_category_row_styles()


## Drills into the currently selected category: builds its recipe list and
## reveals the recipe/detail columns.
func _show_recipe_list() -> void:
	if get_current_category_recipes().is_empty():
		return

	is_browsing_recipes = true
	selected_recipe_index = 0
	recipe_column.show()
	detail_column.show()
	_populate_recipe_list()
	_update_detail_panel()


## Attempts to craft the currently selected recipe (bound to "action" while
## browsing a recipe list). Closes the menu on success, so the player can
## immediately see the item land in their inventory or watch a placement
## blueprint appear for a structure. Leaves the menu open on failure (e.g.
## a station requirement stopped being met) with nothing consumed.
func _craft_selected_recipe() -> void:
	var recipes := get_current_category_recipes()
	if selected_recipe_index < 0 or selected_recipe_index >= recipes.size():
		return

	var recipe: Dictionary = recipes[selected_recipe_index]
	if not is_recipe_available(recipe):
		return

	if craft_recipe(recipe):
		_toggle_menu()


## Highlights the selected category row and dims the rest. Categories are
## never greyed out for availability - only individual recipes are, since a
## whole category can mix craftable and station-gated recipes.
func _refresh_category_row_styles() -> void:
	for i in range(category_rows.size()):
		_style_row(category_rows[i], i == selected_category_index, true)


## Highlights the selected recipe row and dims unavailable ones (station
## requirement not currently met) regardless of selection.
func _refresh_recipe_row_styles() -> void:
	var recipes := get_current_category_recipes()
	for i in range(recipe_rows.size()):
		var available := is_recipe_available(recipes[i])
		_style_row(recipe_rows[i], i == selected_recipe_index, available)


## Fills in the detail column (result icon/name/quantity/description plus
## the full ingredients list) for whichever recipe is currently selected.
func _update_detail_panel() -> void:
	var recipes := get_current_category_recipes()
	if selected_recipe_index < 0 or selected_recipe_index >= recipes.size():
		return

	var recipe: Dictionary = recipes[selected_recipe_index]
	var result: Dictionary = recipe.get("result", {})
	var result_item := ItemDatabase.get_item(result.get("item_id", ""))

	result_icon.texture = result_item.item_texture if result_item else null
	result_name.text = result_item.item_name if result_item else result.get("item_id", "?")
	result_quantity.text = "Makes x%d" % result.get("quantity", 1)
	result_description.text = result_item.item_desc if result_item else ""

	var station: String = recipe.get("required_station", "NONE")
	if station == "NONE" or StationManager.is_near(station):
		requirement_label.text = ""
	else:
		requirement_label.text = "Requires: %s" % STATION_LABELS.get(station, station)

	for child in ingredients_list.get_children():
		child.queue_free()

	for ingredient in recipe.get("ingredients", []):
		var ingredient_item := ItemDatabase.get_item(ingredient.get("item_id", ""))
		var icon: Texture2D = ingredient_item.item_texture if ingredient_item else null
		var display_name: String = ingredient_item.item_name if ingredient_item else ingredient.get("item_id", "?")
		var row := _create_row(icon, "%s  x%d" % [display_name, ingredient.get("quantity", 1)])
		ingredients_list.add_child(row)


## Builds one list row: an optional icon plus a text label, wrapped in a
## PanelContainer so _style_row() can tint its background for selection.
func _create_row(icon_texture: Texture2D, label_text: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _make_row_stylebox(COLOR_ROW_NORMAL))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	if icon_texture:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	return row


## Tints a row's background for selection and its label's text color for
## availability. Kept as one shared helper so category rows (always
## "available") and recipe rows (greyed out when station-gated) look
## consistent.
func _style_row(row: PanelContainer, is_selected: bool, is_available: bool) -> void:
	row.add_theme_stylebox_override(
		"panel", _make_row_stylebox(COLOR_ROW_SELECTED if is_selected else COLOR_ROW_NORMAL)
	)

	var label := row.get_child(0).get_child(row.get_child(0).get_child_count() - 1) as Label
	if label:
		label.add_theme_color_override(
			"font_color", COLOR_TEXT_AVAILABLE if is_available else COLOR_TEXT_UNAVAILABLE
		)


func _make_row_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


## Attempts to craft `recipe` against the player's inventory: validates the
## required station and that every ingredient is available in sufficient
## quantity (via is_recipe_available), then consumes the ingredients and
## grants the result (or starts placement for a structure - see
## item_placeable below). Checks the result will actually fit BEFORE
## consuming anything, so a full inventory never destroys materials for
## nothing. Returns true if the craft succeeded.
func craft_recipe(recipe: Dictionary) -> bool:
	if not is_recipe_available(recipe):
		return false

	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.inventory == null:
		return false

	var inventory: Inventory = player.inventory
	var ingredients: Array = recipe.get("ingredients", [])

	var result: Dictionary = recipe.get("result", {})
	var result_item := ItemDatabase.get_item(result.get("item_id", ""))
	if result_item == null:
		return false

	if result_item.item_placeable:
		# Ingredients are left untouched here - placement only consumes them
		# on confirm (see PlacementManager), so there's nothing to refund if
		# the player cancels.
		PlacementManager.start_placement(result_item, recipe)
		return true

	if not inventory.can_fit(result_item, result.get("quantity", 1)):
		return false

	for ingredient in ingredients:
		inventory.remove_item(ingredient["item_id"], ingredient["quantity"])
	inventory.add_item(result_item, result.get("quantity", 1))

	player.emit_signal("inventory_updated", inventory)
	return true
