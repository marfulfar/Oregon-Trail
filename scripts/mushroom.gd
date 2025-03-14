extends StaticBody2D


@onready var label = $Label
@onready var picking_animation = $AnimatedSprite2D
@onready var sprite = $mushroom_sprite
@onready var player
var edible = true
@export var item_resource : Resource 


func _ready():
	item_resource = load("res://resources/red_mushroom.tres")
	label.visible = false
	player = get_tree().get_first_node_in_group("player")
	#print(player.inventory_list["test"]) Debug purposes
	
	

func _on_area_2d_body_entered(body):
		if body.name == "character":
			label.visible = true


func _input(event):
	if label.visible == true && Input.is_action_pressed("action"):
		picking_animation.play("collect_smoke")
		

func _on_area_2d_body_exited(body):
	label.visible = false


func _on_animated_sprite_2d_animation_finished():
		player.update_inventory(item_resource, item_resource.item_qty_per_item)
		queue_free()

func get_texture():
	return sprite.texture
	
	
	
func eat():
	player.hunger += 5
	
