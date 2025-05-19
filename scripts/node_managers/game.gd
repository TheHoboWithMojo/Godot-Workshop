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
@export var track_frames: bool = true
@export var use_save_data: bool = true
@export var autosaving_enabled: bool = true
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var waypoint_manager: Node = $WaypointManager
@onready var quest_manager: Node = $QuestManager
@onready var level_manager: Node = $LevelManager
@onready var mob_manager: Node = $MobManager
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
		queue_free()
		return
	update_global_references()
	boot_dialogic()
	load_data()
	ready_up()


func _process(_delta: float) -> void:
	if track_frames:
		count_frames()
	if use_save_data and autosaving_enabled:
		autosave()
# =========================================================================
# READY FUNCTIONS
# =========================================================================
func update_global_references() -> void:
	Global.game_reloaded.emit()


func boot_dialogic() -> void:
	pass

func load_data() -> void:
	if not use_save_data:
		Data.clear_data()
		if Data.is_data_cleared != true:
			await Data.data_cleared
	Data.load_game_data()
	if not Data.is_data_loaded:
		await Data.data_loaded


func ready_up() -> void:
	if not use_save_data: # load doc mitchells house if saving is disabled
		level_manager.set_current_level(load(Levels.get_level_path(Levels.LEVELS.DOC_MITCHELLS_HOUSE)).instantiate())
	if not level_manager.is_level_loaded():
		await level_manager.level_loaded

	is_ready_to_start = true
	ready_to_start.emit()
	await Dialogue.start(Dialogue.TIMELINES.YOURE_AWAKE)

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
			Data.save_data_changes()
			Global.speed_mult = 1.0
