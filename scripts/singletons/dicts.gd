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
		"attack_speed_mult": 3.00,
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
	"heavy_handed":
		{
		"reqs": {"level": 5, "bravery": 10},
		"buffs": "melee_damage_mult + 0.05",
		},
	"experienced":
		{
		"reqs": {"level": 2, "intelligence": 5},
		"buffs": "exp_mult + 0.05",
		},
	"asshole":
		{
		"reqs": {"level": 5, "cruelty": 10},
		"buffs": "none",
		"abilities": "none" # write the function name that adds the functionality so you can call it here
		},
	"politician":
		{
		"reqs": {"level": 1, "charisma": 10},
		"buffs": "persuasion_damage + 0.05",
		"abilities": "none"
		},
}

var reload_data: Dictionary = {
	"last_level": "res://scenes/levels/level_1.tscn", # these are set to level one values by default
	"last_position": Vector2(7.0, 15.0),
	"acquired_weapons": [],
}

# FACTIONS
var factions_data: Dictionary = {
	Factions.FACTIONS.NEW_CALIFORNIA_REPUBLIC: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.CAESERS_LEGION: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.BROTHERHOOD_OF_STEEL: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.FOLLOWERS_OF_THE_APOCALYPSE: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.GREAT_KHANS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.GUN_RUNNERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.BOOMERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.ENCLAVE_REMNANTS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.WHITE_GLOVE_SOCIETY: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.OMERTAS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.CHAIRMEN: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.KINGS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.POWDER_GANGERS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.FIENDS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.VAN_GRAFFS: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.CRIMSON_CARAVAN: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.JACOBSTOWN: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.WESTSIDE_COOPERATIVE: {
		"rep": 50,
		"decisions": []
	},
	Factions.FACTIONS.BROTHERHOOD_OUTCASTS: {
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
		"faction": Factions.FACTIONS.NEW_CALIFORNIA_REPUBLIC,
		},
}

var timelines: Dictionary = {
	"opening": {
		"completed": false,
		"repeatable": false,
		"characters": [characters.steve]
	}
}
