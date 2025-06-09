@icon("res://assets/Icons/16x16/waypoint.png")
class_name Waypoint
extends Area2D
@export var radius: float = 10.0
@export var quest: Quests.QUESTS
@export var home_level: Levels.LEVELS
@export var complete_on_touch: bool = false
@export var show_icon: bool = false
@export var collider: CollisionShape2D
@export var debugging: bool = false
@onready var sprite: Sprite2D = $Sprite
@onready var spawn_position: Vector2 = global_position
var complete: bool = false
var duplicates: Array[Waypoint]
var quest_node: QuestMaker
var duplicated: bool = false
var active: bool = false # whether or not its active in the current quest

signal player_touched_me

func _ready() -> void:
	assert(quest != Quests.QUESTS.UNASSIGNED, Debug.define_error("All waypoints must link to a quest.", self))
	assert(home_level != Levels.LEVELS.UNASSIGNED, Debug.define_error("Each waypoint must be reference a level enum", self))
	quest_node = Global.quest_manager.get_quest_node(quest)
	sprite.set_visible(false)
	add_to_group("waypoints")
	area_entered.connect(_on_area_entered)
	Debug.debug_if(!duplicated, "spawned and added to waypoint group.", self, "_ready")


func _on_area_entered(area: Area2D) -> void:
	if area == Global.player_bubble:
		player_touched_me.emit()
		Debug.debug_if(!duplicated, "emitting player_touched_me", self, "_on_area_entered")
		if complete_on_touch:
			remove_from_group("waypoints")
			complete = true
			Debug.debug_if(!duplicated, "complete on touch is on... queueing free.", self, "_on_area_entered")
			queue_free()


func is_complete() -> bool:
	return complete


func get_home_level() -> Levels.LEVELS:
	return home_level


func get_quest_enum() -> Quests.QUESTS:
	return quest


func get_quest_node() -> QuestMaker:
	return quest_node


func get_duplicates() -> Array[Waypoint]:
	return duplicates


func is_duplicate() -> bool:
	return duplicated


func set_active(value: bool) -> void:
	if show_icon:
		Debug.debug_if(!duplicated, "Changing visibility to %s" % [str(value)], self, "set_active")
		sprite.set_visible(value)
		active = value
		Debug.debug("setting active to %s" % [value], self, "set_active")


func is_active() -> bool:
	return active


func create_duplicate() -> Waypoint:
	var copy: Waypoint = duplicate()
	duplicates.append(copy)
	add_child(copy, false)
	Debug.debug("Duplicate added!", self, "create_duplicate")
	return copy
