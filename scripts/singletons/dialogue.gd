extends Node
signal dialogue_started

enum TIMELINES {UNASSIGNED, YOURE_AWAKE, PICKTAGS, SUNNY_GREETING, OFF_YOU_GO}

var timelines: Dictionary = {
	TIMELINES.YOURE_AWAKE: {
		"name": "youre_awake",
		"completed": false,
		"repeatable": false,
		"characters": [Characters.CHARACTERS.DOC_MITCHELL],
		"quests": [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
		"resource": "res://dialogic/timelines/youre_awake.dtl",
	},
	TIMELINES.PICKTAGS: {
		"name": "pick_tags",
		"completed": false,
		"repeatable": false,
		"characters": [Characters.CHARACTERS.DOC_MITCHELL],
		"quests": [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
		"resource": "res://dialogic/timelines/picktags.dtl",
	},
	TIMELINES.SUNNY_GREETING: {
		"name": "sunny_greeting",
		"completed": false,
		"repeatable": false,
		"characters": [Characters.CHARACTERS.SUNNY_SMILES],
		"quests": [Quests.QUESTS.BACK_IN_THE_SADDLE],
		"resource": "res://dialogic/timelines/sunny_greeting.dtl",
	},
	TIMELINES.OFF_YOU_GO: {
		"name": "off_you_go",
		"completed": false,
		"repeatable": false,
		"characters": [Characters.CHARACTERS.SUNNY_SMILES],
		"quests": [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
		"resource": "res://dialogic/timelines/off_you_go.dtl",
	}
}

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)


func start(timeline: TIMELINES) -> bool:
	if timeline == TIMELINES.UNASSIGNED:
		push_warning(Debug.define_error("Tried to play an unassigned timeline", self))
		return false
	var timeline_path: String = timelines[timeline]["resource"]
	if is_timeline_running():
		push_warning(Debug.define_error("A timeline '%s' is already running! Cannot start the new one %s" % [Global.get_rawname(str(Dialogic.current_timeline)), get_timeline_name(timeline)], self))
		return false
	if is_timeline_completed(timeline) and not is_timeline_repeatable(timeline):
		#push_warning(Debug.define_error("The timeline %s has been played and is not repeatable" % [get_timeline_name(timeline)], self))
		return false
	Data.game_data["timelines"][str(timeline)]["completed"] = true
	Dialogic.start(timeline_path)
	if not Dialogic.current_timeline:
		await Dialogic.timeline_started
		dialogue_started.emit()
	return true


func preload_timeline(timeline: TIMELINES) -> Resource:
	return Dialogic.preload_timeline(Dialogue.timelines[timeline]["resource"])


func aggro_conversers() -> void:
	if is_timeline_running():
		var timeline_name: String = Global.get_rawname(Dialogic.current_timeline.resource_path)
		for character: Characters.CHARACTERS in timelines[timeline_name]["characters"]:
			for npc: Node2D in get_tree().get_nodes_in_group("npc"):
				if npc.name.to_lower() == Characters.get_character_name(character):
					npc.set_hostile(true)


func is_dialogue_playing() -> bool:
	return Dialogic.current_timeline != null


func is_timeline_completed(timeline: TIMELINES) -> bool:
	return Data.game_data["timelines"][str(timeline)]["completed"] == true


func is_timeline_repeatable(timeline: TIMELINES) -> bool:
	return timelines[timeline]["repeatable"] == true


func is_timeline_running() -> bool:
	return Dialogic.current_timeline != null


func get_timeline_resource(timeline: TIMELINES) -> DialogicTimeline:
	return load(timelines[timeline]["resource"])


func get_timeline_name(timeline: TIMELINES) -> String:
	return Global.enum_to_snakecase(timeline, TIMELINES)


func _on_dialogic_signal(command: String) -> void:
	if command == "aggro":
		aggro_conversers()

@onready var total_mobs: int = 0
func _on_dialogue_start() -> void:
	Global.set_paused(true)


func _on_dialogue_end() -> void:
	Global.set_paused(false)
