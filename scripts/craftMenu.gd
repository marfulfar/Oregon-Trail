extends PanelContainer


@onready var ing1 = $ColorRect/VBoxContainer/row1/HBoxContainer/ingredient1
@onready var ing2 = $ColorRect/VBoxContainer/row1/HBoxContainer/ingredient2
@onready var result = $ColorRect/VBoxContainer/row1/HBoxContainer/result

var recipes : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	# Example Usage (Assuming your JSON file is named "recipes.json" in the project root)
	recipes = load_recipes("res://crafting_recipes.json")
	populate_crafting_list(recipes)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Load the JSON file into a Dictionary
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


func populate_crafting_list(recipes):
	var vbox_container =  $TextureRect/VBoxContainer # Access the VBoxContainer
	# Clear existing children
	for child in vbox_container.get_children():
		child.queue_free()


	for i in range(recipes.size()): # Iterate using an index 'i'
		var recipe = recipes[i] # Get the recipe at index 'i'
		
		var textureBackground = TextureRect.new()
		vbox_container.add_child(textureBackground)
		textureBackground.texture = load("res://assets/sprites/UI/row_ui.png")
		
		var hbox = HBoxContainer.new()
		textureBackground.add_child(hbox)
		hbox.set_anchors_preset(PRESET_FULL_RECT)
		hbox.offset_bottom = -20
		hbox.offset_left = 20
		hbox.offset_right = -20
		hbox.offset_top = 20
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# Ingredient 1
		var ingredient1_texture = TextureRect.new()
		hbox.add_child(ingredient1_texture)
		ingredient1_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		ingredient1_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		#ingredient1_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var ingredient1_resource_path = recipe["ingredient1resourcepath"]
		var resource = load(ingredient1_resource_path)
		ingredient1_texture.texture = resource.item_texture

		# Plus Sign
		var plus_label = Label.new()
		plus_label.text = "+"
		hbox.add_child(plus_label)
		plus_label.add_theme_color_override("font_color",Color.BLACK)

		# Ingredient 2
		var ingredient2_texture = TextureRect.new()
		hbox.add_child(ingredient2_texture)
		ingredient2_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		ingredient2_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var ingredient2_resource_path = recipe["ingredient2resourcepath"]
		resource = load(ingredient2_resource_path)
		ingredient2_texture.texture = resource.item_texture

		# Result Sign
		var result_label = Label.new()
		result_label.text = "=>"
		result_label.add_theme_color_override("font_color",Color.BLACK)
		hbox.add_child(result_label)
		

		# Result
		var result_texture = TextureRect.new()
		hbox.add_child(result_texture)
		result_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		result_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var result_resource_path = recipe["resultresourcepath"]
		resource = load(result_resource_path)
		result_texture.texture = resource.item_texture
