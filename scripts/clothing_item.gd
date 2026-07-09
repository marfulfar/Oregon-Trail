class_name Clothing_Item
extends "res://scripts/base_item.gd"

## Positive value = protection against cold. Used by the temperature system.
@export var warmth_value : float = 0.0

## Positive value = protection against damage. Optional to use at first.
@export var defense_value : float = 0.0
