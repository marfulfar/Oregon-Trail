extends Control

@onready var world = $"../.."
@onready var player
# Holds the current Inventory resource, so input handling and drops can read from it directly.
var player_inventory : Inventory

#the 5 sprites slots in the inventory
@onready var slot1 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect1
@onready var slot2 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect2
@onready var slot3 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect3
@onready var slot4 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect4
@onready var slot5 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect5
@onready var inventory_slots = [slot1, slot2, slot3, slot4, slot5]
#the 5 labels for qty in the slots in the inventory
@onready var label1 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect1/Label1
@onready var label2 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect2/Label2
@onready var label3 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect3/Label3
@onready var label4 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect4/Label4
@onready var label5 = $inventorySprite/MarginContainer/HBoxContainer/TextureRect5/Label5
@onready var inventory_labels = [label1, label2, label3, label4, label5]
@onready var hbox_container: HBoxContainer = $inventorySprite/MarginContainer/HBoxContainer
@onready var base_margin_container: MarginContainer = $inventorySprite/MarginContainer

## Backpack extra slots (spec: base row + backpack's own capacity, shown as
## a second block of slots next to the base row - see project memory on the
## backpack redesign). Rather than stretching the base row's own background
## to fit more slots (which doesn't scale - see git history), this clones
## the base block's look (same background texture/margins) as an entirely
## separate block positioned to the right, sized proportionally to the
## backpack's own capacity. Gives a clear visual "these are two different
## inventories sitting side by side" cue, and if a future backpack has a
## different slot count (e.g. 8), only the sizing math here needs revisiting
## - a dedicated differently-shaped background asset can replace this reused
## one later without changing the underlying slot-routing logic.
const BACKPACK_SLOT_TINT := Color(0.7, 0.85, 1.0)
const BLOCK_GAP := 24.0
var backpack_inventory: Inventory = null
var backpack_slot_nodes: Array = [] # each entry: {"rect": TextureRect, "label": Label}
var backpack_sprite: TextureRect = null
var backpack_hbox: HBoxContainer = null
var _base_sprite_offset_left: float
var _base_sprite_offset_right: float
#the game paused label
@onready var label_game_paused = $inventorySprite/pausedGame
#the action label
@onready var label_use_item = $inventorySprite/Container/cursor/Drop_label
@onready var label_drop_item = $inventorySprite/Container/cursor/Use_label


@export var scale_factor = 1.2 #the amount of scale of the inventory when opened
var original_scale
var is_inventory_open = false
@onready var inventory_sprite = $inventorySprite
@onready var selector: TextureRect = $inventorySprite/Container/cursor #the inventory cursor
@onready var equip_ui = $"../EquipUI"
@onready var crafting_menu = $"../CraftMenu"
@onready var context_menu = $"../ContextMenu"
@export var slot_count: int = 5 # Number of BASE slots in the HBoxContainer - keep in sync with base_inventory_capacity on player. Indices >= slot_count are backpack slots (see backpack_slot_nodes).
var cursor_slot = 0

## Row/column cursor navigation (spec §4). ROW is the inventory bar (this
## script's own selector); COLUMN is the equip panel (EquipUI owns its own
## cursor visual - see equip_ui.gd's set_cursor_index()/set_cursor_visible()).
## cursor_slot means "index in the inventory row" while in ROW, or "index in
## SLOT_ORDER (Head/Torso/Backpack/Hand)" while in COLUMN - never both at once.
enum CursorLocation { ROW, COLUMN }
var cursor_location: CursorLocation = CursorLocation.ROW
const EQUIP_SLOT_COUNT := 4


func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("inventory_updated", _on_character_inventory_updated) #Connecting from player node
		# Connect directly to the Inventory's own signal too, and right away
		# rather than waiting for the first inventory_updated - otherwise
		# code that mutates the Inventory straight (e.g.
		# InventoryUtils.add_or_drop(), used by equip/unequip) wouldn't
		# repaint the UI until whatever *next* happens to fire
		# inventory_updated through the normal pickup/craft/eat path.
		player_inventory = player.inventory
		player_inventory.inventory_changed.connect(_on_inventory_changed)
	else:
		printerr("Player not found!")

	_base_sprite_offset_left = inventory_sprite.offset_left
	_base_sprite_offset_right = inventory_sprite.offset_right

	EquipmentManager.equipment_changed.connect(_on_equipment_changed)
	_refresh_backpack_slots() # also does the initial repaint of both slot ranges

	original_scale = scale
	selector.visible = false
	original_scale = inventory_sprite.scale
	label_game_paused.visible = false
	label_use_item.visible = false
	label_drop_item.visible = false

func _process(delta):
	# Mutually exclusive with the crafting menu (spec §4): while it's open it
	# takes exclusive input, so ignore the inventory toggle entirely rather
	# than letting both panels show at once.
	if Input.is_action_just_pressed("menu") and not crafting_menu.is_open: #ESC in keyboard
		is_inventory_open = !is_inventory_open #Toggles the boolean

		if is_inventory_open:
			scale = original_scale * scale_factor #increase size of inventory by scale_factor
			# Cursor always resets to the leftmost row slot on open - no
			# memory of the last position (spec §4: contents may have
			# changed while the panel was closed).
			cursor_location = CursorLocation.ROW
			cursor_slot = 0
			selector.visible = true # cursor visible
			equip_ui.set_cursor_visible(false)
			update_selector_position()
			#get_tree().paused = true #Pauses the game (HUD not paused)
			#label_game_paused.visible = true
		else:
			scale = original_scale
			selector.visible = false
			equip_ui.set_cursor_visible(false)
			#get_tree().paused = false
			#label_game_paused.visible = false

	if is_inventory_open:
		if Input.is_action_just_pressed("menu_right"):
			if cursor_location == CursorLocation.ROW:
				if cursor_slot < _get_total_slot_count() - 1:
					cursor_slot += 1
					update_selector_position()
				else:
					# Rightmost row slot -> equip column, always landing on
					# Hand (bottom-most - spatially closest to the row).
					cursor_location = CursorLocation.COLUMN
					cursor_slot = EQUIP_SLOT_COUNT - 1
					selector.visible = false
					equip_ui.set_cursor_visible(true)
					equip_ui.set_cursor_index(cursor_slot)
			# menu_right inside COLUMN is undefined/no-op (column is vertical).

		if Input.is_action_just_pressed("menu_left"):
			if cursor_location == CursorLocation.ROW:
				cursor_slot = max(cursor_slot - 1, 0)
				update_selector_position()
			else:
				# Any equip slot -> back to the row, always at the rightmost
				# slot (fixed re-entry point regardless of which equip slot).
				cursor_location = CursorLocation.ROW
				cursor_slot = _get_total_slot_count() - 1
				equip_ui.set_cursor_visible(false)
				selector.visible = true
				update_selector_position()

		if cursor_location == CursorLocation.COLUMN:
			if Input.is_action_just_pressed("menu_up"):
				cursor_slot = max(cursor_slot - 1, 0) # hard boundary at Head, no wraparound
				equip_ui.set_cursor_index(cursor_slot)
			if Input.is_action_just_pressed("menu_down"):
				cursor_slot = min(cursor_slot + 1, EQUIP_SLOT_COUNT - 1) # hard boundary at Hand
				equip_ui.set_cursor_index(cursor_slot)

	# Contextual action menu (spec §5): Square=Use, Triangle=Drop/Unequip,
	# Circle=Equip, X=unassigned/reserved. Separate named actions per context
	# (menu_use/menu_drop/menu_equip vs world_tool_use/collect) so the same
	# physical button can mean different things without code ambiguity.
	if Input.is_action_just_pressed("menu_use") and is_inventory_open and cursor_location == CursorLocation.ROW:
		var slot = _get_slot(cursor_slot)
		if slot and not slot.is_empty() and slot.item.item_edible:
			player.remove_item_inventory(slot.item, 1, _get_active_inventory(cursor_slot), _get_local_slot_index(cursor_slot))

	if Input.is_action_just_pressed("menu_drop") and is_inventory_open:
		if cursor_location == CursorLocation.ROW:
			var slot = _get_slot(cursor_slot)
			if slot and not slot.is_empty():
				var selected_item = slot.item
				player.remove_item_inventory(selected_item, 1, _get_active_inventory(cursor_slot), _get_local_slot_index(cursor_slot))
				var scene_path = selected_item.item_scene_path
				var instance = load(scene_path).instantiate()
				instance.position = world.to_local(player.global_position)
				world.add_child(instance)
		else:
			_unequip_column_slot(equip_ui.get_slot_at_index(cursor_slot))

	if Input.is_action_just_pressed("menu_equip") and is_inventory_open and cursor_location == CursorLocation.ROW:
		var slot = _get_slot(cursor_slot)
		if slot and not slot.is_empty() and slot.item.equip_slot != BaseItem.EquipSlot.NONE:
			_equip_from_inventory(slot.item, cursor_slot)

	_refresh_context_menu()


## Triangle/unequip from the equip column. BACKPACK always drops (with
## contents, via unequip_backpack()) - it can never sit in the inventory.
## Every other slot follows the general 3-tier priority: back to inventory
## if there's space, else drop on the ground.
func _unequip_column_slot(target_slot: BaseItem.EquipSlot) -> void:
	if target_slot == BaseItem.EquipSlot.BACKPACK:
		EquipmentManager.unequip_backpack()
		return

	var item := EquipmentManager.unequip(target_slot)
	if item != null:
		InventoryUtils.add_or_drop(player_inventory, item, 1)


## Circle/equip from the inventory row. Removes item from inventory first
## (freeing a slot for whatever gets displaced), displaces any current
## occupant of the target slot through the same 3-tier priority, then
## equips. BACKPACK uses equip_backpack()'s own built-in swap-drop instead
## of the generic displacement path, since a backpack can never go back into
## the inventory.
func _equip_from_inventory(item: Resource, index: int) -> void:
	var target_slot: BaseItem.EquipSlot = item.equip_slot
	player.remove_item_inventory(item, 1, _get_active_inventory(index), _get_local_slot_index(index))

	if target_slot == BaseItem.EquipSlot.BACKPACK:
		EquipmentManager.equip_backpack(item)
		return

	var occupant := EquipmentManager.get_equipped(target_slot)
	if occupant != null:
		InventoryUtils.add_or_drop(player_inventory, occupant, 1)
	EquipmentManager.equip(item, target_slot)


## Repositions/refreshes the contextual action menu popup above whichever
## slot currently has focus - called every frame the panel is open so it's
## always in sync with the cursor, regardless of which input just moved it.
func _refresh_context_menu() -> void:
	if not is_inventory_open:
		context_menu.hide_menu()
		return

	if cursor_location == CursorLocation.ROW:
		var slot = _get_slot(cursor_slot)
		var has_item: bool = slot != null and not slot.is_empty()
		var can_use: bool = has_item and slot.item.item_edible
		var can_equip: bool = has_item and slot.item.equip_slot != BaseItem.EquipSlot.NONE
		context_menu.show_for_slot(selector.global_position, true, can_use, has_item, can_equip)
	else:
		var target_slot: BaseItem.EquipSlot = equip_ui.get_slot_at_index(cursor_slot)
		var occupied: bool = EquipmentManager.get_equipped(target_slot) != null
		context_menu.show_for_slot(equip_ui.get_cursor_global_position(), false, false, occupied, false)


## Moves the cursor to whichever slot's visual node cursor_slot currently
## points at (base row or backpack extension). Reads the target node's
## actual global_position instead of a hardcoded per-slot pixel pitch, since
## the row's total slot count - and therefore each slot's real width and
## the container's layout - now changes dynamically when a backpack is
## equipped/unequipped.
func update_selector_position():
	var target_node := _get_slot_visual_node(cursor_slot)
	if target_node:
		selector.global_position = target_node.global_position


func _on_character_inventory_updated(updated_inventory: Inventory): #connects from player
	player_inventory = updated_inventory
	_repaint_all_slots()


func _on_inventory_changed() -> void:
	_repaint_all_slots()


func _on_equipment_changed(slot: BaseItem.EquipSlot, _item: Resource) -> void:
	if slot == BaseItem.EquipSlot.BACKPACK:
		_refresh_backpack_slots()


## Tears down and rebuilds the dynamic backpack block to match whatever
## backpack (if any) is currently equipped - its capacity is per-instance
## (extra_slots on the specific BackpackItem, not a fixed constant), so this
## can't be pre-built once in the scene.
func _refresh_backpack_slots() -> void:
	if backpack_inventory != null and backpack_inventory.inventory_changed.is_connected(_on_inventory_changed):
		backpack_inventory.inventory_changed.disconnect(_on_inventory_changed)

	backpack_slot_nodes.clear()
	_destroy_backpack_block()

	backpack_inventory = EquipmentManager.get_backpack_inventory()

	if backpack_inventory != null:
		backpack_inventory.inventory_changed.connect(_on_inventory_changed)
		_build_backpack_block()
		for i in backpack_inventory.capacity:
			var rect := TextureRect.new()
			rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rect.size_flags_stretch_ratio = 1.0
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.modulate = BACKPACK_SLOT_TINT

			var label := Label.new()
			label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			label.offset_left = -40
			label.offset_top = -23
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			rect.add_child(label)

			backpack_hbox.add_child(rect)
			backpack_slot_nodes.append({"rect": rect, "label": label})

	_reposition_blocks()

	# If the row just shrank (backpack unequipped) while the cursor was
	# sitting past its new end, pull it back to the last valid slot.
	if cursor_location == CursorLocation.ROW and cursor_slot >= _get_total_slot_count():
		cursor_slot = max(_get_total_slot_count() - 1, 0)
		if is_inventory_open:
			update_selector_position()

	_repaint_all_slots()


func _get_total_slot_count() -> int:
	return slot_count + (backpack_inventory.capacity if backpack_inventory != null else 0)


## Clones the base row's background look (texture/expand/stretch settings)
## as an independent block, with its own MarginContainer (copying the base
## one's margins) and HBoxContainer (copying its separation), ready for
## _refresh_backpack_slots() to fill with tinted slot TextureRects.
func _build_backpack_block() -> void:
	backpack_sprite = TextureRect.new()
	backpack_sprite.texture = inventory_sprite.texture
	backpack_sprite.expand_mode = inventory_sprite.expand_mode
	backpack_sprite.stretch_mode = inventory_sprite.stretch_mode
	backpack_sprite.layout_mode = 1
	backpack_sprite.anchor_left = inventory_sprite.anchor_left
	backpack_sprite.anchor_right = inventory_sprite.anchor_right
	backpack_sprite.anchor_top = inventory_sprite.anchor_top
	backpack_sprite.anchor_bottom = inventory_sprite.anchor_bottom
	backpack_sprite.offset_top = inventory_sprite.offset_top
	backpack_sprite.offset_bottom = inventory_sprite.offset_bottom
	add_child(backpack_sprite)

	var margin := MarginContainer.new()
	margin.layout_mode = 1
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = base_margin_container.offset_left
	margin.offset_top = base_margin_container.offset_top
	margin.offset_right = base_margin_container.offset_right
	margin.offset_bottom = base_margin_container.offset_bottom
	backpack_sprite.add_child(margin)

	backpack_hbox = HBoxContainer.new()
	backpack_hbox.add_theme_constant_override("separation", hbox_container.get_theme_constant("separation"))
	margin.add_child(backpack_hbox)


func _destroy_backpack_block() -> void:
	if backpack_sprite != null:
		backpack_sprite.queue_free()
	backpack_sprite = null
	backpack_hbox = null


## Positions the base row and the backpack block (if any) as a pair centered
## as a whole, base on the left with a margin from the screen edge, backpack
## block immediately to its right - restores the base row to its originally
## authored centered position when no backpack is equipped.
func _reposition_blocks() -> void:
	if backpack_sprite == null:
		inventory_sprite.offset_left = _base_sprite_offset_left
		inventory_sprite.offset_right = _base_sprite_offset_right
		return

	var base_width: float = _base_sprite_offset_right - _base_sprite_offset_left
	var backpack_width: float = base_width * (float(backpack_inventory.capacity) / float(slot_count))
	var total_width: float = base_width + BLOCK_GAP + backpack_width
	var left_edge: float = -total_width / 2.0

	inventory_sprite.offset_left = left_edge
	inventory_sprite.offset_right = left_edge + base_width

	backpack_sprite.offset_left = left_edge + base_width + BLOCK_GAP
	backpack_sprite.offset_right = left_edge + base_width + BLOCK_GAP + backpack_width


## The TextureRect a given row index is currently displayed by - base slot
## or dynamic backpack slot.
func _get_slot_visual_node(index: int) -> Control:
	if index < slot_count:
		return inventory_slots[index] if index < inventory_slots.size() else null
	var backpack_index: int = index - slot_count
	return backpack_slot_nodes[backpack_index].rect if backpack_index < backpack_slot_nodes.size() else null


## Which Inventory a given row index actually belongs to.
func _get_active_inventory(index: int) -> Inventory:
	return player_inventory if index < slot_count else backpack_inventory


## A row index's slot position within whichever Inventory it maps to (see
## _get_active_inventory()) - the base row's indices already line up 1:1,
## backpack indices need the base slot_count subtracted back out.
func _get_local_slot_index(index: int) -> int:
	return index if index < slot_count else index - slot_count


func _repaint_all_slots() -> void:
	_populate_slot_range(inventory_slots, inventory_labels, player_inventory)
	if backpack_inventory != null:
		var backpack_rects: Array = []
		var backpack_labels: Array = []
		for entry in backpack_slot_nodes:
			backpack_rects.append(entry.rect)
			backpack_labels.append(entry.label)
		_populate_slot_range(backpack_rects, backpack_labels, backpack_inventory)


func _populate_slot_range(rects: Array, labels: Array, inv: Inventory) -> void:
	# Each slot in inv.slots maps 1:1 to a UI slot by index now, so there's no
	# need to track a separate slot_index counter like the old dictionary
	# version did - the array position IS the UI position, empty or not.
	for i in range(rects.size()):
		if inv == null or i >= inv.slots.size():
			# Safety guard in case the UI has more visual slots than the
			# inventory's actual capacity (shouldn't normally happen).
			rects[i].texture = null
			labels[i].text = ""
			continue

		var slot = inv.slots[i]
		if slot.is_empty():
			rects[i].texture = null
			labels[i].text = ""
		else:
			rects[i].texture = slot.item.item_texture
			labels[i].text = "x" + String.num_int64(slot.quantity)


func _get_slot(index: int) -> InventorySlot:
	var inv := _get_active_inventory(index)
	if inv == null:
		return null
	var local_index: int = index if index < slot_count else index - slot_count
	if local_index < 0 or local_index >= inv.slots.size():
		return null
	return inv.slots[local_index]
