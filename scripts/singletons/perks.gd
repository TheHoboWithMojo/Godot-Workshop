extends Node

enum PERKS {
	HEAVY_HANDED,
	EXPERIENCED,
	ASSHOLE,
	POLITICIAN
}

enum PROPERTIES {REQUIREMENTS, BUFFS, REVERSIBLE, ACTIVE}


var perks_dict: Dictionary = {
	PERKS.HEAVY_HANDED: {
		PROPERTIES.REQUIREMENTS: {"level": 5, "bravery": 10},
		PROPERTIES.BUFFS: {Stats.STATS.MELEE_DAMAGE_MULT: 0.05},
		PROPERTIES.REVERSIBLE: false,
		PROPERTIES.ACTIVE: false,
	},
	PERKS.EXPERIENCED: {
		PROPERTIES.REQUIREMENTS: {"level": 2, "intelligence": 5},
		PROPERTIES.BUFFS: {Stats.STATS.EXP_MULT: 0.05},
		PROPERTIES.REVERSIBLE: false,
		PROPERTIES.ACTIVE: false,
	},
	PERKS.ASSHOLE: {
		PROPERTIES.REQUIREMENTS: {"level": 5, "cruelty": 10},
		PROPERTIES.BUFFS: {},
		PROPERTIES.REVERSIBLE: false,
		PROPERTIES.ACTIVE: false,
	},
	PERKS.POLITICIAN: {
		PROPERTIES.REQUIREMENTS: {"level": 1, "charisma": 10},
		PROPERTIES.BUFFS: {Stats.STATS.PERSUASION_DAMAGE: 0.05},
		PROPERTIES.REVERSIBLE: false,
		PROPERTIES.ACTIVE: false,
	},
}

func set_perk_active(perk: PERKS, value: bool, _perks_dict: Dictionary) -> bool:
	if is_perk_active(perk, _perks_dict) and not is_perk_reversible(perk):
		return false
	_perks_dict[perk][PROPERTIES.ACTIVE] = value
	return true


func is_perk_active(perk: PERKS, _perks_dict: Dictionary) -> bool:
	return _perks_dict[perk][PROPERTIES.ACTIVE] == true


func is_perk_reversible(perk: PERKS) -> bool:
	return perks_dict[perk][PROPERTIES.REVERSIBLE] == true


func get_perk_name(perk: PERKS) -> String:
	return Global.enum_to_title(perk, PERKS)
