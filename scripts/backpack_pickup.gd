extends StaticBody2D

## World pickup for a BackpackItem. Unlike flint.gd/log.gd, this calls
## EquipmentManager.equip_backpack() directly instead of adding to the
## inventory - backpacks are equip-only, never inventory items.
##
## `resource` is exported rather than hardcoded in _ready() because a
## *dropped* backpack must keep its own contents: InventoryUtils.spawn_in_world()
## sets this property (after instancing) to the exact BackpackItem instance
## that was equipped, not a fresh template.

@onready var label = $Label
@export var resource: BackpackItem


func _ready():
	if resource == null:
		resource = load("res://resources/leather_backpack.tres")
	label.visible = false


func _on_area_2d_body_entered(body):
	if body.name == "character":
		label.visible = true


func _on_area_2d_body_exited(body):
	label.visible = false


## Uses just_pressed (not is_action_pressed's continuous held-state) so one
## button press can only trigger this once. Held/repeated presses mattered
## here specifically: equip_backpack()'s swap-drop respawns the world
## instance at the player's own position, so a second held-state firing
## before queue_free() actually removes this node would immediately re-pick
## up the freshly-dropped replacement, unequip it again, respawn again... a
## self-sustaining loop for as long as the button stayed down.
##
## set_input_as_handled() consumes the event once processed - Godot calls
## _input() on every node that overrides it, not just one, so if a swap-drop
## ever puts a second backpack pickup in range at the same spot (the
## replacement spawns exactly at the player's position), a single press
## could otherwise also fire on that second node in the same dispatch and
## immediately trigger another swap.
func _input(event):
	if label.visible and Input.is_action_just_pressed("collect") and not WorldInputGate.is_blocked():
		EquipmentManager.equip_backpack(resource)
		get_viewport().set_input_as_handled()
		queue_free()
