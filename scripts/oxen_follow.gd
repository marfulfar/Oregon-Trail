extends CharacterBody2D

@export var follow_speed = 100.0
@export var follow_distance = 50.0
@onready var player = %character
@onready var is_following = false
@onready var sprite = $AnimatedSprite2D # Assuming your sprite is a Sprite2D node
@onready var wagon_sprite = $AnimatedSprite2D/wagon # Assuming your sprite is a Sprite2D node
@onready var wagon_crafting_menu = $"../HUD/WagonCraftMenu"
@onready var crafting_area = $AnimatedSprite2D/wagon/crafting_area/CollisionShape2D
@onready var craft_menu_label = $AnimatedSprite2D/craft_menu_label


func _ready():
	wagon_crafting_menu.hide()
	craft_menu_label.hide()
	
func _physics_process(delta):
	if is_following and player:
		var direction = (player.position - position).normalized()
		if position.distance_to(player.position) > follow_distance:
			velocity = direction * follow_speed
			sprite.play("oxen_walk")
			wagon_sprite.play("wagon_move")
			# Flip the sprite based on the direction
			if velocity.x > 0:
					sprite.flip_h = true # Facing right
					wagon_sprite.flip_h = true
					wagon_sprite.position.x = -1900
			elif velocity.x < 0:
					sprite.flip_h = false # Facing left
					wagon_sprite.flip_h = false
		else:
			velocity = Vector2.ZERO
			sprite.play("oxen_idle")
			wagon_sprite.play("wagon_idle")
	else:
			velocity = Vector2.ZERO
			sprite.play("oxen_idle")
			wagon_sprite.play("wagon_idle")
			
	move_and_slide()

func start_following():
		is_following = true

func stop_following():
		is_following = false


func _input(event):
	if craft_menu_label.visible == true and Input.is_action_pressed("action"):
		wagon_crafting_menu.show()

func _on_crafting_area_body_exited(body):
	if body.name == "character":
		wagon_crafting_menu.hide()
		craft_menu_label.hide()


func _on_crafting_area_body_entered(body):
	if body.name == "character":
		craft_menu_label.show()
		
