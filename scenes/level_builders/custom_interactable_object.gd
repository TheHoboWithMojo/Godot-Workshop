@icon("res://assets/Icons/16x16/cursor.png")
extends StaticBody2D
class_name Interactable

enum TEMPLATES {CUSTOM, CUTSCENE_MODE, POINT_AND_CLICK_MODE}
enum TRIGGER_MODES {CLICK, ENTRY, CLICK_AND_ENTRY, CLICK_OR_ENTRY}
enum PLAY_MODES {DIALOG, SCENE}

@export var mode: TEMPLATES = TEMPLATES.CUSTOM
@export_subgroup("Mode Reqs/Cutscene", "cutscene")
@export var cutscene_touch_detector: TouchDetector
@export_file("*tscn") var cutscene_scene_path: String

@export_subgroup("Mode Reqs/Point and Click", "point")
@export var point_click_detector: ClickDetector
@export var point_timeline: Dialogue.TIMELINES

@export_group("Mode Reqs/Custom")
@export_subgroup("Trigger Mode", "custom")
@export var custom_trigger_mode: TRIGGER_MODES
@export_subgroup("Trigger Mode/Reqs/Click", "custom")
@export var custom_click_detector: ClickDetector
@export_subgroup("Trigger Mode/Reqs/Entry", "custom")
@export var custom_touch_detector: TouchDetector
@export_subgroup("Trigger Mode/Reqs/Click AND OR Entry", "custom")
@export var custom_click_detector_alt: ClickDetector
@export var custom_touch_detector_alt: TouchDetector

@export_subgroup("Play Mode", "custom")
@export var custom_play_mode: PLAY_MODES
@export_subgroup("Play Mode/Reqs/Dialogue", "custom")
@export var custom_timeline: Dialogue.TIMELINES
@export_subgroup("Play Mode/Reqs/Scene", "custom")
@export_file("*tscn") var custom_scene_path: String

@export_group("Tweaks")
@export var max_trigger_distance: float = 75.0
@export var repeat_event: bool = false
@export var emit_interaction_signals: bool = true

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

@onready var processing_press: bool = false
func _on_button_pressed() -> void:
	if processing_press:
		return
	if not is_event_playable():
		return
	processing_press = true
	player_touched_me.emit(self)
	await _try_play_event()
	processing_press = false

func _on_area_entered(area: Area2D) -> void:
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
			await _try_play_scene()

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
	await node.tree_exited
	event_completed = true
	event_ended.emit(self)

func _assert_mode_requirements() -> void:
	match mode:
		TEMPLATES.CUTSCENE_MODE:
			_assert_cutscene_mode()
		TEMPLATES.POINT_AND_CLICK_MODE:
			_assert_point_and_click_mode()
		TEMPLATES.CUSTOM:
			_assert_custom_mode()

func _assert_cutscene_mode() -> void:
	Debug.enforce(cutscene_touch_detector != null, "An interactable set to cutscene mode must define a touch detector", self)
	Debug.enforce(cutscene_scene_path != "", "An interactable set to cutscene mode must define a scene path", self)

	trigger_mode = TRIGGER_MODES.ENTRY
	_configure_trigger(null, cutscene_touch_detector)
	_configure_play(PLAY_MODES.SCENE, Dialogue.TIMELINES.UNASSIGNED, cutscene_scene_path)

func _assert_point_and_click_mode() -> void:
	Debug.enforce(point_click_detector != null, "An interactable set to point and click mode must define a click detector", self)
	Debug.enforce(point_timeline != Dialogue.TIMELINES.UNASSIGNED, "An interactable set to point and click mode must define a timeline", self)

	trigger_mode = TRIGGER_MODES.CLICK
	_configure_trigger(point_click_detector)
	_configure_play(PLAY_MODES.DIALOG, point_timeline)

func _assert_custom_mode() -> void:
	trigger_mode = custom_trigger_mode

	match trigger_mode:
		TRIGGER_MODES.CLICK:
			Debug.enforce(custom_click_detector != null, "Custom trigger mode CLICK requires a click detector", self)
			_configure_trigger(custom_click_detector)
		TRIGGER_MODES.ENTRY:
			Debug.enforce(custom_touch_detector != null, "Custom trigger mode ENTRY requires a touch detector", self)
			_configure_trigger(null, custom_touch_detector)
		TRIGGER_MODES.CLICK_AND_ENTRY, TRIGGER_MODES.CLICK_OR_ENTRY:
			Debug.enforce(custom_click_detector_alt != null, "Custom trigger mode CLICK_AND_ENTRY or CLICK_OR_ENTRY requires a click detector", self)
			Debug.enforce(custom_touch_detector_alt != null, "Custom trigger mode CLICK_AND_ENTRY or CLICK_OR_ENTRY requires a touch detector", self)
			_configure_trigger(custom_click_detector_alt, custom_touch_detector_alt)

	Debug.enforce(custom_play_mode != null, "Custom play mode must be defined", self)
	play_mode = custom_play_mode

	match play_mode:
		PLAY_MODES.DIALOG:
			Debug.enforce(custom_timeline != Dialogue.TIMELINES.UNASSIGNED, "Custom play mode DIALOG requires a timeline", self)
			_configure_play(PLAY_MODES.DIALOG, custom_timeline)
		PLAY_MODES.SCENE:
			Debug.enforce(custom_scene_path != "", "Custom play mode SCENE requires a scene path", self)
			_configure_play(PLAY_MODES.SCENE, Dialogue.TIMELINES.UNASSIGNED, custom_scene_path)

@onready var click_detector_assigned: bool = false
@onready var touch_detector_assigned: bool = false
func _configure_trigger(click: ClickDetector, touch: TouchDetector = null) -> void:
	Debug.enforce(not (click_detector_assigned or touch_detector_assigned), "Only follow the guidelines of one mode.", self)
	if click != null:
		click_detector = click
		click_detector_assigned = true
		click_detector.pressed.connect(_on_button_pressed)

	if touch != null:
		Debug.enforce(touch.get_collider() != null, "Interactables with a touch detector must have an Area2D collider", self)
		touch_detector = touch
		touch_detector_assigned = true
		touch_detector.set_monitored_parent(self)
		if click != null:
			touch_detector.set_ignored_menu(click_detector)

func _configure_play(play: PLAY_MODES, timeline: Dialogue.TIMELINES = Dialogue.TIMELINES.UNASSIGNED, scene_path: String = "") -> void:
	play_mode = play
	match play_mode:
		PLAY_MODES.DIALOG:
			timeline_to_play = timeline
		PLAY_MODES.SCENE:
			scene_path_to_play = scene_path
