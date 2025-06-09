extends Node

enum CHARACTERS { UNASSIGNED, DOC_MITCHELL, SUNNY_SMILES, CHET, RINGO, TAMMY, OLD_MAN_PETE, JOE_COBB, VICTOR }
enum PROPERTIES { ALIVE, RESOURCE, STYLE, FACTION, LAST_LEVEL, DEFAULT_LEVEL, LAST_POSITION, SCENE_PATH }

var characters_dict: Dictionary = {
	CHARACTERS.DOC_MITCHELL: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.STYLE: "res://dialogic/styles/default.tres",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.DOC_MITCHELLS_HOUSE,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/DocMitchell/doc_mitchell.tscn",
	},
	CHARACTERS.SUNNY_SMILES: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.PROSPECTORS_SALOON,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/SunnySmiles/sunny_smiles.tscn",
	},
	CHARACTERS.CHET: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/Chet/chet.tscn",
	},
	CHARACTERS.RINGO: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/Ringo/ringo.tscn",
	},
	CHARACTERS.OLD_MAN_PETE: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/OldManPete/old_man_pete.tscn",
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.GOODSPRINGS,
	},
	CHARACTERS.TAMMY: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.GOODSPRINGS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.PROSPECTORS_SALOON,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/Tammy/tammy.tscn",
	},
	CHARACTERS.JOE_COBB: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.POWDER_GANGERS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.GOODSPRINGS,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/JoeCobb/joe_cobb.tscn",
	},
	CHARACTERS.VICTOR: {
		PROPERTIES.ALIVE: true,
		PROPERTIES.RESOURCE: "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		PROPERTIES.FACTION: Factions.FACTIONS.POWDER_GANGERS,
		PROPERTIES.LAST_LEVEL: Levels.LEVELS.UNASSIGNED,
		PROPERTIES.DEFAULT_LEVEL: Levels.LEVELS.GOODSPRINGS,
		PROPERTIES.LAST_POSITION: Vector2.ZERO,
		PROPERTIES.SCENE_PATH: "res://dialogic/characters/Victor/victor.tscn",
	},
}

func get_character_enum_from_scene_path(path: String) -> CHARACTERS:
	for character: CHARACTERS in characters_dict:
		if characters_dict[character][PROPERTIES.SCENE_PATH] == path:
			return character
	push_error(Debug.define_error("Path %s does not exist in the global characters_dict" % [path], self))
	return CHARACTERS.UNASSIGNED


func get_character_resource(character: CHARACTERS) -> DialogicCharacter:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to access resource of unassigned character", self))
		return null
	return load(characters_dict[character][PROPERTIES.RESOURCE])


func get_character_instantiated_scene(character: CHARACTERS) -> NPC:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to instantiate unassigned character", self))
		return null
	return load(characters_dict[character][PROPERTIES.SCENE_PATH]).instantiate() as NPC


func get_character_name(character: CHARACTERS) -> String:
	return Global.enum_to_snakecase(character, CHARACTERS)


func get_character_faction(character: CHARACTERS) -> Factions.FACTIONS:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to access faction of unassigned character", self))
		return Factions.FACTIONS.UNASSIGNED
	return characters_dict[character][PROPERTIES.FACTION]


func is_character_alive(character: CHARACTERS) -> bool:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to check alive status of unassigned character", self))
		return false
	return characters_dict[character][PROPERTIES.ALIVE]


func set_alive(character: CHARACTERS, value: bool) -> bool:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to set alive on unassigned character", self))
		return false
	if not is_character_alive(character):
		push_warning(Debug.define_error("Trying to set alive to the dead character %s" % [get_character_name(character)], self))
		return false
	characters_dict[character][PROPERTIES.ALIVE] = value
	return true


func set_character_last_level(character: CHARACTERS, level: Levels.LEVELS) -> bool:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to set last level on unassigned character", self))
		return false
	if level == Levels.LEVELS.UNASSIGNED:
		push_warning(Debug.define_error("Trying to set character %s's last level to unassigned" % [get_character_name(character)], self))
		return false
	characters_dict[character][PROPERTIES.LAST_LEVEL] = level
	return true


func get_character_last_level(character: CHARACTERS) -> Levels.LEVELS:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to access last level of unassigned character", self))
		return Levels.LEVELS.UNASSIGNED
	return characters_dict[character][PROPERTIES.LAST_LEVEL]


func set_character_default_level(character: CHARACTERS, level: Levels.LEVELS) -> bool:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to set default level of unassigned character", self))
		return false
	if level == Levels.LEVELS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to set default level of unassigned character", self))
		return false
	characters_dict[character][PROPERTIES.DEFAULT_LEVEL] = level
	return true


func get_character_default_level(character: CHARACTERS) -> Levels.LEVELS:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to get default level of unassigned character", self))
		return Levels.LEVELS.UNASSIGNED
	return characters_dict[character][PROPERTIES.DEFAULT_LEVEL]


func get_character_last_position(character: CHARACTERS) -> Vector2:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to get last position of unassigned character", self))
		return Vector2.ZERO
	return characters_dict[character][PROPERTIES.LAST_POSITION]


func set_character_last_position(character: CHARACTERS, vector: Vector2) -> bool:
	if character == CHARACTERS.UNASSIGNED:
		push_warning(Debug.define_error("Tried to set last position of unassigned character", self))
		return false
	characters_dict[character][PROPERTIES.LAST_POSITION] = vector
	return true
