extends Control

@onready var world = $"../.."
@onready var player
# Holds the current Inventory resource, so input handling and drops can read from it directly.
var player_inventory : Inventory

#the 5 sprites slots in the inventory
@onready var slot1 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect1
@onready var slot2 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect2
@onready var slot3 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect3
@onready var slot4 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect4
@onready var slot5 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect5
@onready var inventory_slots = [slot1, slot2, slot3, slot4, slot5]
#the 5 labels for qty in the slots in the inventory
@onready var label1 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect1/Label1
@onready var label2 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect2/Label2
@onready var label3 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect3/Label3
@onready var label4 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect4/Label4
@onready var label5 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect5/Label5
@onready var inventory_labels = [label1, label2, label3, label4, label5]
#the game paused label
@onready var label_game_paused = $inventorySprite/pausedGame
#the action label
@onready var label_use_item = $inventorySprite/Container/cursor/Drop_label
@onready var label_drop_item = $inventorySprite/Container/cursor/Use_label


@export var scale_factor = 1.2 #the amount of scale of the inventory when opened
var original_scale
var is_inventory_open = false
@onready var inventory_sprite = $inventorySprite
@onready var selector: TextureRect = $inventorySprite/Container/cursor #the inventory cursor
@export var slot_count = 5 # Number of slots in the HBoxContainer - keep in sync with base_inventory_capacity on player
var selector_position = Vector2(0, 0)# the cursor initial position
var cursor_slot = 0


func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("inventory_updated", _on_character_inventory_updated) #Connecting from player node
	else:
		printerr("Player not found!")

	original_scale = scale
	selector.visible = false
	original_scale = inventory_sprite.scale
	label_game_paused.visible = false
	label_use_item.visible = false
	label_drop_item.visible = false

func _process(delta):
	if Input.is_action_just_pressed("menu"): #ESC in keyboard
		is_inventory_open = !is_inventory_open #Toggles the boolean

		if is_inventory_open:
			scale = original_scale * scale_factor #increase size of inventory by scale_factor
			selector.visible = true # cursor visible
			if _has_any_item():
				label_use_item.visible = true
				label_drop_item.visible = true
			update_selector_position()
			#get_tree().paused = true #Pauses the game (HUD not paused)
			#label_game_paused.visible = true
		else:
			scale = original_scale
			selector.visible = false
			label_use_item.visible = false
			label_drop_item.visible = false
			#get_tree().paused = false
			#label_game_paused.visible = false

	if is_inventory_open:
		if Input.is_action_just_pressed("menu_right"):
			#iterates from 1 to 5 to know in which slot cursor is in
			selector_position.x = min(selector_position.x + 1, slot_count - 1)
			cursor_slot = selector_position.x
			update_selector_position()
		if Input.is_action_just_pressed("menu_left"):
			selector_position.x = max(selector_position.x - 1, 0)
			cursor_slot = selector_position.x
			update_selector_position()

	if Input.is_action_just_pressed("action") and is_inventory_open:
		var slot = _get_slot(cursor_slot)
		if slot and not slot.is_empty() and slot.item.item_edible:
			player.remove_item_inventory(slot.item, 1)

	if Input.is_action_just_pressed("drop") and is_inventory_open:
		var slot = _get_slot(cursor_slot)
		if slot and not slot.is_empty():
			var selected_item = slot.item
			player.remove_item_inventory(selected_item, 1)
			var scene_path = selected_item.item_scene_path
			var instance = load(scene_path).instantiate()
			instance.position = world.to_local(player.global_position)
			world.add_child(instance)


func update_selector_position():
	selector.position.x = selector_position.x * 84 #84 is the Nº of pixels (in local position) between the (0.0) o slot 1 and the (0.0) of slot 2, aka (84.0)
	selector.position.y = 0 # Selector is always at the top of the HBoxContainer in the y dimension


func _on_character_inventory_updated(updated_inventory: Inventory): #connects from player
	player_inventory = updated_inventory
	populate_inventory(updated_inventory)


func populate_inventory(inv: Inventory):
	# Each slot in inv.slots maps 1:1 to a UI slot by index now, so there's no
	# need to track a separate slot_index counter like the old dictionary
	# version did - the array position IS the UI position, empty or not.
	for i in range(inventory_slots.size()):
		if i >= inv.slots.size():
			# Safety guard in case the UI has more visual slots than the
			# inventory's actual capacity (shouldn't normally happen).
			inventory_slots[i].texture = null
			inventory_labels[i].text = ""
			continue

		var slot = inv.slots[i]
		if slot.is_empty():
			inventory_slots[i].texture = null
			inventory_labels[i].text = ""
		else:
			inventory_slots[i].texture = slot.item.item_texture
			inventory_labels[i].text = "x" + String.num_int64(slot.quantity)


func _get_slot(index: int) -> InventorySlot:
	if player_inventory == null:
		return null
	if index < 0 or index >= player_inventory.slots.size():
		return null
	return player_inventory.slots[index]


func _has_any_item() -> bool:
	if player_inventory == null:
		return false
	for slot in player_inventory.slots:
		if not slot.is_empty():
			return true
	return false
