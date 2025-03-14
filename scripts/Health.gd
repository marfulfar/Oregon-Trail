extends TextureRect

@onready var player = %character
@onready var label = $Label4



# Called when the node enters the scene tree for the first time.
func _ready():
	if player:
		player.connect("health_update", _on_character_health_update)
	else:
		printerr("health_update signal not found!")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_character_health_update(current_health):
	label.text = str(current_health)
