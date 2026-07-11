extends StaticBody2D

@onready var character = null
var character_sprite = null
var being_held = false
var direction
@onready var tool_sprite = $Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("collect"):
		$AnimationPlayer.play("axe")
	if character:
		var character_sprite = character.get_node("AnimatedSprite2D") 
		if character_sprite:  
			if character_sprite.flip_h == true:
				var flipped = false
				tool_sprite.flip_h = flipped	
			else:
				tool_sprite.flip_h = true	
						
	
		
		

func _on_area_2d_body_entered(body):
	if body.name == "character":
		character = body
		var hand = body.get_node("hand")
		var sprite = body.get_node("AnimatedSprite2D")
		reparent(hand)
		position = Vector2(0,0)
		
						
		
	


	
