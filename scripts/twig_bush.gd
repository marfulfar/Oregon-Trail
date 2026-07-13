extends StaticBody2D

@export var life:int = 100
## Twig bushes yield more than a single loose twig pickup, so this is kept
## separate from resource.item_qty_per_item (which stays 1 for lone twigs).
@export var yield_quantity: int = 2
@onready var collect_smoke = $AnimatedSprite2D
@onready var twig_bush = $Sprite2D
var twigs_collected = false
var player
@export var resource : Resource
var in_range = false


func _ready():
	resource = load("res://resources/Twigs.tres")
	twig_bush.visible = true
	player = get_tree().get_first_node_in_group("player")
	collect_smoke.hide()


func _on_area_2d_body_entered(body):
	if body.name == "character":
		in_range = true


func _input(event):
	if in_range && Input.is_action_pressed("collect") && not WorldInputGate.is_blocked():
		if player.can_fit_anywhere(resource, yield_quantity):
			collect_smoke.show()
			collect_smoke.play("collect_smoke")
		else:
			print("Inventory full")


func _on_area_2d_body_exited(body):
	in_range = false


func _on_animated_sprite_2d_animation_finished():
	in_range = false
	collect_smoke.hide()
	twigs_collected = true
	twig_bush.visible = false
	player.update_inventory(resource, yield_quantity)
