# =========================================================================
# GAME MANAGER
# Handles essential game operations (loading, saving, essential signals, tracking frames)
# =========================================================================
extends Node2D
# =========================================================================
# CONFIGURATION
# =========================================================================
@export_group("Config")
@export var active: bool = true
@export var use_save_data: bool = true
@export var autosaving_enabled: bool = true
@export var show_mouse_pos: bool = false
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var waypoint_manager: Node = $WaypointManager
@onready var quest_manager: QuestManager = $QuestManager
@onready var level_manager: LevelManager = $LevelManager
@onready var mob_manager: MobManager = $MobManager
@onready var save_manager: SaveManager = $SaveManager
@onready var is_ready_to_start: bool = false # Updated by ready_to_start signal
@onready var total_mobs: int
# =========================================================================
# SIGNALS
# =========================================================================
signal ready_to_start # Nodes read this to know when to begin processing
# =========================================================================
# CORE LIFECYCLE METHODS
# =========================================================================
func _ready() -> void:
	if not active:
		push_warning("Game Manager set to Inactive")
		queue_free()
		return
	await update_global_references()
	load_data()
	ready_up()

	if show_mouse_pos:
		add_child(load("res://scenes/tools/mouse_pos_printer.tscn").instantiate())


func _process(_delta: float) -> void:
	count_frames()
	if use_save_data and autosaving_enabled:
		autosave()
# =========================================================================
# READY FUNCTIONS
# =========================================================================
func update_global_references() -> void:
	Global.game_reloaded.emit()
	await get_tree().process_frame


func load_data() -> void:
	if not use_save_data:
		save_manager.clear_data()
		if save_manager.is_data_cleared != true:
			await save_manager.data_cleared
	save_manager.load_game_data()
	if not save_manager.is_loading_complete:
		await save_manager.loading_complete


func ready_up() -> void:
	if not use_save_data: # load doc mitchells house if saving is disabled
		level_manager.set_current_level(Levels.LEVELS.DOC_MITCHELLS_HOUSE)
	is_ready_to_start = true
	ready_to_start.emit()
	await Dialogue.start(Dialogue.TIMELINES.YOURE_AWAKE)
	level_manager.new_level_loaded.emit(await level_manager.get_current_level_node()) # refresh an scripts that rely on the new level signal on boot

# =========================================================================
# PROCESS FUNCTIONS
# =========================================================================
func count_frames() -> void:
	Global.frames += 1
	if Global.frames >= 100:
		Global.frames = 0


var _currently_autosaving: bool = false
func autosave() -> void:
	if autosaving_enabled:
		if not _currently_autosaving:
			_currently_autosaving = true
			await Global.delay(self, 10)
			Global.speed_mult = 0.0
			save_manager.data()
			Global.speed_mult = 1.0
