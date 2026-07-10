extends Node2D

@onready var fuel = 100
@onready var time_manager = %TimeManager
@onready var point_of_light = $PointLight2D
@onready var craft_menu_label = $craft_menu_label


func _ready():
	time_manager.connect("time_changed",_on_time_manager_time_changed)
	craft_menu_label.hide()

func _on_time_manager_time_changed(time_of_day):
	fuel -= 10
	point_of_light.energy -= 0.2

	if fuel == 0:
		queue_free()


## Marks this campfire as a "FIRE" crafting station while the player is
## standing in crafting_area, so the crafting menu greys FIRE-gated recipes
## (e.g. mental_health_tea) in/out accordingly.
func _on_crafting_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		StationManager.enter("FIRE")
		craft_menu_label.show()


func _on_crafting_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		StationManager.exit("FIRE")
		craft_menu_label.hide()
