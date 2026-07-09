class_name ToolItem
extends "res://scripts/base_item.gd"

## What kind of tool this is. Gathering scripts (tree, rock, etc.) will check
## this against a required ToolType before allowing the action to succeed.
enum ToolType { AXE = 0, PICKAXE = 1, ROD = 2 }
@export var tool_type : ToolType

## How effective this tool is. Not wired up yet, but gives us a hook for
## gather speed, damage per hit, or durability drain later without needing
## another refactor.
@export var gather_power : int = 1
