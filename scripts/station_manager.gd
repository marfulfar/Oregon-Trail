extends Node

## Autoload that tracks which crafting stations (e.g. "SCHOONER", "FIRE") the
## player is currently standing near. Station trigger areas (see the wagon's
## crafting_area in oxen.gd and the campfire's crafting_area in firecamp.gd)
## call enter()/exit() when the player enters/exits their range. The crafting
## menu then asks is_near() to decide which recipes are currently craftable.
##
## A count per station (rather than a single "current station" string) means
## overlapping trigger zones - or a station with more than one trigger area -
## behave correctly: a station only stops counting as "nearby" once every
## trigger that reported it has also reported an exit.

var _nearby_station_counts: Dictionary = {}


## Call when the player enters a station's trigger area.
func enter(station_name: String) -> void:
	_nearby_station_counts[station_name] = _nearby_station_counts.get(station_name, 0) + 1


## Call when the player exits a station's trigger area.
func exit(station_name: String) -> void:
	if not _nearby_station_counts.has(station_name):
		return
	_nearby_station_counts[station_name] -= 1
	if _nearby_station_counts[station_name] <= 0:
		_nearby_station_counts.erase(station_name)


## True if the player is currently within range of the given station.
func is_near(station_name: String) -> bool:
	return _nearby_station_counts.has(station_name)
