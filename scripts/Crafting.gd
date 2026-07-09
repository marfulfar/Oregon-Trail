extends Control

@onready var is_open = false #MAIN MENU TOGGLE
@onready var tier : int = 1
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

#@onready var tier1_recipes = ["res://resources/Berries.tres","res://resources/firecamp.tres",
#"res://resources/Flint.tres","res://resources/grass.tres","res://resources/Log.tres",
#"res://resources/Red_mushroom.tres"]
@onready var tier1_recipes
@onready var tier2_recipes
@onready var tier3_recipes
@onready var tier4_recipes
@onready var tier5_recipes


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
	tier1_recipes = load_recipes("res://crafting_recipes.json")#WILL HAVE 5 JSON, 1 FOR EACH RECIPE TIER
	#HIDING EVERYTHING BY DEFAULT
	cursor.hide()
	side_panel.hide()
	detail_panel.hide()
	
	tier2_recipes = ["res://resources/Pinecone.tres","res://resources/Twigs.tres", 
	"res://resources/Red_mushroom.tres","res://resources/Red_mushroom.tres","res://resources/Red_mushroom.tres",
	"res://resources/Red_mushroom.tres"]
	
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
		update_detail_panel(tier)


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
		update_detail_panel(tier)

	if event.is_action_pressed("action") and is_open and side_panel.visible:
		match main_cursor_position:
			0:
				var resource = load(tier1_recipes[side_cursor_position])
			1:
				var resource = load(tier2_recipes[side_cursor_position])
			2:
				var resource = load(tier3_recipes[side_cursor_position])
			3:
				var resource = load(tier4_recipes[side_cursor_position])
			4:
				var resource = load(tier5_recipes[side_cursor_position])
				
	elif event.is_action_pressed("action") and is_open:
		side_panel.show()
		detail_panel.show()
		update_detail_panel(tier)
		cursor.position =  cursor_original_side_panel_pos
		side_panel.texture = load("res://assets/sprites/UI/side_panel"+String.num_int64(main_cursor_position+1)+".png")
		match main_cursor_position:
			0:
				#for i in range(0,recipes_textures.size()): #USE THIS WHEN JSON IS COMPLETE
				tier = 1
				for i in range(3):
					var recipe = tier1_recipes[i]
					var resource = load(recipe["resultresourcepath"])
					recipes_textures[i].texture  = resource.item_texture

			1: 
				tier = 2
				for i in range(0,recipes_textures.size()):
					var resource = load(tier2_recipes[i])
					recipes_textures[i].texture  = resource.item_texture
					
			#NEXT CURSOR POSITIONS WILL BE WRITTEN HERE: 2, 3 AND 4


	if event.is_action_pressed("back") and is_open and side_panel.visible:
		side_panel.hide()
		detail_panel.hide()
		cursor.position.y = 207
		cursor.position.x = side_panel_cursor_position_x[main_cursor_position]
		detail_panel.position = detail_panel_original_pos
		side_cursor_position = 0

func update_detail_panel(tier:int):
	match tier:
		1:
			var recipe = tier1_recipes[side_cursor_position]
			var resource = load(recipe["resultresourcepath"])
			detail_title.text = resource.item_name
			detail_description.text = resource.item_desc
			var ing1 = load(recipe["ingredient1resourcepath"])
			detail_ingredient1.texture = ing1.item_texture
			detail_ingredient1.EXPAND_FIT_WIDTH_PROPORTIONAL
			detail_ingredient1.STRETCH_KEEP_CENTERED
			var ing2 = load(recipe["ingredient2resourcepath"])
			detail_ingredient2.texture = ing2.item_texture
			detail_ingredient2.EXPAND_FIT_WIDTH_PROPORTIONAL
			detail_ingredient2.STRETCH_KEEP_CENTERED
			
			#THE OTHER 4 TIER WILL BE WRITTEN HERE

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
