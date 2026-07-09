extends Control

@onready var is_open = false #MAIN MENU TOGGLE
@onready var side_panel = $SidePanel
@onready var detail_panel = $DetailPanel
@onready var detail_title = $DetailPanel/Title
@onready var detail_description = $DetailPanel/Description
@onready var detail_ingredient1 = $DetailPanel/Control/ing1
@onready var detail_ingredient2 = $DetailPanel/Control/ing2
@onready var cursor = $Cursor
@onready var main_cursor_position = 0
@onready var side_cursor_position = 0
@onready var cursor_original_side_panel_pos = Vector2(48,80)

@onready var side_panel_cursor_position_x = [50,133,217,300,383]
@onready var detail_panel_position_x = [0,88,175,250,340]
@onready var detail_panel_original_pos = Vector2(0,328)

@onready var recipes_textures = [$SidePanel/Recipe1,$SidePanel/Recipe2,$SidePanel/Recipe3,
$SidePanel/Recipe4,$SidePanel/Recipe5]

## Category order matches the side_panel1..5.png icons and the 5 cursor/detail
## slots above. Add a category here (and a matching side_panelN.png) to add a
## 6th tab - no other code change needed.
const CATEGORIES = ["REF", "TOL", "CAM", "WAG", "MED"]

## Set by station Area2Ds (schooner, campfire) when the player enters/exits
## range. Recipes whose required_station isn't "NONE" and doesn't match this
## are shown greyed-out and can't be crafted. No station Area2Ds exist yet -
## this is the hook for them.
var current_station: String = "NONE"

var recipes_by_category: Dictionary = {}


# Load the JSON file into an Array
func load_recipes(filepath: String) -> Array:
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		printerr("Error opening JSON file: ", filepath)
		return [] # Return an empty dictionary if file fails to load

	var json_string = file.get_as_text()
	file.close()

	var json_parsed = JSON.parse_string(json_string)
	if json_parsed == null:
		printerr("Error parsing JSON", "Error parsing JSON")
		return [] # Return an empty dictionary if parsing fails

	if json_parsed is Array:
		return json_parsed # Directly return the parsed array
	else:
		printerr("JSON is not an array of recipes.")
		return []


# Called when the node enters the scene tree for the first time.
func _ready():
	for recipe in load_recipes("res://crafting_recipes.json"):
		var category = recipe.get("category", "")
		if not recipes_by_category.has(category):
			recipes_by_category[category] = []
		recipes_by_category[category].append(recipe)

	#HIDING EVERYTHING BY DEFAULT
	cursor.hide()
	side_panel.hide()
	detail_panel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("crafting_menu"):
		if is_open == true:
			open_menu()
		else:
			close_menu()

	if event.is_action_pressed("menu_down") and is_open and !detail_panel.visible:
		#MAIN PANEL SCROLL DOWN
		if main_cursor_position >= 0 and main_cursor_position < 4:
			main_cursor_position += 1
		cursor.position.x = side_panel_cursor_position_x[main_cursor_position]

	if event.is_action_pressed("menu_down") and is_open and detail_panel.visible:
		#SIDE PANEL SCROLL DOWN
		cursor.position.y = 85
		if side_cursor_position >= 0 and side_cursor_position < 4:
			side_cursor_position += 1
		cursor.position.x = side_panel_cursor_position_x[side_cursor_position]
		detail_panel.position.x = detail_panel_position_x[side_cursor_position]
		update_detail_panel()


	if event.is_action_pressed("menu_up") and is_open and !detail_panel.visible:
		#MAIN PANEL SCROLL DOWN
		if main_cursor_position >= 1 and main_cursor_position < 5:
			main_cursor_position -= 1
		cursor.position.x = side_panel_cursor_position_x[main_cursor_position]
	elif event.is_action_pressed("menu_up") and is_open and detail_panel.visible:
		#SIDE PANEL SCROLL DOWN
		cursor.position.y = 85
		if side_cursor_position >= 1 and side_cursor_position < 5:
			side_cursor_position -= 1
		cursor.position.x = side_panel_cursor_position_x[side_cursor_position]
		detail_panel.position.x = detail_panel_position_x[side_cursor_position]
		update_detail_panel()

	if event.is_action_pressed("action") and is_open and side_panel.visible:
		var recipes = get_current_category_recipes()
		if side_cursor_position < recipes.size():
			var recipe = recipes[side_cursor_position]
			if is_recipe_available(recipe):
				craft_recipe(recipe)

	elif event.is_action_pressed("action") and is_open:
		side_panel.show()
		detail_panel.show()
		side_cursor_position = 0
		cursor.position = cursor_original_side_panel_pos
		side_panel.texture = load("res://assets/sprites/UI/side_panel"+String.num_int64(main_cursor_position+1)+".png")
		populate_recipe_icons()
		update_detail_panel()


	if event.is_action_pressed("back") and is_open and side_panel.visible:
		side_panel.hide()
		detail_panel.hide()
		cursor.position.y = 207
		cursor.position.x = side_panel_cursor_position_x[main_cursor_position]
		detail_panel.position = detail_panel_original_pos
		side_cursor_position = 0

## Recipes for whichever category tab the main cursor is on.
## NOTE: only the first 5 recipes of a category are shown - recipes_textures
## only has 5 slots (Recipe1..5). Several categories (TOL, CAM, WAG, MED) now
## have more than 5 recipes; a scrollable/paginated side panel is needed to
## surface the rest. Flagging rather than silently truncating.
func get_current_category_recipes() -> Array:
	return recipes_by_category.get(CATEGORIES[main_cursor_position], [])

func is_recipe_available(recipe: Dictionary) -> bool:
	var station = recipe.get("required_station", "NONE")
	return station == "NONE" or station == current_station

func populate_recipe_icons():
	var recipes = get_current_category_recipes()
	for i in range(recipes_textures.size()):
		if i < recipes.size():
			var recipe = recipes[i]
			var result_item = ItemDatabase.get_item(recipe["result"]["item_id"])
			recipes_textures[i].visible = true
			recipes_textures[i].texture = result_item.item_texture if result_item else null
			recipes_textures[i].modulate = Color(1, 1, 1, 1) if is_recipe_available(recipe) else Color(0.4, 0.4, 0.4, 1)
		else:
			recipes_textures[i].visible = false

func update_detail_panel():
	var recipes = get_current_category_recipes()
	if side_cursor_position >= recipes.size():
		return

	var recipe = recipes[side_cursor_position]
	var result_item = ItemDatabase.get_item(recipe["result"]["item_id"])
	if result_item:
		detail_title.text = result_item.item_name
		detail_description.text = result_item.item_desc

	var ingredients = recipe.get("ingredients", [])
	# NOTE: the detail panel scene only has 2 ingredient slots (ing1/ing2).
	# Recipes with a 3rd ingredient (e.g. Wooden Spear, Wagon Canvas Patch)
	# won't show it until a 3rd TextureRect is added to the scene.
	if ingredients.size() > 0:
		var ing1_item = ItemDatabase.get_item(ingredients[0]["item_id"])
		detail_ingredient1.texture = ing1_item.item_texture if ing1_item else null
		detail_ingredient1.EXPAND_FIT_WIDTH_PROPORTIONAL
		detail_ingredient1.STRETCH_KEEP_CENTERED
	if ingredients.size() > 1:
		var ing2_item = ItemDatabase.get_item(ingredients[1]["item_id"])
		detail_ingredient2.texture = ing2_item.item_texture if ing2_item else null
		detail_ingredient2.EXPAND_FIT_WIDTH_PROPORTIONAL
		detail_ingredient2.STRETCH_KEEP_CENTERED

## Crafting hook point. Inventory doesn't exist yet, so this doesn't consume
## ingredients or grant the result yet - it's here so the input handling
## above has somewhere real to call into once that's built.
func craft_recipe(recipe: Dictionary) -> void:
	print("Crafting: ", recipe.get("recipe_id", "?"))

func open_menu():
	cursor.hide()
	position.x = 200 #MAIN MENU SPRITE
	side_panel.hide()
	detail_panel.hide()
	main_cursor_position = 0
	side_cursor_position = 0
	cursor.position.x = 48
	cursor.position.y = 208
	side_panel.texture = load("res://assets/sprites/UI/side_panel.png")
	is_open = false

func close_menu():
	cursor.show()
	cursor.position.x = 48
	cursor.position.y = 208
	position.x = 304 #MAIN MENU SPRITE
	is_open = true
