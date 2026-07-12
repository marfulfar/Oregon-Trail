extends StaticBody2D

@onready var label = $Label
@onready var collect_smoke = $AnimatedSprite2D
@onready var bush = $Sprite2D
var player
@export var resource : Resource


func _ready():
	resource = load("res://resources/grass.tres")
	label.visible = false
	collect_smoke.hide()
	player = get_tree().get_first_node_in_group("player")


func _on_area_2d_body_entered(body):
	if body.name == "character":
		label.visible = true
	
	
func _input(event):
	if label.visible == true && Input.is_action_pressed("collect") && not WorldInputGate.is_blocked():
		if player.can_fit_anywhere(resource, resource.item_qty_per_item):
			collect_smoke.show()
			collect_smoke.play("collect_smoke")
		else:
			print("Inventory full")
	


func _on_area_2d_body_exited(body):
	label.visible = false


func _on_animated_sprite_2d_animation_finished():
	label.visible = false
	player.update_inventory(resource, resource.item_qty_per_item)
	queue_free()
