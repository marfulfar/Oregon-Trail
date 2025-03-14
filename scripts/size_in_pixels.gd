extends Sprite2D


# Called when the node enters the scene tree for the first time.

func _ready():
	var scaled_size = get_rect().size
	print("Scaled tree sprite size: ", scaled_size)
