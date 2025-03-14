extends TextureRect

@onready var hydration_label = $Label2
@onready var sprite = $"."

var thirst_empty;
var thirst_1to20;
var thirst_20to40
var thirst_40to60
var thirst_60to80
var thirst_80to99
var thirst_full


func _ready():		
	thirst_empty = load("res://assets/sprites/Thirst Marker/empty.png")
	thirst_1to20 = load("res://assets/sprites/Thirst Marker/1to20.png")
	thirst_20to40 = load("res://assets/sprites/Thirst Marker/20to40.png")
	thirst_40to60 = load("res://assets/sprites/Thirst Marker/40to60.png")
	thirst_60to80 = load("res://assets/sprites/Thirst Marker/60to80.png")
	thirst_80to99 = load("res://assets/sprites/Thirst Marker/80to99.png")
	thirst_full = load("res://assets/sprites/Thirst Marker/full.png")

func _process(delta):
	pass


func _input(event):
	pass


func _on_character_thirst_update(rounded_thirst):
	if rounded_thirst == 100:
		sprite.texture = thirst_full
	elif rounded_thirst<99 && rounded_thirst>=80:
		sprite.texture = thirst_80to99
	elif rounded_thirst<80 && rounded_thirst>=60:
		sprite.texture = thirst_60to80
	elif rounded_thirst<60 && rounded_thirst>=40:
		sprite.texture = thirst_40to60
	elif rounded_thirst<40 && rounded_thirst>=20:
		sprite.texture = thirst_20to40
	elif rounded_thirst<20 && rounded_thirst>=1:
		sprite.texture = thirst_1to20
	elif rounded_thirst == 0:
		sprite.texture = thirst_empty
	else:
		sprite.texture = thirst_full
	hydration_label.text = str(rounded_thirst)
