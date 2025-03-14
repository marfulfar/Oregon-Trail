extends Node

@onready var time_manager = null
@onready var directional_light = $DirectionalLight2D
@onready var night_overlay = $CanvasLayer/ColorRect

func _ready():
	time_manager = get_parent().get_node("TimeManager")
	if time_manager:
		time_manager.connect("time_changed",_on_time_manager_time_changed)
	else:
		printerr("TimeManager not found!")


func _on_time_manager_time_changed(time_of_day):
	# Update sun position (light rotation)
	var sun_angle = lerp(0, 360, time_of_day)
	directional_light.rotation = sun_angle
	
	#print(time_of_day)
	
	# Night overlay
	# Second argument of lerp needs to be float and also 1 = full dark, 0 = full light
	if time_of_day > 0.5: # Nighttime
		night_overlay.color.a = lerp(0.0, 0.75, (time_of_day - 0.5) * 2) # Fade in
		
	else: # Daytime
		night_overlay.color.a = lerp(0.75, 0.0, time_of_day * 2) # Fade out

	# You can add more environmental effects here
	# For example, changing the color of the sky, 
	# adjusting fog, or triggering weather events


