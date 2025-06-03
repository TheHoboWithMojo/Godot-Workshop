@icon("res://assets/Icons/16x16/cursor.png")
extends StaticBody2D
class_name Portal

@export var debugging: bool = false
@export_category("REQS")
@export var send_from_level: Node2D
@export var send_to_level: Levels.LEVELS
@export var spawn_point: SpawnPoint
@export var click_detector: ClickDetector
@export var touch_detector: TouchDetector
@onready var send_to_level_path: String = Levels.get_level_path(send_to_level) if send_to_level else ""

@export_category("TWEAKS")
@export var emit_interaction_signals: bool = true


signal player_touched_me(self_node: Node)

func _ready() -> void:
	Debug.enforce(send_from_level != null, "Portals must reference the level they're in", self)

	Debug.enforce(send_to_level != Levels.LEVELS.UNASSIGNED, "Portals must reference the level they lead to", self)
	name = "PortalTo%s" % Levels.get_level_name(send_to_level)

	Debug.enforce(click_detector != null, "Portals must have click detection to register interaction", self)
	click_detector.pressed.connect(_on_portal_clicked)

	Debug.enforce(touch_detector != null, "Portals must have touch detection in order to ensure the player is touching them", self)
	touch_detector.set_ignored_menu(click_detector) # stops the touch detector from setting mouse_touching_node to false when the click detector is touched

	add_to_group("portal")
	add_to_group("interactable")
	await get_tree().process_frame

@onready var processing_click: bool = false
func _on_portal_clicked() -> void:
	if processing_click or Player.is_occupied() or (not Global.player_bubble in touch_detector.get_overlapping_areas()):
		return
	processing_click = true
	player_touched_me.emit(self)
	Global.level_manager.change_level(send_from_level, send_to_level_path)
	processing_click = false


func get_spawn_point_position() -> Vector2:
	return spawn_point.global_position
