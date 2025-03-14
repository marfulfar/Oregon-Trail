extends TextureRect

@onready var world = $"../.."
@onready var player
@onready var inventory : Array
#the 5 sprites slots in the inventory
@onready var slot1 = $MarginContainer/HBoxContainer/TextureRect1
@onready var slot2 = $MarginContainer/HBoxContainer/TextureRect2
@onready var slot3 = $MarginContainer/HBoxContainer/TextureRect3
@onready var slot4 = $MarginContainer/HBoxContainer/TextureRect4
@onready var slot5 = $MarginContainer/HBoxContainer/TextureRect5
@onready var inventory_slots = [slot1,slot2, slot3,slot4,slot5]
#the 5 labels for qty in the slots in the inventory
@onready var label1 = $MarginContainer/HBoxContainer/TextureRect1/Label1
@onready var label2 = $MarginContainer/HBoxContainer/TextureRect2/Label2
@onready var label3 = $MarginContainer/HBoxContainer/TextureRect3/Label3
@onready var label4 = $MarginContainer/HBoxContainer/TextureRect4/Label4
@onready var label5 = $MarginContainer/HBoxContainer/TextureRect5/Label5
@onready var inventory_labels = [label1,label2,label3,label4,label5]
#the game paused label
@onready var label_game_paused = $pausedGame
#the action label
@onready var label_use_item = $Container/cursor/Use_label
@onready var label_drop_item = $Container/cursor/Drop_label



@export var scale_factor = 1.2 #the amount of scale of the inventory when opened
var original_scale
var is_inventory_open = false
@onready var inventory_sprite = $"."
@onready var selector: TextureRect = $Container/cursor #the inventory cursor
@export var slot_count = 5 # Number of slots in the HBoxContainer
var selector_position = Vector2(0, 0)# the cursor initial position
var cursor_slot = 0


func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("inventory_updated",_on_character_inventory_updated) #Connecting from player node
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
			if !inventory.is_empty():
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
		if !inventory.is_empty():
			var selected_item = inventory[cursor_slot]
			if selected_item.item_edible:
				player.remove_item_inventory(selected_item,1)
			
	if Input.is_action_just_pressed("drop") and is_inventory_open:
		if !inventory.is_empty():
			var selected_item = inventory[cursor_slot]
			player.remove_item_inventory(selected_item,1)
			var scene_path = selected_item.item_scene_path
			var instance = load(scene_path).instantiate()
			#instance.position = player.position
			print(player.position)
			instance.position = world.to_local(player.global_position)
			world.add_child(instance)
			print(instance.position)
			
			
		
		
		

func update_selector_position():
	var slot_width = selector.size.x # Assuming all slots have the same width.
	selector.position.x = selector_position.x * 84 #84 is the Nº of pixels (in local position) between the (0.0) o slot 1 and the (0.0) of slot 2, aka (84.0)
	#print(selector.position.x) #debug
	selector.position.y = 0 # Selector is always at the top of the HBoxContainer in the y dimension
	

func _on_character_inventory_updated(inventory_list):#connects from player
	populate_inventory(inventory_list,inventory_slots)
		
		
func populate_inventory(inventory_list, inventory_slots: Array):
	inventory.clear()
	
	 # Clear the inventory slots' textures
	for slot in inventory_slots:
		slot.texture = null
	for label in inventory_labels:
		label.text = ""
	
	var slot_index = 0
	for item_resource in inventory_list.keys():
		inventory.insert(slot_index,item_resource)
		var quantity = inventory_list[item_resource]

		if slot_index < inventory_slots.size():
			var current_slot = inventory_slots[slot_index]
			var current_label = inventory_labels[slot_index]
			if current_slot != null:
				current_slot.texture = item_resource.item_texture
				current_label.text = "x" + String.num_int64(quantity) 
			slot_index += 1
		else:
			print("Inventory is full!")
			break
	







