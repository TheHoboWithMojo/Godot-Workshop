extends Node2D

@onready var reference_data: Dictionary[String, Dictionary] = {
	"stats": stats,
	"factions": factions,
	"perks": perks,
	"reload_data": reload_data,
}
# PLAYER
var stats: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed": 10000.0,
		"attack_speed_mult": 1.00,
		"attack_speed": 2.0,
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
var factions: Dictionary = {
	"New California Republic": {
		"rep": 50,
		"decisions": []
	},
	"Caesar's Legion": {
		"rep": 50,
		"decisions": []
	},
	"Brotherhood of Steel": {
		"rep": 50,
		"decisions": []
	},
	"Followers of the Apocalypse": {
		"rep": 50,
		"decisions": []
	},
	"Great Khans": {
		"rep": 50,
		"decisions": []
	},
	"Gun Runners": {
		"rep": 50,
		"decisions": []
	},
	"Boomers": {
		"rep": 50,
		"decisions": []
	},
	"Enclave Remnants": {
		"rep": 50,
		"decisions": []
	},
	"White Glove Society": {
		"rep": 50,
		"decisions": []
	},
	"Omertas": {
		"rep": 50,
		"decisions": []
	},
	"Chairmen": {
		"rep": 50,
		"decisions": []
	},
	"Kings": {
		"rep": 50,
		"decisions": []
	},
	"Powder Gangers": {
		"rep": 50,
		"decisions": []
	},
	"Fiends": {
		"rep": 50,
		"decisions": []
	},
	"Van Graffs": {
		"rep": 50,
		"decisions": []
	},
	"Crimson Caravan": {
		"rep": 50,
		"decisions": []
	},
	"Jacobstown": {
		"rep": 50,
		"decisions": []
	},
	"Westside Cooperative": {
		"rep": 50,
		"decisions": []
	},
	"Brotherhood Outcasts": {
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
