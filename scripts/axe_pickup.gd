extends StaticBody2D

## World pickup for a ToolItem (e.g. axe.tres). Auto-equip rule (see
## inventory_equip_system_spec.md §5): if HAND is empty, equip directly;
## else try to add to inventory; else drop it on the ground - reuses the
## same "fit or drop" helper the rest of the equip system shares.

@onready var label = $Label
@export var resource: ToolItem


func _ready():
	if resource == null:
		resource = load("res://resources/axe.tres")
	label.visible = false


func _on_area_2d_body_entered(body):
	if body.name == "character":
		label.visible = true


func _on_area_2d_body_exited(body):
	label.visible = false


## Uses just_pressed (not is_action_pressed's continuous held-state) so one
## button press can only trigger this once - a held/repeated press firing
## _input() more than once before queue_free() actually removes this node
## would otherwise add/drop extra copies of a non-stackable item.
##
## set_input_as_handled() consumes the event once processed, matching
## backpack_pickup.gd - Godot calls _input() on every node that overrides
## it, not just one, so two pickups overlapping in range could otherwise
## both react to the same single press.
func _input(event):
	if not (label.visible and Input.is_action_just_pressed("collect") and not WorldInputGate.is_blocked()):
		return

	if EquipmentManager.get_equipped(BaseItem.EquipSlot.HAND) == null:
		EquipmentManager.equip(resource, BaseItem.EquipSlot.HAND)
	else:
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			InventoryUtils.add_or_drop(player.inventory, resource, 1)
	get_viewport().set_input_as_handled()
	queue_free()
