extends CharacterBody2D

var player
@export var speed = 100
@onready var sprite = $AnimatedSprite2D
@onready var wagon = $AnimatedSprite2D/wagon
var is_following = true
var body_exited = true
@onready var label = $Label



# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_node("character")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	sprite.global_rotation = 0.0
	if is_following:
		look_at(player.position)
		self.position += (Vector2
		(player.position.x - self.position.x, 
		player.position.y - self.position.y).normalized()) * speed * delta
		sprite.play("oxen_walk")
		wagon.play("wagon_move")
		
		if (player.position.x - self.position.x) > 0:
			sprite.flip_h = true
			wagon.flip_h = true
			wagon.position.x = -2000
		else:
			sprite.flip_h = false
			wagon.flip_h = false
			wagon.position.x = 2000
	else:
		sprite.play("oxen_idle")
		wagon.play("wagon_idle")
			
	move_and_slide()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if is_following == true:
			is_following = false
			body_exited = false
			
		if is_following == false && body_exited == true:
			label.visible = true
			label.text = "Press Action to make follow"
			
				
		
	

func _input(event):
	if event.is_action_pressed("action") && is_following == false:
		is_following = true


func _on_area_2d_body_exited(body):
	label.visible = false
	body_exited = true

