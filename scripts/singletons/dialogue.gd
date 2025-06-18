extends Node
signal dialogue_started

enum TIMELINES {UNASSIGNED, YOURE_AWAKE, PICKTAGS, SUNNY_GREETING, OFF_YOU_GO, SHOT_BOTTLES, CLEARED_FIRST_WELL_GECKOS}
enum PROPERTIES {FINISHED, REPEATABLE, CHARACTERS, QUESTS}

const resource_path: String = "res://dialogic/timelines/"

var timelines_dict: Dictionary = {
	TIMELINES.YOURE_AWAKE: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.DOC_MITCHELL],
		PROPERTIES.QUESTS: [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
	},
	TIMELINES.PICKTAGS: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.DOC_MITCHELL],
		PROPERTIES.QUESTS: [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
	},
	TIMELINES.SUNNY_GREETING: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.SUNNY_SMILES],
		PROPERTIES.QUESTS: [Quests.QUESTS.BACK_IN_THE_SADDLE],
	},
	TIMELINES.OFF_YOU_GO: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.SUNNY_SMILES],
		PROPERTIES.QUESTS: [Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD],
	},
	TIMELINES.SHOT_BOTTLES: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.SUNNY_SMILES],
		PROPERTIES.QUESTS: [Quests.QUESTS.BACK_IN_THE_SADDLE],
	},
	TIMELINES.CLEARED_FIRST_WELL_GECKOS: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.REPEATABLE: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.SUNNY_SMILES],
		PROPERTIES.QUESTS: [Quests.QUESTS.BACK_IN_THE_SADDLE],
	},
}

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)


func start(timeline: TIMELINES) -> bool:
	if timeline == TIMELINES.UNASSIGNED:
		push_warning(Debug.define_error("Tried to play an unassigned timeline", self))
		return false
	if is_timeline_running():
		push_warning(Debug.define_error("A timeline '%s' is already running! Cannot start the new one %s" % [Global.get_rawname(str(Dialogic.current_timeline)), get_timeline_name(timeline)], self))
		return false
	if is_timeline_finished(timeline) and not is_timeline_repeatable(timeline):
		#push_warning(Debug.define_error("The timeline %s has been played and is not repeatable" % [get_timeline_name(timeline)], self))
		return false
	Data.game_data[Data.PROPERTIES.TIMELINES][timeline][PROPERTIES.FINISHED] = true
	Dialogic.start(get_timeline_resource(timeline))
	dialogue_started.emit()
	return true


func preload_timeline(timeline: TIMELINES) -> Resource:
	return Dialogic.preload_timeline(get_timeline_resource(timeline))


func aggro_conversers() -> void:
	for npc: NPC in get_npcs_in_current_timeline():
		npc.set_hostile(true)


func get_characters_enums_in_current_timeline() -> Array[Characters.CHARACTERS]:
	if Dialogic.current_timeline:
		return get_characters_enums_in_timeline(Global.string_to_enum_value(Global.get_rawname(Dialogic.current_timeline.resource_path), TIMELINES))
	return []


func get_npcs_in_current_timeline() -> Array[NPC]:
	if Dialogic.current_timeline:
		return get_npcs_in_timeline(Global.string_to_enum_value(Global.get_rawname(Dialogic.current_timeline.resource_path), TIMELINES))
	return []


func get_characters_enums_in_timeline(timeline: TIMELINES) -> Array[Characters.CHARACTERS]:
	return timelines_dict[timeline][PROPERTIES.CHARACTERS]


func get_npcs_in_timeline(timeline: TIMELINES) -> Array[NPC]:
	return get_characters_enums_in_timeline(timeline).map(func(character: Characters.CHARACTERS) -> NPC: return Global.npc_manager.get_npc(character))


func is_dialogue_playing() -> bool:
	return Dialogic.current_timeline != null


func is_timeline_finished(timeline: TIMELINES) -> bool:
	return Data.game_data[Data.PROPERTIES.TIMELINES][timeline][PROPERTIES.FINISHED] == true


func is_timeline_repeatable(timeline: TIMELINES) -> bool:
	return timelines_dict[timeline][PROPERTIES.REPEATABLE] == true


func is_timeline_running() -> bool:
	return Dialogic.current_timeline != null


func get_timeline_resource(timeline: TIMELINES) -> DialogicTimeline:
	return load(resource_path + Global.enum_to_snakecase(timeline, TIMELINES) + ".dtl")


func get_timeline_name(timeline: TIMELINES) -> String:
	return Global.enum_to_title(timeline, TIMELINES)


func _on_dialogic_signal(command: String) -> void:
	match(command):
		"aggro":
			aggro_conversers()


func _on_dialogue_start() -> void:
	Global.enter_menu()


func _on_dialogue_end() -> void:
	Global.exit_menu()
