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
var inventory_list = {}
@export var inventory_limit = 5
#signals
signal thirst_update()
signal hunger_update()
signal inventory_updated(inventory_list)
signal health_update()
#oxen following
@onready var follow_area = $Follow_area
@onready var action_label = $Label
@onready var oxen = $"../../oxen"

func _ready():
	current_health = max_health
	hunger_depletion_rate = 100.0 / (hunger_num_of_days_full_depletion * time_manager.day_length)
	thirst_depletion_rate = 100.0 / (thirst_num_of_days_full_depletion * time_manager.day_length)
	health_depletion_rate = 100.0 / (health_num_days_full_depletion * time_manager.day_length)
	
	action_label.hide()

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
		anim.play("walk")
		if dir == "left":
			anim.flip_h=true
		if dir == "right":
			anim.flip_h=false
	elif is_moving == false:
		anim.play("idle")


	if Input.is_action_just_pressed("action") and follow_area.get_overlapping_bodies().has(oxen):
		if oxen.is_following:
			oxen.stop_following()
		else:
			oxen.start_following()
		action_label.hide()
		
		
# Oxen logic - Follow and Unfollow
func _on_follow_area_body_entered(body):
	if body.name == "oxen":
		if oxen.is_following:
			action_label.text = "Press A to stop follow"
		else:
			action_label.text = "Press A to make follow"
		action_label.show()

func _on_follow_area_body_exited(body):
	if body.name == "oxen":
		action_label.hide()




		
#Inventory logic. Character has a dictionary that gets populated when picking objects
func update_inventory(item_resource, qty:int):
	if inventory_list.has(item_resource) and item_resource.item_stackable:
		inventory_list[item_resource]+=qty
	else:
		if inventory_list.size()<inventory_limit: # Inventory limit size 
			inventory_list[item_resource]=qty	
		else:
			print("inventory full") # Pending to handle. Probably a toast or bouncing animation like DST
			
	emit_signal("inventory_updated", inventory_list) # Destiny: inventory Sprite UI
		
func remove_item_inventory(item_resource, qty:int):
	if inventory_list.has(item_resource):
		var current_qty = inventory_list[item_resource]
		if current_qty > qty:
			inventory_list[item_resource] -= qty
			if item_resource.item_edible:
				hunger += item_resource.food_value
				thirst += item_resource.thirst_value
				current_health += item_resource.health_value
		elif current_qty == qty:
			inventory_list.erase(item_resource)
			if item_resource.item_edible:
				hunger += item_resource.food_value
				thirst += item_resource.thirst_value
				current_health += item_resource.health_value
		
		else:
			print("Error: Trying to remove more items than available.")
	else:
		print("Error: Item not found in inventory.")

	emit_signal("inventory_updated", inventory_list)
			
	
	

	
		
		
