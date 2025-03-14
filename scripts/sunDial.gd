extends Node

@onready var time_manager = %TimeManager
@onready var arrow = $arrow
@onready var days_label = $sun_moon/days_label

func _ready():
	# Connect to the TimeManager's time_changed signal
	if time_manager:
		time_manager.connect("time_changed",_on_time_changed)
	else:
		printerr("TimeManager 2 not found!")
		

func _on_time_changed(time_of_day):
	# Rotate the arrow based on the time of day
	#print(time_of_day)

	var arrow_rotation = lerp(90, 450, time_of_day)
	arrow.rotation_degrees = arrow_rotation
	days_label.text = "Days: " + str(time_manager.days)

	#print(arrow_rotation)
