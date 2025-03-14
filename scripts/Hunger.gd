extends TextureRect

@onready var stomach_label = $Label
@onready var sprite = $"."
var hunger_1to20  
var hunger_20to40 
var hunger_40to60 
var hunger_60to80 
var hunger_80to99 
var hunger_full 
var hunger_empty 

# Called when the node enters the scene tree for the first time.
func _ready():
	hunger_1to20 = preload("res://assets/sprites/Hunger Marker/1to20.png")
	hunger_20to40 = preload("res://assets/sprites/Hunger Marker/20to40.png")
	hunger_40to60 = preload("res://assets/sprites/Hunger Marker/40to60.png")
	hunger_60to80 = preload("res://assets/sprites/Hunger Marker/60to80.png")
	hunger_80to99 = preload("res://assets/sprites/Hunger Marker/80to99.png")
	hunger_full = preload("res://assets/sprites/Hunger Marker/full.png")
	hunger_empty = preload("res://assets/sprites/Hunger Marker/empty.png")
	
	
func _process(delta):
	pass



func _on_character_hunger_update(rounded_hunger):
	if rounded_hunger == 100:
		sprite.texture = hunger_full
	elif rounded_hunger<99 && rounded_hunger>=80:
		sprite.texture = hunger_80to99
	elif rounded_hunger<80 && rounded_hunger>=60:
		sprite.texture = hunger_60to80
	elif rounded_hunger<60 && rounded_hunger>=40:
		sprite.texture = hunger_40to60
	elif rounded_hunger<40 && rounded_hunger>=20:
		sprite.texture = hunger_20to40
	elif rounded_hunger<20 && rounded_hunger>=1:
		sprite.texture = hunger_1to20
	elif rounded_hunger == 0:
		sprite.texture = hunger_empty
	else:
		sprite.texture = hunger_full
		
	stomach_label.text = str(rounded_hunger)
