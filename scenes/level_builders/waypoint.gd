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
	assert(quest != 0, "All waypoints must link to a quest.")
	Quests.add_quest_waypoint(self, quest)
	sprite.set_visible(false)
	add_to_group("waypoint")
	if not self in Global.waypoint_manager.get_children():
		reparent.call_deferred(Global.waypoint_manager)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body == Global.player:
		if complete_on_touch:
			remove_from_group("waypoint")
			complete = true
			player_touched_me.emit()
			queue_free()


func is_complete() -> bool:
	return complete


func set_active(value: bool) -> void:
	if show_icon:
		sprite.set_visible(value)
