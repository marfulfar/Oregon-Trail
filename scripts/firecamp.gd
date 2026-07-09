extends Node2D

@onready var fuel = 100
@onready var time_manager = %TimeManager
@onready var point_of_light = $PointLight2D


func _ready():
	time_manager.connect("time_changed",_on_time_manager_time_changed)

func _on_time_manager_time_changed(time_of_day):
	fuel -= 10
	point_of_light.energy -= 0.2
		
	if fuel == 0:
		queue_free()
