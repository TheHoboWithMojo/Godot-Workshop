# Stores universal reference to player and camera
# Stores functions to manipulate player stats
# Stores globally editable/referencable variables/constants (frames, float_limit, speed_mult, etc.)
extends Node2D

# Constants
const FLOAT_LIMIT: float = 2147483647.0
const PLAYER_PATH: String = "/root/Game/Player"
const PLAYER_CAMERA_PATH: = "/root/Game/Player/PlayerCamera"
const GAME_MANAGER_PATH: = "/root/Game"

# Signals
signal game_reloaded # Receives this signal when game_manager's ready runs

# Global Variables
@onready var frames: int = 0
@onready var speed_mult: float = 1.0
@onready var player: CharacterBody2D = get_node(PLAYER_PATH)
@onready var player_camera: Camera2D = get_node(PLAYER_CAMERA_PATH)
@onready var game_manager: Node2D = get_node(GAME_MANAGER_PATH)

# HERE TO EDIT, MANUALLY SAVE AS REF AFTER EDITING USING DATA.SAVE_JSON()
var player_stats_ref: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed": 50
	},
	"health": {
		"health": 100.0,
		"health_regen": 0.05
	},
	"crit": {
		"crit_chance": 0.01,
		"crit_mult": 2.0
	},
	"personality": {
		"recklessness": 5,
		"bravery": 5,
		"intelligence": 5,
		"snarkiness": 5,
		"charisma": 5,
	}
}

# Stat Constraints
var stat_constraints: Dictionary = {
	"speed": {
		"speed_mult": {"min": 1.0, "max": 5.0},
		"speed_base": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"health": {
		"health": {"min": 0.0, "max": FLOAT_LIMIT},
		"health_regen": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"crit": {
		"crit_chance": {"min": 0.0, "max": 1.0},
		"crit_mult": {"min": 0.0, "max": FLOAT_LIMIT}
	}
}

# Timelines Dictionary
var Timelines: Dictionary = {
	"npc": {
		"completed": false,
		"repeatable": false
	}
}

# =============================================
# PUBLIC FUNCTIONS
# =============================================

func _ready() -> void:
	game_reloaded.connect(_on_game_reloaded)
	# Initialize game data with a copy of our template if not already present
	if not "player stats" in Data.game_data:
		Data.game_data["player stats"] = player_stats_ref.duplicate(true)

func _on_game_reloaded() -> void: # Reset assignments if scene is reset
	player = get_node(PLAYER_PATH)
	player_camera = get_node(PLAYER_CAMERA_PATH)
	game_manager = get_node(GAME_MANAGER_PATH)
	print("paths reloaded!")
	
# ESSENTIAL, UBIQUITOUS FUNCTION, CHECKS IF NODE IS SET TO ACTIVE AND WAITS FOR DATA TO BE LOADED
func active_and_ready(self_node: Node, active: bool):
	if active: # Check is node is active and if the player exists
		if not Global.player:
			await Global.game_reloaded # if theres no player wait for references to update
			
		if Global.game_manager.start_ready != true:
			await Global.game_manager.ready_to_start
	else:
		self_node.queue_free()

func delay(self_node: Node, seconds: float):
	await self_node.get_tree().create_timer(seconds).timeout

func player_get_stat(stat: String) -> float:
	var stat_category: String = _get_stat_category(stat)
	return Data.game_data["player stats"][stat_category][stat] if stat_category else 0.0

func damage_player(damage: float):
	player_change_stat("health - %s" % [damage])
	player.player_damaged.emit()
	
func heal_player(heal: float):
	player_change_stat("health + %s" % [heal])

func player_add_perk(perk_name: String) -> void:
	if not Data.game_data["perks"].has(perk_name):
		print("Could not find '", perk_name, "' in perks data")
		Debug.print_player_perks()
		return
		
	if _update_toggle_buff(perk_name, Data.game_data["perks"]):
		print(perk_name, " boolean buff was added!")
	else:
		print(perk_name, " boolean buff is already active.")

func player_add_trait(trait_name: String) -> void:
	if not Data.game_data["traits"].has(trait_name):
		Debug.throw_error(self, "player_add_trait", trait_name + " not found in traits")
		Debug.print_player_traits()
		return
		
	if _update_toggle_buff(trait_name, Data.game_data["traits"]):
		print(trait_name, " boolean buff was added!")
	else:
		print(trait_name, " boolean buff is already active.")

func start_dialog(timeline: String) -> void:
	if _is_timeline_running():
		Debug.throw_error(self, "start_dialog", "A timeline is already running! Cannot start a new one")
		return
	if timeline in Timelines:
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " has been played and is not repeatable")
			return
		
		Timelines[timeline]["completed"] = true
		Dialogic.start(timeline)
	else:
		Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " does not exist")

func get_vector_to_player(self_node: Node2D) -> Vector2:
	if player:
		return player.global_position - self_node.global_position
	else:
		Debug.throw_error(self, "get_vector_to_player", "Player path has changed")
		return Vector2.ZERO
		
func get_vector_to_player_camera(self_node: Node2D) -> Vector2:
	if player_camera:
		return player_camera.global_position - self_node.global_position
	else:
		Debug.throw_error(self, "get_vector_to_player_camera", "Player camera path has changed")
		return Vector2.ZERO
		
func player_change_stat(buff_string: String, debug: bool = false) -> void:
	var buffs: Array = _parse_buff_string(buff_string)
	for buff in buffs:
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: float = buff[2]
		var stat_category: String = _get_stat_category(stat)
		
		if stat_category.is_empty():
			continue
			
		var original_stat_value: float = Data.game_data["player stats"][stat_category][stat]
		
		var new_stat_value: float = _get_updated_stat(stat_category, stat, operator, value)
		
		if debug:
				_print_stat_change(stat, original_stat_value, new_stat_value)
				
# =============================================
# PRIVATE HELPER FUNCTIONS
# =============================================

# Parses a buff string, i.e. "stat", "operator", value and directly modifies the game data dict

func _is_valid_buff_string(string: String) -> bool:
	var buffs: Array = _split_buff_string(string)
	for buff in buffs:
		if buff.size() != 3:
			Debug.throw_error(self, "_is_valid_buff_string", "Buff does not contain the required word amount (3)", buff)
			return false
		
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: String = buff[2]
		if not _is_valid_stat(stat) or not _is_valid_operator(operator) or not value.is_valid_float():
			Debug.throw_error(self, "_is_valid_buff_string", "Invalid buff format", buff)
			return false
	
	return true

func _is_valid_stat(stat: String) -> bool:
	for stat_category in Data.game_data["player stats"].values():
		if stat in stat_category:
			return true
	return false

func _is_valid_operator(_char: String) -> bool:
	return _char in ["*", "-", "+", "/", "="]

func _split_buff_string(buff_string: String) -> Array:
	var buffs: Array = []
	for buff in buff_string.split(";", false):
		var split_buff = buff.strip_edges().split(" ", false)
		if split_buff.size() == 3:
			buffs.append(Array(split_buff))
	return buffs

func _parse_buff_string(buff_string: String) -> Array:
	if _is_valid_buff_string(buff_string):
		var buffs: Array = _split_buff_string(buff_string)
		for buff in buffs:
			buff[2] = buff[2].to_float()
		return buffs
	return []

func _print_stat_change(stat: String, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		stat, original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])

func _get_stat_category(stat: String) -> String:
	for stat_category in Data.game_data["player stats"].keys():
		if stat in Data.game_data["player stats"][stat_category]:
			return stat_category
	return ""

func _get_stat_constraints(stat_category: String, stat: String) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": FLOAT_LIMIT })

func _get_updated_stat(stat_category: String, stat: String, operator: String, value: float) -> float:
	if player:
		if stat == "health" and player.damagable == false: # IV frames implementation
			return Data.game_data["player stats"][stat_category][stat]
			
		var current_value: float = Data.game_data["player stats"][stat_category][stat]
		match operator:
			"*": current_value *= value
			"-": current_value -= value
			"+": current_value += value
			"=": current_value = value
			"/": 
				if value != 0:
					current_value /= value
				else:
					Debug.throw_error(self, "_get_updated_stat", "Cannot divide by 0")
		var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
		var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
		Data.game_data["player stats"][stat_category][stat] = constrained_value
		
		return constrained_value
	return 0.0

func _is_toggle_buff_active(buff_dict: Dictionary) -> bool:
	return buff_dict.get("has") == "true"

func _update_toggle_buff(buff_name: String, buff_data: Dictionary) -> bool:
	if not buff_data.has(buff_name):
		return false
		
	var buff = buff_data[buff_name]
	
	if _is_toggle_buff_active(buff):
		return false
	
	buff["has"] = "true"
	player_change_stat(buff.get("buffs", ""))
	return true

func _is_timeline_completed(timeline: String) -> bool:
	return Timelines[timeline]["completed"] == true

func _is_timeline_repeatable(timeline: String) -> bool:
	return Timelines[timeline]["repeatable"] == true

func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null
