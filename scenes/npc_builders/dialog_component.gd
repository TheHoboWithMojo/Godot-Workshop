@icon("res://assets/Icons/16x16/dialogue.png")
extends Node
class_name DialogComponent

# --- Exported Variables ---
@export var parent: Node2D
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@export var timeline: Dialogue.TIMELINES
@export var max_trigger_distance: float = 1000.0

@export_group("Trigger Config")
@export var trigger_mode: TRIGGER_MODES = TRIGGER_MODES.CLICK_AND_ENTRY
@export var click_detector: ClickDetector
@export var touch_detector: TouchDetector

# --- Enums ---
enum TRIGGER_MODES { CLICK, ENTRY, CLICK_AND_ENTRY, CLICK_OR_ENTRY }

# --- Internal State ---
var processing_press: bool = false
var processing_entry: bool = false

# --- Signals ---
signal player_touched_me(self_node: Node)
signal dialog_started(self_node: Node)
signal dialog_ended(self_node: Node)

# --- Setup ---
func _ready() -> void:
	assert(parent != null, Debug.define_error("A DialogComponent must reference a parent node", self))
	await parent.tree_entered

	Debug.throw_warning_if(timeline == Dialogue.TIMELINES.UNASSIGNED, "Dialog Components should be initiated with a boot timeline", parent)

	match trigger_mode:
		TRIGGER_MODES.CLICK:
			assert(click_detector != null, Debug.define_error("Trigger mode CLICK requires a ClickDetector", parent))
			click_detector.pressed.connect(_on_button_pressed)

		TRIGGER_MODES.ENTRY:
			assert(touch_detector != null, Debug.define_error("Trigger mode ENTRY requires a TouchDetector", parent))
			touch_detector.area_entered.connect(_on_area_entered)

		TRIGGER_MODES.CLICK_AND_ENTRY:
			assert(click_detector != null and touch_detector != null, Debug.define_error("Trigger mode CLICK_AND_ENTRY requires both ClickDetector and TouchDetector", parent))
			click_detector.pressed.connect(_on_button_pressed)
			touch_detector.set_ignored_menu(click_detector)

		TRIGGER_MODES.CLICK_OR_ENTRY:
			assert(click_detector != null and touch_detector != null, Debug.define_error("Trigger mode CLICK_OR_ENTRY requires both ClickDetector and TouchDetector", parent))
			click_detector.pressed.connect(_on_button_pressed)
			touch_detector.area_entered.connect(_on_area_entered)
			touch_detector.set_ignored_menu(click_detector)

	if parent is NPC:
		await parent.await_name_changed()

	if inherit_debugging:
		debugging = parent.debugging

# --- Timeline Management ---
func set_timeline(new_timeline: Dialogue.TIMELINES) -> bool:
	if Dialogue.is_timeline_completed(new_timeline) and not Dialogue.is_timeline_repeatable(new_timeline):
		Debug.throw_warning("Trying to assign a completed, non-repeatable timeline", parent)
		return false

	Debug.debug("timeline changed to %s." % [Dialogue.get_timeline_name(new_timeline)], parent, "set_timeline")
	timeline = new_timeline
	return true

# --- Trigger Handlers ---
func _on_button_pressed() -> void:
	if processing_press or Player.is_occupied():
		return
	processing_press = true
	player_touched_me.emit(self)
	await _try_play_dialog()
	processing_press = false

func _on_area_entered(area: Area2D) -> void:
	if area != Global.player_bubble or Player.is_occupied() or processing_entry:
		return
	processing_entry = true
	player_touched_me.emit(self)
	await _try_play_dialog()
	processing_entry = false

# --- Dialog Playback ---
func _try_play_dialog() -> void:
	if Global.get_vector_to_player(parent).length() > max_trigger_distance:
		return

	var can_play: bool = false
	match trigger_mode:
		TRIGGER_MODES.CLICK, TRIGGER_MODES.CLICK_OR_ENTRY:
			can_play = true
		TRIGGER_MODES.ENTRY, TRIGGER_MODES.CLICK_AND_ENTRY:
			can_play = Global.player_bubble in touch_detector.get_overlapping_areas()

	if can_play:
		if await Dialogue.start(timeline):
			dialog_started.emit(self)
			await Dialogic.timeline_ended
			dialog_ended.emit(self)
