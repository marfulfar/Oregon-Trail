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
@onready var anim  = $AnimatedSprite2D
@onready var position_2d = $position2D
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

func _ready():
	current_health = max_health
	inventory = Inventory.new(base_inventory_capacity)
	hunger_depletion_rate = 100.0 / (hunger_num_of_days_full_depletion * time_manager.day_length)
	thirst_depletion_rate = 100.0 / (thirst_num_of_days_full_depletion * time_manager.day_length)
	health_depletion_rate = 100.0 / (health_num_days_full_depletion * time_manager.day_length)

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
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed #velocity comes from CharacterBody2D node

	if Input.is_action_pressed("left"):
		is_moving=true
		dir="left"
	elif Input.is_action_pressed("right"):
		is_moving=true
		dir="right"
	elif Input.is_action_pressed("up"):
		is_moving=true
		dir="up"
	elif Input.is_action_pressed("down"):
		is_moving=true
		dir="down"
	else:
		velocity = Vector2.ZERO
		is_moving = false
	
	


func _physics_process(delta):
	get_input()
	move_and_slide()
	# Setting animations and flipping character sprite
	if is_moving == true:
		anim.play("new_walk")
		if dir == "left":
			anim.flip_h=true
		if dir == "right":
			anim.flip_h=false
	elif is_moving == false:
		anim.play("new_idle")


# Inventory logic. Delegates all slot/stacking work to the Inventory class -
# player.gd just decides WHEN items get added/removed and applies the
# gameplay side-effects (eating) on top.

## Attempts to add qty of item_resource to the inventory. Returns true if it
## fully fit and was added, false if there wasn't room (nothing is added in
## that case - gathering scripts should check this before playing a
## "collected" animation or freeing the world object).
func update_inventory(item_resource: Resource, qty: int) -> bool:
	if not inventory.can_fit(item_resource, qty):
		return false
	inventory.add_item(item_resource, qty)
	emit_signal("inventory_updated", inventory) # Destiny: inventory Sprite UI
	return true

## Removes qty of item_resource from the inventory (e.g. eating or dropping).
## Applies edible effects (hunger/thirst/health) if the item is edible.
func remove_item_inventory(item_resource: Resource, qty: int) -> void:
	if item_resource == null:
		print("Error: Item not found in inventory.")
		return

	if not inventory.remove_item(item_resource.item_id, qty):
		print("Error: Trying to remove more items than available.")
		return

	if item_resource.item_edible:
		hunger = min(hunger + item_resource.food_value, 100)
		thirst = min(thirst + item_resource.thirst_value, 100)
		current_health = min(current_health + item_resource.health_value, max_health)

	emit_signal("inventory_updated", inventory)
