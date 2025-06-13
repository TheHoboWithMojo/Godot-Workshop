@icon("res://assets/Icons/16x16/disk.png")
class_name SaveManager extends Node
@export var debugging: bool = false

# ----- Variables -----
var is_loading_complete: bool = false
var is_data_cleared: bool = false

# ----- Signals -----
signal data_cleared
signal loading_complete
signal saving_started
signal saving_complete

@onready var reference_data: Dictionary[String, Dictionary] = {
	"reload_data": reload_data,
	"characters": Characters.characters_dict,
	"stats": Player.stats,
	"factions": Factions.factions_data,
	"perks": Player.perks,
	"timelines": Dialogue.timelines,
	"quests": Quests.quests
}

var reload_data: Dictionary = {
	"last_level": Levels.LEVELS.DOC_MITCHELLS_HOUSE,
	"last_position": Vector2(0, 0),
	"acquired_weapons": [],
}

var spreadsheets: Dictionary[String, Dictionary] = {
	"items": {
		"id": "1J16pLFRq0sskkJiUBQhY4QvSbcZ4VGSB00Zy3yi-1Vc",
	},
	"quests": {
		"id": "1YyJAqxexIt5-x0fV528fsZG9R7tNW6V0nZjoHDgejpY",
	},
}

# ----- Initialization -----
func load_game_data() -> void:
	Debug.debug("Loading game data...", self, "load_game_data")
	_load_static_data()
	_load_dynamic_data()
	_process_reload_data()
	_convert_faction_keys()
	_ensure_player_health()

	Debug.debug("Game data loaded...", self, "load_game_data")
	is_loading_complete = true
	loading_complete.emit()

func _load_static_data() -> void:
	Data.game_data["items"] = Data.load_json_file(Data.get_current_path("items").replace("_current", ""))

func _load_dynamic_data() -> void:
	for data_name: String in reference_data.keys():
		var current_data_path: String = Data.get_current_path(data_name)
		var backup_data_path: String = Data.get_backup_path(data_name)

		var current_data_str: String = FileAccess.get_file_as_string(current_data_path)
		var backup_data_str: String = FileAccess.get_file_as_string(backup_data_path)
		var current_data: Dictionary = JSON.parse_string(current_data_str)
		var backup_data: Dictionary = JSON.parse_string(backup_data_str)

		if current_data == null or current_data.is_empty():
			push_error(Debug.define_error("Current data for %s is invalid or empty" % data_name, self))

			if backup_data != null and not backup_data.is_empty():
				Debug.debug("Restoring from backup for %s" % data_name, self, "_load_dynamic_data")
				Data.game_data[data_name] = backup_data
				Data.save_json(backup_data, current_data_path)
				continue

			Debug.debug("Using default data for %s" % data_name, self, "_load_dynamic_data")
			Data.game_data[data_name] = reference_data[data_name].duplicate(true)
			Data.save_json(Data.game_data[data_name], current_data_path)
			Data.save_json(Data.game_data[data_name], backup_data_path)
			continue

		Data.game_data[data_name] = current_data
		if current_data_str != backup_data_str:
			Debug.debug("Updating backup for %s" % data_name, self, "_load_dynamic_data")
			Data.save_json(current_data, backup_data_path)

func _process_reload_data() -> void:
	if not Data.game_data.has("reload_data"):
		return

	var _reload_data: Dictionary = Data.game_data["reload_data"]
	var _character_data: Dictionary = Data.game_data["characters"]

	if _reload_data.has("last_position"):
		Global.player.global_position = Global.string_to_vector2(_reload_data["last_position"])

	if _reload_data.has("acquired_weapons"):
		for weapon_scene_path: String in _reload_data["acquired_weapons"]:
			Global.player.projectiles.append(load(weapon_scene_path))
		if Global.player.projectiles:
			Global.player.current_projectile = Global.player.projectiles[0]

	if _reload_data.has("last_level"):
		Global.level_manager.current_level = load(Levels.get_level_path(_reload_data["last_level"])).instantiate()

	for character: String in _character_data:
		_character_data[str(character)][str(Characters.PROPERTIES.LAST_POSITION)] = Global.string_to_vector2(_character_data[str(character)][str(Characters.PROPERTIES.LAST_POSITION)])

func _convert_faction_keys() -> void:
	if not Data.game_data.has("factions_data"):
		return

	var factions_copy: Dictionary = Data.game_data["factions_data"].duplicate()
	Data.game_data["factions_data"].clear()
	for faction_number: String in factions_copy.keys():
		Data.game_data["factions_data"][int(faction_number)] = factions_copy[faction_number]

func _ensure_player_health() -> void:
	if Player.get_stat(Player.STATS.HEALTH) == 0:
		Player.set_stat(Player.STATS.HEALTH, 100.0)

# ----- Data Backup And Clearing -----
func verify_data_integrity() -> bool:
	var all_valid: bool = true

	for data_name: String in reference_data.keys():
		var current_path: String = Data.get_current_path(data_name)
		var backup_path: String = Data.get_backup_path(data_name)

		if not FileAccess.file_exists(current_path) or not FileAccess.file_exists(backup_path):
			push_error(Debug.define_error("Missing data file for: %s" % [data_name], self))
			all_valid = false
			continue

		var current_data: Dictionary = Data.load_json_file(current_path)
		var backup_data: Dictionary = Data.load_json_file(backup_path)

		if current_data.is_empty() and not Data.game_data[data_name].is_empty():
			push_error(Debug.define_error("Current data file is empty for: %s" % data_name, self))
			all_valid = false

		if backup_data.is_empty() and not Data.game_data[data_name].is_empty():
			push_error(Debug.define_error("Backup data file is empty for: %s" % data_name, self))
			all_valid = false

	return all_valid

func save() -> void:
	saving_started.emit()
	_save_data_with_backup("quests")

	for data_name: String in reference_data.keys():
		_save_data_with_backup(data_name)

	var is_valid: bool = verify_data_integrity()
	if is_valid:
		Debug.debug("All data saved successfully and verified.", self, "save")
	else:
		push_warning(Debug.define_error("Some data may not have been saved correctly!", self))

	saving_complete.emit()

func _save_data_with_backup(data_name: String) -> void:
	var current_data_path: String = Data.get_current_path(data_name)
	var backup_data_path: String = Data.get_backup_path(data_name)
	var temp_data_path: String = current_data_path.replace("_current", "_temp")

	var new_data: Dictionary = Data.game_data[data_name]
	var success_temp_save: bool = Data.save_json(new_data, temp_data_path)
	if not success_temp_save:
		push_error(Debug.define_error("Failed to create temporary file for: %s" % data_name, self))
		return

	var temp_data: Dictionary = Data.load_json_file(temp_data_path)
	if temp_data.is_empty() and not new_data.is_empty():
		push_error(Debug.define_error("Temp file verification failed for: %s" % data_name, self))
		return

	if FileAccess.file_exists(current_data_path):
		var current_data: Dictionary = Data.load_json_file(current_data_path)
		if not current_data.is_empty():
			var success_backup: bool = Data.save_json(current_data, backup_data_path)
			if not success_backup:
				push_error(Debug.define_error("Failed to create backup for: %s" % data_name, self))
				return

	var success_current: bool = Data.save_json(new_data, current_data_path)
	if not success_current:
		push_error(Debug.define_error("Failed to save current data for: %s" % data_name, self))
		return

	var cleanup_dir: DirAccess = DirAccess.open("res://data/")
	if cleanup_dir:
		cleanup_dir.remove(temp_data_path)

func clear_data() -> void:
	for data_name: String in reference_data.keys():
		var current_path: String = Data.get_current_path(data_name)
		var backup_path: String = current_path.replace("_current", "_backup")

		Data.save_json(reference_data[data_name], current_path)
		Data.save_json(reference_data[data_name], backup_path)
		Data.game_data[data_name] = reference_data[data_name].duplicate(true)

	Debug.debug("All data have been reset to defaults.", self, "clear_data")

	is_data_cleared = true
	data_cleared.emit()
