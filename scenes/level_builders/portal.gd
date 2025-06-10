@icon("res://assets/Icons/16x16/cursor.png")
class_name Portal extends StaticBody2D

@export var debugging: bool = false
@export_category("REQS")
@export var send_from_level: Node2D
@export var send_to_level: Levels.LEVELS
@export var spawn_point: SpawnPoint
@export var touch_detector: TouchDetector
@onready var send_to_level_path: String = Levels.get_level_path(send_to_level) if send_to_level else ""

@export_category("TWEAKS")
@export var emit_interaction_signals: bool = true

signal player_touched_me(self_node: Node)

func _ready() -> void:
	assert(send_from_level != null, Debug.define_error("Portals must reference the level they're in", self))

	assert(send_to_level != Levels.LEVELS.UNASSIGNED, Debug.define_error("Portals must reference the level they lead to", self))
	name = "PortalTo%s" % Levels.get_level_name(send_to_level)

	assert(touch_detector != null, Debug.define_error("Portals must have touch detection in order to ensure the player is touching them", self))
	touch_detector.player_entered_area.connect(_on_player_entered_area)

	add_to_group("portal")
	add_to_group("interactable")
	await get_tree().process_frame


@onready var processing_interaction: bool = false
func _on_player_entered_area() -> void:
	if processing_interaction or Player.is_occupied():
		Debug.debug("Processing transfer failed", self, "_on_portal_clicked")
		return

	var id: int = randi()
	Debug.doc_loop_start(self, "_on_player_entered_area", id)
	while Global.player_bubble in touch_detector.get_overlapping_areas():
		if Input.is_action_just_pressed("interact"):
			processing_interaction = true
			player_touched_me.emit(self)
			Debug.debug("Processing click succeeded, changing level!", self, "_on_portal_clicked")
			await Global.level_manager.change_level(send_from_level, send_to_level_path)
			processing_interaction = false
		await get_tree().process_frame
	Debug.doc_loop_end(id)


func get_spawn_point_position() -> Vector2:
	return spawn_point.global_position


func get_send_to_level_enum() -> Levels.LEVELS:
	return send_to_level
