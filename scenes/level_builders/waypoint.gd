@icon("res://assets/Icons/16x16/waypoint.png")
extends Area2D
class_name Waypoint
@export var radius: float = 10.0
@export var quest: Quests.QUESTS
@export var complete_on_touch: bool = false
@export var show_icon: bool = false
@export var collider: CollisionShape2D
@export var local_waypoints: Node
@onready var sprite: Sprite2D = $Sprite
@onready var complete: bool = false

signal player_touched_me

func _ready() -> void:
	Debug.enforce(quest != 0, "All waypoints must link to a quest.", self)
	sprite.set_visible(false)
	add_to_group("waypoints")
	if not self in Global.waypoint_manager.get_children():
		reparent.call_deferred(Global.waypoint_manager)
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area == Global.player_bubble:
		player_touched_me.emit()
		if complete_on_touch:
			remove_from_group("waypoints")
			complete = true
			queue_free()


func is_complete() -> bool:
	return complete


func set_active(value: bool) -> void:
	if show_icon:
		sprite.set_visible(value)
