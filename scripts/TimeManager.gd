extends Node


signal time_changed(time_of_day)

@export var day_length = 480.0 # 8 minutes in seconds
#day goes from 0 to 0.1
@export var minutes_per_signal = 0.02
var time_of_day = 0.0
var days = 0
var previous_time = 0.0
var last_signal_time = 0.0

func _process(delta):
	previous_time = time_of_day
	time_of_day = fmod(time_of_day + delta / day_length, 1.0)
	
	if time_of_day < previous_time:
		days += 1
		#print("New Day! Day:", days)

	if abs(time_of_day - last_signal_time) >= minutes_per_signal:
		emit_signal("time_changed", time_of_day)
		last_signal_time = time_of_day
	
	#print(time_of_day)
