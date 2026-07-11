extends StaticBody2D


@onready var stump = $stump
@onready var tree = $Sprite2D
@onready var label = $Label
@onready var tree_chopped = false
@onready var collect_anim = $smoke
@onready var stump_collision = $stump_box
var tree_life = 100
const log_scene = preload("res://scenes/log.tscn")
@onready var sound = $AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready():
	stump.visible = false
	label.visible = false
	collect_anim.visible=false

	var character_size = tree.get_rect().size
	print(character_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	if body.name == "character" && tree_chopped==false:
		label.visible = true
	

func _input(event):
	if Input.is_action_pressed("collect") && label.visible == true && tree_chopped == false:
		collect_anim.visible=true
		sound.play()
		collect_anim.play("collect_smoke")
		tree_life -=25


func _on_area_2d_body_exited(body):
	label.visible = false


func _on_animated_sprite_2d_animation_finished():
	if tree_life <= 0:
		tree_chopped = true
		label.visible=false
		tree.visible = false
		stump.visible=true
		stump_collision.scale = Vector2(0.75,0.5)
		
		for i in 3: #drop 3 logs
			var log_instance = log_scene.instantiate()
			# Generate random x and y offsets within the specified ranges
			var random_x = randf_range(-130, 130)
			var random_y = randf_range(-70, 50)
			# Apply the offsets to the tree's global position
			log_instance.position = Vector2(random_x,random_y)
			log_instance.scale = Vector2(1.5,1.5) # Rescale the log
			add_child(log_instance)
	
		
		#var instance2 = log_scene.instantiate()
		#instance2.position = Vector2(15,10)
		#var log_sprite = instance2.get_node("log_sprite")
		#log_sprite.flip_h = true
		#instance2.scale = scale/3
		#add_child(instance2)
		#
		#var instance3 = log_scene.instantiate()
		#instance3.position = Vector2(100,-30)
		#instance3.scale = scale/3
		#add_child(instance3)
