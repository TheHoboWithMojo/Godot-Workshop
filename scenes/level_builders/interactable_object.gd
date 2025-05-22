@icon("res://assets/Icons/16x16/cursor.png")
extends StaticBody2D
class_name Interactable

enum TEMPLATES {CUSTOM, PORTAL_MODE, CUTSCENE_MODE, POINT_AND_CLICK_MODE}
enum TRIGGER_MODES {CLICK, ENTRY, CLICK_AND_ENTRY, CLICK_OR_ENTRY}
enum PLAY_MODES {DIALOG, SCENE}

@export_category("Modes")
@export var template: TEMPLATES = TEMPLATES.CUSTOM

@export_subgroup("Mode Reqs/Portal")
@export var send_from_level: Node2D
@export var send_to_level: Levels.LEVELS
@export var spawn_point_portal: SpawnPoint
@export var click_detector_portal: ClickDetector
@export var touch_detector_portal: TouchDetector
@export var touch_detection_zone_portal: Collider
@onready var send_to_level_path: String = Levels.get_level_path(send_to_level) if send_to_level else ""

@export_subgroup("Mode Reqs/Cutscene")
@export var touch_detection_zone_cutscene: Collider
@export var touch_detector_cutscene: TouchDetector
@export var scene_path_cutscene: String

@export_subgroup("Mode Reqs/Point and Click")
@export var click_detector_point: ClickDetector
@export var timeline_point: Dialogue.TIMELINES

@export_group("Mode Reqs/Custom")
@export_subgroup("Trigger Mode")
@export var trigger_mode_custom: TRIGGER_MODES
@export_subgroup("Trigger Mode/Reqs/Click")
@export var click_detector_custom: ClickDetector
@export_subgroup("Trigger Mode/Reqs/Entry")
@export var touch_detector_custom: TouchDetector
@export var touch_detection_zone_custom: Collider
@export_subgroup("Trigger Mode/Reqs/Click AND OR Entry")
@export var click_detector_custom_alt: ClickDetector
@export var touch_detector_custom_alt: TouchDetector
@export var touch_detection_zone_custom_alt: Collider

@export_subgroup("Play Mode")
@export var play_mode_custom: PLAY_MODES
@export_subgroup("Play Mode/Reqs/Dialogue")
@export var timeline_custom: Dialogue.TIMELINES
@export_subgroup("Play Mode/Reqs/Scene")
@export var scene_path_custom: String

@export_category("Tweaks")
@export var max_trigger_distance: float = 100000.0
@export var repeat_event: bool = false
@export var emit_interaction_signals: bool = true

# Canonical runtime variables (set after validation)
var trigger_mode: TRIGGER_MODES
var play_mode: PLAY_MODES
var click_detector: ClickDetector
var touch_detector: TouchDetector
var timeline_to_play: Dialogue.TIMELINES
var scene_path_to_play: String
var event_completed: bool = false

signal event_ended(self_node: Node)
signal event_started(self_node: Node)
signal player_touched_me(self_node: Node)

func _ready() -> void:
	_assert_mode_requirements()
	await get_tree().process_frame

func _on_button_pressed() -> void:
	if not is_event_playable():
		return
	player_touched_me.emit(self)
	if template == TEMPLATES.PORTAL_MODE and Global.player in touch_detector.get_overlapping_bodies():
		print("working")
		Global.level_manager.change_level(send_from_level, send_from_level)
		return
	await _try_play_event()

func _on_area_entered(area: Area2D) -> void: # this runs for ENTRY or ENTRYorCLICK modes
	if not area == Global.player_bubble or not is_event_playable():
		return
	while Global.player_bubble in touch_detector.get_overlapping_areas():
		if Input.is_action_just_pressed("interact"):
			await _try_play_event()
	await get_tree().process_frame


func is_event_playable() -> bool:
	return (Global.get_vector_to_player(self).length() < max_trigger_distance
	and not (event_completed and not repeat_event)
	and not Player.is_occupied())


func _try_play_event() -> void:
	match play_mode:
		PLAY_MODES.DIALOG:
			await _try_play_dialog()
		PLAY_MODES.SCENE:
			_try_play_scene()


func _try_play_dialog() -> void:
	match(trigger_mode):
		pass
	if await Dialogue.start(timeline_to_play):
		event_started.emit(self)
		await Dialogic.timeline_ended
	event_completed = true
	event_ended.emit(self)


func _try_play_scene() -> void:
	match(trigger_mode):
		pass
	event_started.emit(self)
	var node: Node = load(scene_path_to_play).instantiate()
	Global.game_manager.add_child(node)
	node.global_position = Global.player.global_position
	event_completed = true
	event_ended.emit(self)

# ============================
# Mode Assertion Functions
# ============================
func _assert_mode_requirements() -> void:
	match template:
		TEMPLATES.PORTAL_MODE:
			_assert_portal_mode()
		TEMPLATES.CUTSCENE_MODE:
			_assert_cutscene_mode()
		TEMPLATES.POINT_AND_CLICK_MODE:
			_assert_point_and_click_mode()
		TEMPLATES.CUSTOM:
			_assert_custom_mode()


func _assert_portal_mode() -> void:
	assert(send_from_level)
	assert(send_to_level != Levels.LEVELS.UNASSIGNED)
	assert(click_detector_portal)
	assert(touch_detector_portal)
	assert(touch_detection_zone_portal)

	trigger_mode = TRIGGER_MODES.CLICK_AND_ENTRY
	_configure_trigger(click_detector_portal, touch_detector_portal, touch_detection_zone_portal)
	_configure_play(PLAY_MODES.SCENE)
	name = "PortalTo%s" % Levels.get_level_name(send_to_level)


func _assert_cutscene_mode() -> void:
	assert(touch_detection_zone_cutscene)
	assert(touch_detector_cutscene)
	assert(scene_path_cutscene != "")

	trigger_mode = TRIGGER_MODES.ENTRY
	_configure_trigger(null, touch_detector_cutscene, touch_detection_zone_cutscene)
	_configure_play(PLAY_MODES.SCENE, Dialogue.TIMELINES.UNASSIGNED, scene_path_cutscene)


func _assert_point_and_click_mode() -> void:
	assert(click_detector_point)
	assert(timeline_point)

	trigger_mode = TRIGGER_MODES.CLICK
	_configure_trigger(click_detector_point)
	_configure_play(PLAY_MODES.DIALOG, timeline_point)


func _assert_custom_mode() -> void:
	assert(trigger_mode_custom)
	trigger_mode = trigger_mode_custom

	match trigger_mode:
		TRIGGER_MODES.CLICK:
			assert(click_detector_custom)
			_configure_trigger(click_detector_custom)
		TRIGGER_MODES.ENTRY:
			assert(touch_detector_custom)
			_configure_trigger(null, touch_detector_custom, touch_detection_zone_custom)
		TRIGGER_MODES.CLICK_AND_ENTRY, TRIGGER_MODES.CLICK_OR_ENTRY:
			assert(click_detector_custom_alt)
			assert(touch_detector_custom_alt)
			_configure_trigger(click_detector_custom_alt, touch_detector_custom_alt, touch_detection_zone_custom_alt)

	assert(play_mode_custom)
	play_mode = play_mode_custom

	match play_mode:
		PLAY_MODES.DIALOG:
			assert(timeline_custom)
			_configure_play(PLAY_MODES.DIALOG, timeline_custom)
		PLAY_MODES.SCENE:
			assert(scene_path_custom != "")
			_configure_play(PLAY_MODES.SCENE, Dialogue.TIMELINES.UNASSIGNED, scene_path_custom)


func _configure_trigger(click: ClickDetector, touch: TouchDetector = null, detection_zone: Node = null) -> void:
	click_detector = click
	if click:
		click.pressed.connect(_on_button_pressed)

	touch_detector = touch
	if touch:
		touch.set_monitored_parent(self)
		if click:
			touch.set_ignored_menu(click)

	if detection_zone and touch:
		detection_zone.reparent(touch)


func _configure_play(play: PLAY_MODES, timeline: Dialogue.TIMELINES = Dialogue.TIMELINES.UNASSIGNED, scene_path: String = "") -> void:
	play_mode = play
	match play:
		PLAY_MODES.DIALOG:
			timeline_to_play = timeline
		PLAY_MODES.SCENE:
			scene_path_to_play = scene_path
