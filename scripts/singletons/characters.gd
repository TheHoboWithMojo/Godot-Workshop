extends Node2D

enum CHARACTERS {ERROR, DOC_MITCHELL, SUNNY_SMILES, CHET, RINGO, TAMMY, OLD_MAN_PETE}

@onready var characters: Dictionary = {
	CHARACTERS.DOC_MITCHELL: {
		"name": "doc_mitchell",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"style": "res://dialogic/styles/default.tres",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
	CHARACTERS.SUNNY_SMILES: {
		"name": "sunny_smiles",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
	CHARACTERS.CHET: {
		"name": "chet",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
	CHARACTERS.RINGO: {
		"name": "ringo",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
	CHARACTERS.OLD_MAN_PETE: {
		"name": "old_man_pete",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
	CHARACTERS.TAMMY: {
		"name": "tammy",
		"alive": true,
		"resource": "res://dialogic/characters/DocMitchell/doc_mitchell.dch",
		"faction": Factions.FACTIONS.GOODSPRINGS
	},
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
	if not is_character_alive(character):
		Debug.throw_error(self, "kill_character", "Character %s is already dead." % [get_character_name(character)])
	characters[character]["alive"] = value
