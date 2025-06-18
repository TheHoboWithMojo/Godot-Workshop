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
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var quest_manager: QuestManager = $QuestManager
@onready var level_manager: LevelManager = $LevelManager
@onready var mob_manager: MobManager = $MobManager
@onready var save_manager: SaveManager = $SaveManager
var total_mobs: int
# =========================================================================
# SIGNALS
# =========================================================================
signal ready_finished
# =========================================================================
# CORE LIFECYCLE METHODS
# =========================================================================
func _ready() -> void:
	if not active:
		push_warning("Game Manager set to Inactive")
		queue_free()
		return
	await update_global_references()
	await load_data()
	ready_up()


func _process(_delta: float) -> void:
	count_frames()
# =========================================================================
# READY FUNCTIONS
# =========================================================================
func update_global_references() -> void:
	Global.game_reloaded.emit()
	await get_tree().process_frame


func load_data() -> void:
	if not save_manager.use_save_data:
		save_manager.clear_data()
		if save_manager.is_data_cleared != true:
			await save_manager.data_cleared
	save_manager.load_game_data()
	if not save_manager.is_loading_finished:
		await save_manager.loading_finished


func ready_up() -> void:
	ready_finished.emit()
	level_manager.set_current_level(int(Data.game_data[Data.PROPERTIES.RELOAD_DATA]["last_level"]))

# =========================================================================
# PROCESS FUNCTIONS
# =========================================================================
func count_frames() -> void:
	Global.frames += 1
	if Global.frames >= 100:
		Global.frames = 0
