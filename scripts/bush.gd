extends StaticBody2D

@export var life:int = 100
@onready var sound = $AudioStreamPlayer
@onready var label = $Label
@onready var collect_smoke = $AnimatedSprite2D
@onready var bush_no_berry = $bush_no_berry
@onready var bush = $Sprite2D
var berry_collected = false
var player
@export var resource : Resource


func _ready():
	resource = load("res://resources/Berries.tres")
	label.visible = false
	bush_no_berry.visible = false
	bush.visible = true
	player = get_tree().get_first_node_in_group("player")
	collect_smoke.hide()


func _on_area_2d_body_entered(body):
	if body.name == "character" && berry_collected == false:
		label.visible = true
	
	
func _input(event):
	if label.visible == true && Input.is_action_pressed("collect") && berry_collected == false && not WorldInputGate.is_blocked():
		if player.can_fit_anywhere(resource, resource.item_qty_per_item):
			collect_smoke.show()
			#sound.play()
			collect_smoke.play("collect_smoke")
		else:
			print("Inventory full")
	


func _on_area_2d_body_exited(body):
	label.visible = false


func _on_animated_sprite_2d_animation_finished():
	label.visible = false
	collect_smoke.hide()
	berry_collected = true
	bush_no_berry.visible = true
	bush.visible = false
	player.update_inventory(resource, resource.item_qty_per_item)
