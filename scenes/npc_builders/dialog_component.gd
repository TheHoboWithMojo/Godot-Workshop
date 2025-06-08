@icon("res://assets/Icons/16x16/dialogue.png")
class_name DialogComponent extends Node

# --- Exported Variables ---
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@export var parent: Node
@export var self_parented: bool = false
#@export var debugging: bool = false
#@export var inherit_debugging: bool = false
@export var timeline: Dialogue.TIMELINES
@export var max_trigger_distance: float = 1000.0

@export_group("Trigger Config")
@export var trigger_mode: TRIGGER_MODES = TRIGGER_MODES.CLICK_WHILE_TOUCHING
@export var touch_detector: TouchDetector
var touch_detector_region: Rect2

# --- Enums ---
enum TRIGGER_MODES { CLICK_ONLY, TOUCH_ONLY, CLICK_WHILE_TOUCHING }

# --- Internal State ---
var processing_press: bool = false
var processing_entry: bool = false

# --- Signals ---
signal dialog_started(parent: Node)
signal dialog_ended(parent: Node)
signal processing_complete

# --- Setup ---
func _ready() -> void:
	debugging = parent.debugging if parent and inherit_debugging else debugging
	if self_parented:
		parent = self
		Debug.debug("In self_parent mode", self if parent != self and not inherit_debugging else parent, "_ready")

	assert(parent != null, Debug.define_error("A DialogComponent must reference a parent node", self))
	assert(touch_detector != null, "Portals require touch detectors for entry validation")
	touch_detector.player_entered_area.connect(_on_player_entered)
	touch_detector_region = Global.get_collider_global_rect(touch_detector.get_collider())

	if timeline == Dialogue.TIMELINES.UNASSIGNED:
		push_warning(Debug.define_error("Dialog Components should be initiated with a boot timeline", parent))

	match trigger_mode:
		TRIGGER_MODES.TOUCH_ONLY:
			Debug.debug("Setting dialogue trigger mode to entry", self if not inherit_debugging else parent, "_ready")
		TRIGGER_MODES.CLICK_ONLY:
			Debug.debug("Setting dialogue trigger mode to click", self if not inherit_debugging else parent, "_ready")
			touch_detector.mouse_entered_area.connect(_on_mouse_entered) # only connects when click only is on
		TRIGGER_MODES.CLICK_WHILE_TOUCHING:
			Debug.debug("Setting dialogue trigger mode to click and entry", self if not inherit_debugging else parent, "_ready")

# --- Timeline Management ---
func set_timeline(new_timeline: Dialogue.TIMELINES) -> bool:
	if Dialogue.is_timeline_completed(new_timeline) and not Dialogue.is_timeline_repeatable(new_timeline):
		push_warning(Debug.define_error("Trying to assign a completed, non-repeatable timeline", parent))
		return false
	if processing:
		await processing_complete
	Debug.debug("timeline changed to %s." % [Dialogue.get_timeline_name(new_timeline)], parent, "set_timeline")
	timeline = new_timeline
	return true

# --- Trigger Handlers ---
var processing: bool = false
func _on_player_entered() -> void:
	Debug.debug("Player touched me!", self if not inherit_debugging else parent, "_on_area_entered")
	if Player.is_occupied() or processing or not Global.npc_manager.is_npc_enabled(parent):
		return
	processing_entry = true
	Debug.debug("Conditions met to attempt playing dialogue, loop beginning", self if not inherit_debugging else parent, "_on_player_entered")
	while Global.player_bubble in touch_detector.get_overlapping_areas():
		if await _try_play_dialog(timeline):
			break
			Debug.debug("Dialogue succesfully played, breaking loop", self if not inherit_debugging else parent, "_on_player_entered")
		await get_tree().process_frame
	processing_complete.emit()
	processing_entry = false


func _on_mouse_entered() -> void:
	if Player.is_occupied() or processing or not Global.npc_manager.is_npc_enabled(parent):
		return
	processing_entry = true
	Debug.debug("Conditions met to attempt playing dialogue, loop beginning", self if not inherit_debugging else parent, "_on_player_entered")
	while touch_detector_region.has_point(get_viewport().get_global_mouse_position()):
		if await _try_play_dialog(timeline):
			break
			Debug.debug("Dialogue succesfully played, breaking loop", self if not inherit_debugging else parent, "_on_player_entered")
		await get_tree().process_frame
	processing_complete.emit()
	processing_entry = false


func _try_play_dialog(_timeline: Dialogue.TIMELINES) -> bool:
	if Input.is_action_just_pressed("interact") and Global.get_vector_to_player(parent).length() < max_trigger_distance:
		if await Dialogue.start(_timeline):
			dialog_started.emit(parent)
			await Dialogic.timeline_ended
			dialog_ended.emit(parent)
			return true
	return false
