@icon("res://assets/Icons/16x16/cursor.png")
extends StaticBody2D
class_name Interactable
@export_group("Nodes")
@export var ibubble_collider: CollisionShape2D
@export var click_detector: Button
@export_group("Events")
@export var repeat_event_enabled: bool = false
@export var play_timeline_enabled: bool = false
@export var timeline: Dialogue.TIMELINES
@export var play_scene_enabled: bool = false
@export var play_scene_path: String
@export var use_ibubble_enabled: bool
# ONREADY #
@onready var scene: PackedScene = load(play_scene_path) if (play_scene_enabled and not Engine.is_editor_hint()) else null
@onready var ibubble: Area2D = $IBubble


signal player_touched_me
signal event_completed(self_node: Node)
signal event_started(self_node: Node)

func _ready() -> void:
	_assert_rules()
	await get_tree().process_frame


func _assert_rules() -> void:
	assert(play_timeline_enabled != play_scene_enabled, "an interactable cannot be initiated with zero or both of its functions.")
	if play_timeline_enabled:
		assert(timeline, "an timeline-playing interactable must have an assigned timeline.")
	if play_scene_enabled:
		assert(play_scene_path, "an interactable set to play a timeline must have a valid TIMELINES value")
		assert(ibubble or click_detector, "every interactable needs at least one detection source")
	if click_detector:
		click_detector.pressed.connect(_on_button_pressed)
	if use_ibubble_enabled:
		assert(ibubble_collider, "interactables set to use ibubbles must have collision in order to track touching state.")
		ibubble_collider.reparent(ibubble)
		if click_detector:
			ibubble.set_ignored_menu(click_detector)
	else:
		ibubble.queue_free()
		if ibubble_collider:
			ibubble_collider.queue_free()


@onready var _event_completed: bool = false
func _try_play_dialog() -> void:
	if await Dialogue.start(timeline):
		event_started.emit(self)
		await Dialogic.timeline_ended
	_event_completed = true
	event_completed.emit(self)


func _try_play_scene() -> void:
	event_started.emit(self)
	var node: Node = scene.instantiate()
	Global.game_manager.add_child(node)
	node.set_global_position(Global.player.global_position)
	_event_completed = true
	event_completed.emit(self)


func _on_button_pressed() -> void:
	player_touched_me.emit()
	if (_event_completed and not repeat_event_enabled) or Player.is_occupied():
		return
	if play_timeline_enabled:
		await _try_play_dialog()
	if play_scene_enabled:
		_try_play_scene()
