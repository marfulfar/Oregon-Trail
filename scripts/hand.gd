extends Node2D

## Hand-item visual layer (see inventory_equip_system_spec.md §7.7): shows
## whichever tool is equipped in HAND as a small icon (its own item_texture -
## e.g. axe.tres's hatchet.png), separate from the character's own body
## animation. Swing motion itself now comes from the AnimationPlayer's
## chop_hand clip (see player.gd), which keys this node's position/rotation
## directly - this script only keeps the icon showing the right texture.

@export var icon_scale: float = 0.3

## Where in the icon texture the character's grip is, as a fraction of the
## image size (0,0 = top-left, 1,1 = bottom-right). The sprite is offset so
## this point sits at the hand node's own origin, which is what chop_hand's
## rotation track (if any) pivots around. Tuned for hatchet.png's handle tip;
## adjust per-tool if a future icon's grip point lands somewhere else.
@export var grip_point: Vector2 = Vector2(0.78, 0.8)

@onready var sprite: Sprite2D = $swing/Sprite2D


func _ready() -> void:
	EquipmentManager.equipment_changed.connect(_on_equipment_changed)
	_refresh_icon()


func _on_equipment_changed(slot: BaseItem.EquipSlot, _item: Resource) -> void:
	if slot == BaseItem.EquipSlot.HAND:
		_refresh_icon()


func _refresh_icon() -> void:
	var equipped: Resource = EquipmentManager.get_equipped(BaseItem.EquipSlot.HAND)
	sprite.texture = equipped.item_texture if equipped != null else null
	sprite.visible = sprite.texture != null
	sprite.scale = Vector2(icon_scale, icon_scale)
	if sprite.texture != null:
		sprite.offset = (Vector2(0.5, 0.5) - grip_point) * sprite.texture.get_size()
