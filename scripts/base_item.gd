extends Resource

@export var item_name : String = ""
@export var item_texture : Texture2D
@export var item_desc : String = ""
@export var item_edible : bool = false
@export var item_stackable : bool = true
@export var item_stack_limit : int = 10
@export var item_tool : bool = false
@export var item_ingredient : bool = false
@export var item_scene_path : String
@export var item_qty_per_item : int = 1
