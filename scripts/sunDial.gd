extends Node

@onready var time_manager = %TimeManager
@onready var arrow = $arrow
@onready var days_label = $sun_moon/days_label

func _ready():
	# Connect to the TimeManager's time_changed signal
	if time_manager:
		time_manager.time_changed.connect(_on_time_changed)
	else:
		printerr("TimeManager not found!")


## time_of_day is 0..1 across a full day - lerp(90, 450, ...) sweeps the
## arrow exactly 360 degrees (450 = 90 + 360) starting from the editor's
## default pose (arrow.rotation is already 90 degrees in the scene), so
## there's no visible snap on the very first update.
func _on_time_changed(time_of_day):
	var arrow_rotation = lerp(90, 450, time_of_day)
	arrow.rotation_degrees = arrow_rotation
	days_label.text = "Days: " + str(time_manager.days)
