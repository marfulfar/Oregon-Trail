extends Node2D

@onready var fuel = 100
const MAX_FUEL = 100
const BASE_LIGHT_ENERGY = 2.0
## %TimeManager unique-name lookup only resolves for nodes present in the
## scene when it was saved - a campfire spawned at runtime as a placement
## blueprint has no such owner chain, so this uses the same group lookup the
## "player" group already relies on elsewhere instead.
@onready var time_manager = get_tree().get_first_node_in_group("TimeManager")
@onready var point_of_light = $PointLight2D
@onready var craft_menu_label = $craft_menu_label

## True while this campfire is a translucent, movable placement preview (see
## PlacementManager) rather than a real, working campfire - fuel doesn't
## drain and it doesn't register as a "FIRE" crafting station until this
## flips to false on placement confirm.
@export var is_blueprint: bool = false:
	set(value):
		is_blueprint = value
		modulate = Color(1, 1, 1, 0.5) if is_blueprint else Color(1, 1, 1, 1)


func _ready():
	time_manager.connect("time_changed",_on_time_manager_time_changed)
	craft_menu_label.hide()

## Fuel is spent in step with TimeManager's ticks so a full tank burns
## for roughly one full day/night cycle regardless of day_length or
## minutes_per_signal tuning - light energy tracks the remaining fuel
## fraction so it dims smoothly instead of stepping down in chunks.
func _on_time_manager_time_changed(time_of_day):
	if is_blueprint:
		return

	fuel -= 1
	point_of_light.energy = BASE_LIGHT_ENERGY * (float(fuel) / MAX_FUEL)

	if fuel <= 0:
		queue_free()


## Marks this campfire as a "FIRE" crafting station while the player is
## standing in crafting_area, so the crafting menu greys FIRE-gated recipes
## (e.g. mental_health_tea) in/out accordingly. No-ops while is_blueprint is
## true, so a placement preview never registers as a real station.
func _on_crafting_area_body_entered(body: Node2D) -> void:
	if is_blueprint or not body.is_in_group("player"):
		return
	StationManager.enter("FIRE")
	craft_menu_label.show()


func _on_crafting_area_body_exited(body: Node2D) -> void:
	if is_blueprint or not body.is_in_group("player"):
		return
	StationManager.exit("FIRE")
	craft_menu_label.hide()
