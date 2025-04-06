extends Node2D

@onready var reference_data: Dictionary[String, Dictionary] = {
	"reload_data": reload_data,
	"stats": stats,
	"factions_data": factions_data,
	"perks": perks,
	"characters": characters,
	"timelines": timelines,
}

# PLAYER
var stats: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed": 10000.0,
		"attack_speed_mult": 1.00,
		"attack_speed": 5.0,
	},
	"health": {
		"max_health": 100.0,
		"health": 100.0,
		"health_regen": 0.05
	},
	"crit": {
		"crit_chance": 0.01,
		"crit_mult": 2.0
	},
	"exp": {
		"exp": 0.0,
		"exp_mult": 1.0
	},
	"personality": {
		"bravery": 5,
		"intelligence": 5,
		"snarkiness": 5,
		"charisma": 5,
		"cruelty": 5,
		"selflessness": 5,
		"selfishness": 5,
	},
	"accomplishments": {
		"enemies_killed": 0,
	},
	"damage":{
		"fire_damage_mult": 1.0,
		"melee_damage_mult": 1.0,
		"explosive_damage_mult": 1.0,
		"persuasion_damage": 0,
	}
}

var perks: Dictionary = {
	"Heavy Handed":
		{
		"Reqs": {"level": 5, "bravery": 10},
		"Buffs": "melee_damage_mult + 0.05",
		},
	"Experienced":
		{
		"Reqs": {"level": 2, "intelligence": 5},
		"Buffs": "exp_mult + 0.05",
		},
	"Asshole":
		{
		"Reqs": {"level": 5, "cruelty": 10},
		"Buffs": "none",
		"Abilities": "none" # write the function name that adds the functionality so you can call it here
		},
	"Politician":
		{
		"Reqs": {"level": 1, "charisma": 10},
		"Buffs": "persuasion_damage + 0.05",
		"Abilities": "none"
		},
}

var reload_data: Dictionary = {
	"last_level": "res://scenes/levels/level_1.tscn", # these are set to level one values by default
	"last_position": Vector2(7.0, 15.0),
}

# FACTIONS
var factions_data: Dictionary = {
	Factions.factions.NEW_CALIFORNIA_REPUBLIC: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.CAESERS_LEGION: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.BROTHERHOOD_OF_STEEL: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.FOLLOWERS_OF_THE_APOCALYPSE: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.GREAT_KHANS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.GUN_RUNNERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.BOOMERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.ENCLAVE_REMNANTS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.WHITE_GLOVE_SOCIETY: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.OMERTAS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.CHAIRMEN: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.KINGS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.POWDER_GANGERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.FIENDS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.VAN_GRAFFS: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.CRIMSON_CARAVAN: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.JACOBSTOWN: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.WESTSIDE_COOPERATIVE: {
		"rep": 50,
		"decisions": []
	},
	Factions.factions.BROTHERHOOD_OUTCASTS: {
		"rep": 50,
		"decisions": []
	}
}

# DATA
var spreadsheets: Dictionary[String, Dictionary] = { # dictionary for syncing csvs
	"items": {
		"id": "1J16pLFRq0sskkJiUBQhY4QvSbcZ4VGSB00Zy3yi-1Vc",
	},
	"quests": {
		"id": "1YyJAqxexIt5-x0fV528fsZG9R7tNW6V0nZjoHDgejpY",
	},
}

# Dialogue
var characters: Dictionary = {
	"steve": {
		"name": "steve",
		"alive": true,
		"resource": "res://dialogic/characters/steve.dch",
		"faction": Factions.factions.NEW_CALIFORNIA_REPUBLIC,
		},
}

var timelines: Dictionary = {
	"npc": {
		"completed": false,
		"repeatable": false,
		"characters": [characters.steve]
	}
}
