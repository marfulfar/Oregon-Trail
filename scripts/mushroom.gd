extends StaticBody2D


@onready var picking_animation = $AnimatedSprite2D
@onready var sprite = $mushroom_sprite
@onready var player
var edible = true
@export var item_resource : Resource
var in_range = false


func _ready():
	item_resource = load("res://resources/red_mushroom.tres")
	player = get_tree().get_first_node_in_group("player")
	#print(player.inventory_list["test"]) Debug purposes



func _on_area_2d_body_entered(body):
		if body.name == "character":
			in_range = true


func _input(event):
	if in_range && Input.is_action_pressed("collect") && not WorldInputGate.is_blocked():
		if player.can_fit_anywhere(item_resource, item_resource.item_qty_per_item):
			picking_animation.play("collect_smoke")
		else:
			print("Inventory full")


func _on_area_2d_body_exited(body):
	in_range = false


func _on_animated_sprite_2d_animation_finished():
		player.update_inventory(item_resource, item_resource.item_qty_per_item)
		queue_free()

func get_texture():
	return sprite.texture
	
	
	
func eat():
	player.hunger += 5
	
