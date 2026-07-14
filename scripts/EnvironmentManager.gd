extends CanvasModulate

@onready var time_manager = %TimeManager
@onready var night_overlay = $"."

func _ready():
	if not time_manager:
		printerr("TimeManager not found!")


## Night is a plateau, not just a single instant at 0.0/1.0 - without
## unlit ground/trees to see by, the player should be effectively blind
## outside a light source's radius for the whole dusk-to-dawn stretch,
## not just a brief moment around midnight.
const DAWN_START = 0.2
const DAWN_END = 0.3
const DUSK_START = 0.7
const DUSK_END = 0.8
const NIGHT_COLOR = Color(0.01, 0.01, 0.02)
const DAY_COLOR = Color.WHITE

## Reads time_of_day directly every frame instead of TimeManager's
## throttled time_changed signal - the signal only fires every
## minutes_per_signal (~4.8s at current settings), which made the dusk/
## dawn fade visibly step between colors. Polling continuously makes the
## color track time_of_day's own continuous increase, so the fade is
## as smooth as the framerate.
func _process(_delta):
	if not time_manager:
		return
	var time_of_day: float = time_manager.time_of_day
	var adjusted_time: float
	if time_of_day < DAWN_START or time_of_day >= DUSK_END:
		adjusted_time = 1.0 # full night
	elif time_of_day < DAWN_END:
		adjusted_time = 1.0 - (time_of_day - DAWN_START) / (DAWN_END - DAWN_START)
	elif time_of_day < DUSK_START:
		adjusted_time = 0.0 # full day
	else:
		adjusted_time = (time_of_day - DUSK_START) / (DUSK_END - DUSK_START)

	night_overlay.color = DAY_COLOR.lerp(NIGHT_COLOR, adjusted_time)
