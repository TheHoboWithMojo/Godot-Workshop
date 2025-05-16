extends Node
signal dialogue_started

enum CHARACTERS {ERROR, DOC_MITCHELL, SUNNY_SMILES, CHET, RINGO, TAMMY, OLD_MAN_PETE}
enum TIMELINES {ERROR, YOUREAWAKE, PICKTAGS}

var characters: Dictionary = {
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

var timelines: Dictionary = {
	TIMELINES.YOUREAWAKE: {
		"name": "youre_awake",
		"completed": false,
		"repeatable": false,
		"characters": [CHARACTERS.DOC_MITCHELL],
		"resource": "res://dialogic/timelines/youreawake.dtl",
	},
	TIMELINES.PICKTAGS: {
		"name": "pick_tags",
		"completed": false,
		"repeatable": false,
		"characters": [CHARACTERS.DOC_MITCHELL],
		"resource": "res://dialogic/timelines/picktags.dtl",
	},
}

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	

func start(timeline: TIMELINES) -> bool:
	var timeline_path: String = timelines[timeline]["resource"]
	if _is_timeline_running():
		#Debug.throw_error(self, "start_dialog", "The timeline %s is already running! Cannot start a new one" % [Global.get_rawname(str(Dialogic.current_timeline))])
		return false
	if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
		Debug.throw_error(self, "start_dialog", "The timeline " + timeline_path + " has been played and is not repeatable")
		return false
	else:
		Data.game_data["timelines"][str(timeline)]["completed"] = true
		Dialogic.start(timeline_path)
		if not Dialogic.current_timeline:
			await Dialogic.timeline_started
			dialogue_started.emit()
		return true
		

func aggro_conversers() -> void:
	if _is_timeline_running():
		var timeline_name: String = Global.get_rawname(Dialogic.current_timeline.resource_path)
		for character: CHARACTERS in timelines[timeline_name]["characters"]:
			for npc: Node2D in get_tree().get_nodes_in_group("npc"):
				if npc.name.to_lower() == get_character_name(character):
					npc.master.hostile = true
					

func _is_timeline_completed(timeline: TIMELINES) -> bool:
	return Data.game_data["timelines"][str(timeline)]["completed"] == true
	

func _is_timeline_repeatable(timeline: TIMELINES) -> bool:
	return timelines[timeline]["repeatable"] == true
	

func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null
	

func character_exists(nomen: String) -> bool:
	return nomen in Data.game_data["characters"].keys()
	

func get_character(character: CHARACTERS) -> DialogicCharacter:
	return load(characters[character]["resource"])
	

func get_character_name(character: CHARACTERS) -> String:
	return Global.enum_to_snakecase(character, CHARACTERS)
	

func get_timeline(timeline: TIMELINES) -> DialogicTimeline:
	return load(timelines[timeline]["resource"])
	

func get_timeline_name(timeline: TIMELINES) -> String:
	return Global.enum_to_title(timeline, TIMELINES)
	

func _on_dialogic_signal(command: String) -> void:
	if command == "aggro":
		aggro_conversers()
		
@onready var total_mobs: int = 0
func _on_dialogue_start() -> void:
	Global.speed_mult = 0.0
	if Global.player and Global.game_manager:
		Global.player.set_physics_process(false)
		Global.player.can_shoot = false
		
		total_mobs = Global.game_manager.total_mobs # Store actual mob count
		Global.game_manager.total_mobs = Global.game_manager.MOB_CAP # Sets mob count to max to stop spawning
		
		for being: Node2D in Global.get_beings():
			being.master.vincible = false
			

func _on_dialogue_end() -> void:
	if Global.player and Global.game_manager:
		Global.player.set_physics_process(true)
		Global.player.can_shoot = true
		Global.game_manager.total_mobs = total_mobs # Restores actual mob count
		
		for being: Node2D in Global.get_beings():
			being.master.vincible = true
		
		Global.speed_mult = 1.0
