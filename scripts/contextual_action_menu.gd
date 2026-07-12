extends Control

## Contextual action menu popup (spec §5): floats next to whichever slot has
## cursor focus (row or column), showing all 4 face-button prompts, greyed
## out per the current slot/item context. All 4 are always shown, never
## hidden - deliberately simple for v1 (see spec). X has no assigned action
## yet (reserved for a future swap mechanic) so it's permanently greyed.
##
## Vertical layout, top to bottom: Triangle/Drop, Square/Use, Circle/Equip,
## X/unassigned. Anchored above the slot when focus is on the horizontal
## inventory row, or to the left of the slot when focus is on the vertical
## equip column - avoids running off the right screen edge, which is where
## the equip column lives.

const COLOR_AVAILABLE := Color(1, 1, 1)
const COLOR_UNAVAILABLE := Color(0.55, 0.55, 0.55)

@onready var use_label: Label = $Panel/VBoxContainer/Use
@onready var drop_label: Label = $Panel/VBoxContainer/Drop
@onready var equip_label: Label = $Panel/VBoxContainer/Equip
@onready var unassigned_label: Label = $Panel/VBoxContainer/Unassigned
@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	hide()
	_set_available(unassigned_label, false) # X is always unavailable - reserved, unimplemented.


## Repositions relative to slot_global_position (the focused slot's own
## global_position) and refreshes each button's greyed-out state for the
## given context. anchor_above: true when the focused slot is in the
## horizontal inventory row (popup sits above it); false when it's in the
## vertical equip column (popup sits to its left). Called every frame the
## panel is open (see inventorySprite.gd's _refresh_context_menu()), so it's
## always in sync with wherever the cursor currently is.
func show_for_slot(slot_global_position: Vector2, anchor_above: bool, can_use: bool, can_drop: bool, can_equip: bool) -> void:
	if anchor_above:
		global_position = slot_global_position + Vector2(-4, -panel.size.y - 30)
	else:
		global_position = slot_global_position + Vector2(-panel.size.x - 12, 0)
	_set_available(use_label, can_use)
	_set_available(drop_label, can_drop)
	_set_available(equip_label, can_equip)
	show()


func hide_menu() -> void:
	hide()


func _set_available(label: Label, available: bool) -> void:
	label.add_theme_color_override("font_color", COLOR_AVAILABLE if available else COLOR_UNAVAILABLE)
