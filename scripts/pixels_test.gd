extends CharacterBody2D

@onready var character_sprite : Sprite2D = $Sprite2D
func _ready():
	var character_size = character_sprite.get_rect().size
	print(character_size)
