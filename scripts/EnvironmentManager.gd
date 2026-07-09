extends CanvasModulate

@onready var time_manager = %TimeManager
@onready var night_overlay = $"."

func _ready():
	if time_manager:
		time_manager.connect("time_changed",_on_time_manager_time_changed)
	else:
		printerr("TimeManager not found!")


func _on_time_manager_time_changed(time_of_day):
	# time_of_day should be a value between 0.0 and 1.0, where 0.0 is midnight and 0.5 is midday.
	# We want to map this to a color between black and white.
	var black_color = Color(0.03, 0.03, 0.06)  # Fully black
	var white_color = Color.WHITE  # Fully white 
	# Adjust time_of_day to make midnight fully black and midday fully white.
	var adjusted_time = abs(time_of_day - 0.5) * 2.0
	# Lerp between black and white based on adjusted_time.
	var current_color = white_color.lerp(black_color, adjusted_time)
	# Apply the color to the night overlay.
	night_overlay.color = current_color
	
