extends StaticBody2D


@onready var label = $Label
@onready var picking_animation = $AnimatedSprite2D
@onready var player
@export var resource : Resource



func _ready():
	resource = load("res://resources/Pinecone.tres")
	label.visible = false
	player = get_tree().get_first_node_in_group("player")
	

func _on_area_2d_body_entered(body):
		if body.name == "character":
			label.visible = true


func _input(event):
	if label.visible == true && Input.is_action_pressed("collect"):
		if player.inventory.can_fit(resource, resource.item_qty_per_item):
			picking_animation.play("collect_smoke")
		else:
			print("Inventory full")
		

func _on_area_2d_body_exited(body):
	label.visible = false


func _on_animated_sprite_2d_animation_finished():
		player.update_inventory(resource, resource.item_qty_per_item)
		queue_free()

	
