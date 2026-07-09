extends Node2D

@onready var ing1 = $HUD/ingredient1
@onready var ing2 = $HUD/HBoxContainer/ingredient2
@onready var result = $HUD/HBoxContainer/result



# Called when the node enters the scene tree for the first time.
func _ready():
	# Example Usage (Assuming your JSON file is named "recipes.json" in the project root)
	var recipes = load_recipes("res://crafting_recipes.json")
	print(recipes[0])
	var resource_path
	if recipes[0].has("resultresourcepath"):
		var recipe = recipes[0]
		resource_path = recipe["resultresourcepath"]
		print(resource_path)
	var resource = load(resource_path)
	var result_texture = resource.item_texture
	ing1.texture = result_texture
	

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
