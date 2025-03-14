extends Node2D



func _ready():
		# Connect to the global time signal (you'll need to create this signal)
	#get_parent().get_node("TimeManager").connect("time_changed",_on_time_changed) # Assumes your root node emits the signal

#func _on_time_changed(time_of_day):
	pass
