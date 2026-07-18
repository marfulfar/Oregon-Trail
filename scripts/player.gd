extends CharacterBody2D


#Health depletion
@export var max_health = 100
var current_health
var health_depletion_rate = 0.0
@export var health_num_days_full_depletion = 5
#time manager
@onready var time_manager = %TimeManager
#Hunger depletion
@export var hunger = 100.0
@export var hunger_num_of_days_full_depletion = 2
var hunger_depletion_rate = 0.0 # Will be calculated based on day_length
var is_starving = false
#thirst depletion
@export var thirst = 100.0
var thirst_depletion_rate = 0.0 # Will be calculated based on day_length
@export var thirst_num_of_days_full_depletion = 3
var is_dehydrated = false
#movement
@export var speed = 800
var is_moving:bool = false
var dir:String = "left"
var facing:String = "side" # "side", "front" (facing camera) or "back" (facing away)
@onready var anim  = $AnimatedSprite2D
@onready var action_anim_player: AnimationPlayer = $AnimationPlayer
## Wraps hand (which chop_hand animates) - flipping this mirrors both the
## swing's position keys AND the tool icon's art in one go, since Node2D
## children inherit a negative parent scale. See hand.gd for the icon itself.
@onready var hand_flip: Node2D = $hand_flip
var is_action_playing = false

#inventory
## Base personal inventory size, before any backpack is equipped. Backpacks
## do NOT change this value (see BackpackItem) - they carry their own
## separate Inventory that gets displayed alongside this one while worn.
@export var base_inventory_capacity : int = 5
var inventory : Inventory

#signals
signal thirst_update()
signal hunger_update()
signal inventory_updated(inventory: Inventory)
signal health_update()
## Fired when world_tool_use is pressed and a tool is equipped in HAND - see
## hand.gd (plays the swing feedback on the hand-item icon) and gathering
## scripts like tree.gd (apply the actual gather effect if a matching target
## is in range).
signal tool_used(tool_type: ToolItem.ToolType)

func _ready():
	current_health = max_health
	inventory = Inventory.new(base_inventory_capacity)
	hunger_depletion_rate = 100.0 / (hunger_num_of_days_full_depletion * time_manager.day_length)
	thirst_depletion_rate = 100.0 / (thirst_num_of_days_full_depletion * time_manager.day_length)
	health_depletion_rate = 100.0 / (health_num_days_full_depletion * time_manager.day_length)
	action_anim_player.animation_finished.connect(_on_action_animation_finished)

# Hunger, Thirst and Health logic
func _process(delta):
	# Hunger logic
	hunger -= hunger_depletion_rate * delta
	hunger = max(hunger, 0.0) # Ensure hunger doesn't go below 0
	var rounded_hunger = round(hunger)# Eliminating decimals
	emit_signal("hunger_update",rounded_hunger) #destiny: hunger textureRect
	if hunger <= 0:
		is_starving = true
		
	# Thirst logic
	thirst -= thirst_depletion_rate * delta
	thirst = max(thirst, 0.0) # Ensure hunger doesn't go below 0
	var rounded_thirst = round(thirst) # Eliminating decimals
	emit_signal("thirst_update", rounded_thirst) # Destiny: thirst textureRect
	if thirst <= 0:
		is_dehydrated = true

	#Health logic
	if is_starving and is_dehydrated:
		current_health -= health_depletion_rate * 2 * delta
		current_health = clamp(current_health, 0, max_health) # Ensure health stays within bounds
		var rounded_health = round(current_health)# Eliminating decimals
		emit_signal("health_update", rounded_health)
	elif is_starving:
		current_health -= health_depletion_rate * delta
		current_health = clamp(current_health, 0, max_health) # Ensure health stays within bounds
		var rounded_health = round(current_health)# Eliminating decimals
		emit_signal("health_update", rounded_health)
	elif is_dehydrated:
		current_health -= health_depletion_rate * delta
		current_health = clamp(current_health, 0, max_health) # Ensure health stays within bounds
		var rounded_health = round(current_health)# Eliminating decimals
		emit_signal("health_update", rounded_health)
	if current_health <= 0:
		get_tree().quit()


# Walking directions input
func get_input():
	# Freeze movement while a tool-use animation is playing - all input
	# waits until chop_hand finishes (see _on_action_animation_finished).
	if is_action_playing:
		velocity = Vector2.ZERO
		is_moving = false
		return

	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized() #ignore stick push distance - always move at full speed once past the deadzone
	velocity = input_direction * speed #velocity comes from CharacterBody2D node

	is_moving = input_direction != Vector2.ZERO
	if is_moving:
		# Whichever axis dominates picks the animation: side view for mostly
		# horizontal movement, front/back for mostly vertical.
		if abs(input_direction.x) >= abs(input_direction.y):
			facing = "side"
			if abs(input_direction.x) > 0.1: #deadband so a near-vertical stick angle doesn't flicker the flip while circling
				dir = "left" if input_direction.x < 0 else "right"
		else:
			facing = "back" if input_direction.y < 0 else "front"




## World tool-use (Square/F): fires tool_used if a tool is equipped,
## regardless of whether anything is in range - listeners (hand.gd for the
## visual, gathering scripts for the actual effect) each decide their own
## reaction. No-op if HAND is empty.
##
## Square is shared with menu_use (spec §5) since they're the same physical
## button in different contexts - guarded via WorldInputGate so opening the
## inventory panel doesn't let one press fire both a world tool-swing AND a
## menu action simultaneously (the inventory panel deliberately doesn't
## pause the game, so without this guard world_tool_use would keep firing
## while it's open).
func _unhandled_input(event):
	if not event.is_action_pressed("world_tool_use"):
		return

	if WorldInputGate.is_blocked():
		return

	if is_action_playing:
		return

	var equipped_tool: ToolItem = EquipmentManager.get_equipped(BaseItem.EquipSlot.HAND)
	if equipped_tool != null:
		tool_used.emit(equipped_tool.tool_type)
		is_action_playing = true
		action_anim_player.play("chop_hand")


## Clears is_action_playing once chop_hand finishes so _physics_process
## resumes driving walk/idle on AnimatedSprite2D again.
func _on_action_animation_finished(anim_name: StringName) -> void:
	if anim_name == "chop_hand":
		is_action_playing = false


func _physics_process(delta):
	get_input()
	move_and_slide()
	# Setting animations and flipping character sprite - skipped while
	# chop_hand (or any future action animation) owns AnimatedSprite2D's
	# frame, otherwise this would stomp its frame every physics tick.
	if is_action_playing:
		return
	if is_moving == true:
		match facing:
			"side":
				anim.play("walk_side")
				var facing_left := dir == "left"
				anim.flip_h = facing_left
				hand_flip.scale.x = -1.0 if facing_left else 1.0
			"back":
				anim.play("walk_back")
				anim.flip_h = false
				hand_flip.scale.x = 1.0
			"front":
				anim.play("walk_front")
				anim.flip_h = false
				hand_flip.scale.x = 1.0
	elif is_moving == false:
		anim.play("new_idle")


# Inventory logic. Delegates all slot/stacking work to the Inventory class -
# player.gd just decides WHEN items get added/removed and applies the
# gameplay side-effects (eating) on top.

## True if qty of item_resource could be added right now, either to the
## player's own inventory or (if a backpack is equipped) its extra slots -
## matches update_inventory()'s own fallback order, so a pre-check (e.g. a
## gathering script gating its collect animation) never disagrees with what
## actually happens once the pickup completes.
func can_fit_anywhere(item_resource: Resource, qty: int) -> bool:
	if inventory.can_fit(item_resource, qty):
		return true
	var backpack_inventory: Inventory = EquipmentManager.get_backpack_inventory()
	return backpack_inventory != null and backpack_inventory.can_fit(item_resource, qty)


## Attempts to add qty of item_resource to the inventory, falling back to the
## equipped backpack's own slots if the base inventory is full - matches the
## combined-row UX (spec: base row + backpack shown as one continuous pool).
## Returns true if it fully fit and was added somewhere, false if there
## wasn't room anywhere (nothing is added in that case - gathering scripts
## should check can_fit_anywhere() before playing a "collected" animation or
## freeing the world object).
func update_inventory(item_resource: Resource, qty: int) -> bool:
	if inventory.can_fit(item_resource, qty):
		inventory.add_item(item_resource, qty)
		emit_signal("inventory_updated", inventory) # Destiny: inventory Sprite UI
		return true

	var backpack_inventory: Inventory = EquipmentManager.get_backpack_inventory()
	if backpack_inventory != null and backpack_inventory.can_fit(item_resource, qty):
		backpack_inventory.add_item(item_resource, qty)
		# backpack_inventory emits its own inventory_changed, which
		# inventorySprite.gd already listens to directly - no separate
		# inventory_updated emit needed for this branch.
		return true

	return false

## Removes qty of item_resource from the inventory (e.g. eating or dropping).
## Applies edible effects (hunger/thirst/health) if the item is edible.
## target_inventory defaults to the player's own inventory - pass a backpack's
## Inventory instead when removing an item stored in its extra slots (see
## inventorySprite.gd's combined row navigation). slot_index, when given
## (>= 0), removes from that exact slot instead of scanning for the first
## slot matching item_resource.item_id - matters once the same item can
## occupy more than one slot, so "the item under the cursor" and "the first
## matching stack" can differ.
func remove_item_inventory(item_resource: Resource, qty: int, target_inventory: Inventory = null, slot_index: int = -1) -> void:
	if target_inventory == null:
		target_inventory = inventory

	if item_resource == null:
		print("Error: Item not found in inventory.")
		return

	var removed: bool = target_inventory.remove_from_slot(slot_index, qty) if slot_index >= 0 \
		else target_inventory.remove_item(item_resource.item_id, qty)
	if not removed:
		print("Error: Trying to remove more items than available.")
		return

	if item_resource.item_edible:
		hunger = min(hunger + item_resource.food_value, 100)
		thirst = min(thirst + item_resource.thirst_value, 100)
		current_health = min(current_health + item_resource.health_value, max_health)

	# Only the player's own inventory has a UI listener wired to this signal -
	# a backpack's Inventory already emits its own inventory_changed directly
	# (see Inventory.gd), which inventorySprite.gd listens to separately.
	if target_inventory == inventory:
		emit_signal("inventory_updated", inventory)
