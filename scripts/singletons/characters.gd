extends Node2D

enum CHARACTERS {UNASSIGNED, DOC_MITCHELL, SUNNY_SMILES, CHET, RINGO, TAMMY, OLD_MAN_PETE, JOE_COBB}

var characters: Dictionary = {
	CHARACTERS.DOC_MITCHELL: {
		"name": "doc_mitchell",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"style": "res://dialogic/styles/default.tres",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.SUNNY_SMILES: {
		"name": "sunny_smiles",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.CHET: {
		"name": "chet",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.RINGO: {
		"name": "ringo",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.OLD_MAN_PETE: {
		"name": "old_man_pete",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.TAMMY: {
		"name": "tammy",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS,
		"last_level": 0,
		"last_position": Vector2.ZERO
	},
	CHARACTERS.JOE_COBB:
		{
		"name": "joe_cobb",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.POWDER_GANGERS,
		"last_level": 0,
		"last_position": Vector2.ZERO
		}
}


func character_exists(nomen: String) -> bool:
	return nomen in Data.game_data["characters"].keys()


func get_character_resource(character: CHARACTERS) -> DialogicCharacter:
	return load(characters[character]["resource"])


func get_character_name(character: CHARACTERS) -> String:
	return Global.enum_to_snakecase(character, CHARACTERS)


func get_character_faction(character: CHARACTERS) -> Factions.FACTIONS:
	return characters[character]["faction"]


func is_character_alive(character: CHARACTERS) -> bool:
	return characters[character]["alive"]


func set_alive(character: CHARACTERS, value: bool) -> void:
	if Debug.throw_warning_if(not is_character_alive(character), "Character %s is already dead." % [get_character_name(character)], self):
		return
	characters[character]["alive"] = value


func set_character_last_level(character: CHARACTERS, level: Levels.LEVELS) -> void:
	characters[character]["last_level"] = level


func get_character_last_level(character: CHARACTERS) -> Levels.LEVELS:
	return characters[character]["last_level"]


func get_character_last_position(character: CHARACTERS) -> Vector2:
	return characters[character]["last_position"]


func set_character_last_position(character: CHARACTERS, vector: Vector2) -> void:
	characters[character]["last_position"] = vector
