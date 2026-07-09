extends CharacterBody2D

@export var speed: float = 250.0
## How close the oxen gets to the player before it stops moving, so it
## doesn't keep pushing into the player once it catches up.
@export var stop_distance: float = 80.0
## Distance at which the oxen starts slowing down, rather than moving at full
## speed right up until it's almost touching the player. Prevents the
## "overshoots into the player, gets stuck colliding" issue at high speed.
@export var slow_down_distance: float = 200.0

@onready var sprite = $AnimatedSprite2D
@onready var wagon = $AnimatedSprite2D/wagon
@onready var label = $Label

var is_following: bool = false
var player_in_range: bool = false
var player: Node2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	label.hide()
	_update_label_text()


func _physics_process(delta: float) -> void:
	# Keeps the sprite from inheriting any rotation from move_and_slide().
	sprite.global_rotation = 0.0

	if is_following and player:
		var to_player = player.global_position - global_position
		var distance = to_player.length()

		if distance > stop_distance:
			# Scale speed down to 0 as distance goes from slow_down_distance
			# down to stop_distance, instead of moving at full speed right up
			# until it's almost touching the player. clamp() keeps this at
			# full speed while still far away, and never negative once inside
			# the slow-down zone.
			var speed_factor = clamp(
				(distance - stop_distance) / (slow_down_distance - stop_distance),
				0.0, 1.0
			)
			velocity = to_player.normalized() * speed * speed_factor
			sprite.play("new_oxen_walk")
			wagon.play("wagon_move")
			_face_direction(to_player.x)
		else:
			velocity = Vector2.ZERO
			sprite.play("new_oxen_idle")
			wagon.play("wagon_idle")
	else:
		velocity = Vector2.ZERO
		sprite.play("new_oxen_idle")
		wagon.play("wagon_idle")

	move_and_slide()


func _face_direction(x_direction: float) -> void:
	if x_direction > 0:
		sprite.flip_h = true
		wagon.flip_h = true
		wagon.position.x = -2000
	else:
		sprite.flip_h = false
		wagon.flip_h = false
		wagon.position.x = 2000


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("action"):
		is_following = !is_following
		_update_label_text()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_update_label_text()
		label.show()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		label.hide()


func _update_label_text() -> void:
	if is_following:
		label.text = "Press X to unfollow"
	else:
		label.text = "Press X to follow"
