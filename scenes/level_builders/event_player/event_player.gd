@icon("res://assets/Icons/16x16/computer.png")
class_name EventPlayer extends Node
@export var parent: Node = null
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@export var trigger_mode: TRIGGER_MODES = TRIGGER_MODES.INTERACTION_WHILE_TOUCHING
@export var play_mode: PLAY_MODES = PLAY_MODES.DIALOG
@export_range(1, 1000) var max_trigger_distance: float = 100.0
@export var touch_detector: TouchDetector
@export var one_time_event: bool = false
@export var timeline: Dialogue.TIMELINES = Dialogue.TIMELINES.UNASSIGNED
@export_file("*tscn") var scene: String
@export var emit_interaction_signals: bool = false
@export var enabled: bool = true
var _event_playing: bool = false
var _event_completed: bool = false
var _processing_interaction: bool = false
var _mouse_touching: bool = false
var _interaction_input_name: String = "interact"
var _click_input_name: String = "click"
var _custom_trigger_requirement: Callable
var player_bubble: Area2D

signal event_started()
signal event_ended()
signal player_touched_me()

enum TRIGGER_MODES { RANGE_LIMITED_CLICK, AREA_ENTRY, INTERACTION_WHILE_TOUCHING }
enum PLAY_MODES { DIALOG, SCENE }


func _ready() -> void:
	assert(parent != null, Debug.define_error("All EventPlayers must reference a parent", self))
	debugging = Debug.get_configed_debugging(parent, debugging, inherit_debugging)
	assert(touch_detector, Debug.define_error("Child EventPlayer must reference a touch detector", parent))
	match play_mode:
		PLAY_MODES.DIALOG:
			if timeline == Dialogue.TIMELINES.UNASSIGNED and scene:
				push_warning(Debug.define_error("Child EventPlayer was set to play Dialogue but was assigned only a scene path", parent))
			elif timeline == Dialogue.TIMELINES.UNASSIGNED and not scene:
				push_warning(Debug.define_error("Child EventPlayer was set to play Dialogue but was not initialized with a timeline", parent))
			Debug.debug("Child EventPlayer play mode initialized as 'dialogue'", parent, "_ready", self)
		PLAY_MODES.SCENE:
			if timeline != Dialogue.TIMELINES.UNASSIGNED and scene == "":
				push_warning(Debug.define_error("Child EventPlayer was set to play Scene but was assigned only a timeline", parent))
			elif timeline != Dialogue.TIMELINES.UNASSIGNED and scene == "":
				push_warning(Debug.define_error("Child EventPlayer was set to play Scene but was not initialized with a scene path", parent))
			Debug.debug("Child EventPlayer play mode initialized as 'scene'", parent, "_ready", self)
	if scene and timeline:
		push_warning(Debug.define_error("Child EventPlayer was initialized with both a timeline and scene", parent))
	match trigger_mode:
		TRIGGER_MODES.RANGE_LIMITED_CLICK:
			touch_detector.mouse_entered_area.connect(_on_mouse_entered_area)
			touch_detector.mouse_exited_area.connect(_on_mouse_exited_area)
			Debug.debug("Child EventPlayer trigger mode set to 'range limited click'", parent, "_ready", self)
		TRIGGER_MODES.AREA_ENTRY:
			touch_detector.player_entered_area.connect(_on_player_entered_area)
			Debug.debug("Child EventPlayer trigger mode set to 'area entry'", parent, "_ready", self)
		TRIGGER_MODES.INTERACTION_WHILE_TOUCHING:
			touch_detector.player_entered_area.connect(_on_player_entered_area)
			Debug.debug("Child EventPlayer trigger mode set to 'interaction while touching", parent, "_ready", self)
	player_bubble = Global.player_bubble
	assert(player_bubble)


func set_enabled(value: bool) -> void:
	enabled = value


func is_event_complete() -> bool:
	return _event_completed


func is_event_playing() -> bool:
	return _event_playing


func is_processing_interaction() -> bool:
	return _processing_interaction


func set_one_time_event_enabled(value: bool) -> void:
	if one_time_event == value:
		return
	if is_processing_interaction():
		await event_ended
	one_time_event = value


func set_max_trigger_distance(new_distance: float) -> void:
	if new_distance < 0:
		push_error(Debug.define_error("Tried to set max trigger distance of Child EventPlayer to a negative value", parent))
		return
	max_trigger_distance = new_distance


func is_repeatable() -> bool:
	return false if ((one_time_event and _event_completed) or not enabled) else true


func get_max_trigger_distance() ->  float:
	return max_trigger_distance


func is_within_max_trigger_distance(node2d: Node2D) -> bool:
	return Global.get_vector_to_player(node2d).length() < max_trigger_distance


func get_touch_detector() -> TouchDetector:
	if not touch_detector:
		push_error(Debug.define_error("Child EventManager's TouchDetector reference was either corrupted or unassigned", parent))
		return null
	return touch_detector


func set_timeline_enum(_timeline: Dialogue.TIMELINES) -> void:
	if is_processing_interaction():
		await event_ended
	_event_completed = false
	Debug.debug("Timeline set to %s" % [Dialogue.get_timeline_name(_timeline)], parent, "set_timeline_enum", self)
	timeline = _timeline


func set_play_scene_path(path: String) -> void:
	if not FileAccess.file_exists(path) or not path.ends_with(".tscn") or path == "":
		push_error(Debug.define_error("Tried to set Child EventPlayer's play scene path to invalid path %s" % [parent.name], self))
		return
	if is_processing_interaction():
		await event_ended
	scene = path


func get_timeline_enum() -> Dialogue.TIMELINES:
	return timeline


func get_play_scene_path() -> String:
	return scene


func define_custom_trigger_requirement(callback: Callable) -> void:
	Debug.debug("Attempting to set new custom trigger req for child EventManager", parent, "define_custom_trigger_requirement", self)
	if not callback.is_valid():
		push_error(Debug.define_error("Child EventPlayer of assumed parent %s - Attempted to define an invalid custom trigger Callable" % [str(get_parent())], self))
		return
	var test_result: Variant = callback.call()
	if typeof(test_result) != TYPE_BOOL:
		push_error(Debug.define_error("Child EventPlayer - attempted to set custom trigger requirement with Callable '%s' that returns non-boolean (%s)" % [str(callback), typeof(test_result)], parent))
		return
	if _custom_trigger_requirement.is_valid():
		push_warning(Debug.define_error("Child EventPlayer - Overriding previously defined custom trigger requirement '%s'" % [str(_custom_trigger_requirement)], parent))
	_custom_trigger_requirement = callback
	Debug.debug("Successfully added custom trigger req method '%s' to Child EventPlayer" % [str(_custom_trigger_requirement)], parent, "define_custom_trigger_requirement", self)


func is_custom_reqs_met() -> bool:
	return not _custom_trigger_requirement.is_valid() or _custom_trigger_requirement.call()


func _on_player_entered_area() -> void:
	player_touched_me.emit()
	Debug.debug("Player touched me!", parent, "_on_player_entered_area", self)
	if _processing_interaction or not is_repeatable():
		return
	_processing_interaction = true
	match trigger_mode:
		TRIGGER_MODES.AREA_ENTRY:
			await _try_play_event()
		TRIGGER_MODES.INTERACTION_WHILE_TOUCHING:
			Debug.debug("Player is touching and child EventPlayer 'interaction while touching' mode is turned on, running loop for interaction check", parent, "_on_player_entered_area", self)
			var id: int = randi()
			Debug.doc_loop_start(self, "_player_entered_area", id)
			while _is_player_touching_parent():
				if Input.is_action_just_pressed(_interaction_input_name) and is_custom_reqs_met():
					await _try_play_event()
					break
				await get_tree().process_frame
			Debug.doc_loop_end(id)
			if not _is_player_touching_parent():
				Debug.debug("Interaction check loop was unsuccesful, breaking loop", parent, "_on_player_entered_area", self)
			_processing_interaction = false


func _on_mouse_entered_area() -> void:
	_mouse_touching = true
	if _processing_interaction or not is_repeatable():
		return
	_processing_interaction = true
	var id: int = randi()
	Debug.doc_loop_start(parent, "_on_mouse_entered_area", id)
	while _mouse_touching:
		if _is_parent_within_max_trigger_distance() and Input.is_action_just_pressed(_click_input_name) and is_custom_reqs_met(): # and custom_criteria trigger method
			await _try_play_event()
			break
		await get_tree().process_frame
	Debug.doc_loop_end(id)
	_processing_interaction = false


func _is_parent_within_max_trigger_distance() -> bool:
	return Global.get_vector_to_player(parent).length() < max_trigger_distance


func _is_player_touching_parent() -> bool:
	return player_bubble in touch_detector.get_overlapping_areas() if touch_detector.monitoring else false


func _on_mouse_exited_area() -> void:
	_mouse_touching = false


func _try_play_event() -> void:
	match play_mode:
		PLAY_MODES.DIALOG:
			if Dialogue.start(timeline):
				Debug.debug("Dialogue play was successful, breaking loop", parent, "_try_play_event", self)
				event_started.emit()
				_event_playing = true
				await Dialogic.timeline_ended
		PLAY_MODES.SCENE:
			Global.enter_menu()
			var node: Node = load(scene).instantiate()
			Global.game_manager.add_child(node)
			node.global_position = Global.player.global_position
			event_started.emit()
			Debug.debug("Scene play was successful, breaking loop", parent, "_try_play_event", self)
			_event_playing = true
			await node.tree_exited
			Global.exit_menu()
	_event_playing = false
	_event_completed = true
	event_ended.emit()
