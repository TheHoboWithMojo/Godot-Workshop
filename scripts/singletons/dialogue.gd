extends Node

func start(timeline: String) -> void:
	if _is_timeline_running():
		Debug.throw_error(self, "start_dialog", "A timeline is already running! Cannot start a new one")
		return
	if timeline in Dicts.timelines.keys():
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " has been played and is not repeatable")
			return
		
		Data.game_data["timelines"][timeline]["completed"] = true
		Dialogic.start(timeline)
	else:
		Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " does not exist")
		
func aggro_conversers()  -> void:
	if _is_timeline_running():
		var timeline_name: String = Global.get_rawname(Dialogic.current_timeline.resource_path)
		for character: Dictionary in Dicts.timelines[timeline_name]["characters"]:
			for npc: Node2D in get_tree().get_nodes_in_group("npc"):
				if npc.name.to_lower() == character.name:
					npc.master.hostile = true
		
func _is_timeline_completed(timeline: String) -> bool:
	return Data.game_data["timelines"][timeline]["completed"] == true

func _is_timeline_repeatable(timeline: String) -> bool:
	return Dicts.timelines[timeline]["repeatable"] == true

func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)

func _on_dialogic_signal(command: String) -> void:
	if command == "aggro":
		aggro_conversers()
		
var total_mobs: int = 0
func _on_dialogue_start() -> void:
	Global.speed_mult = 0.0
	Global.player.set_physics_process(false)
	Global.player.can_shoot = false
	
	total_mobs = Global.game_manager.total_mobs # Store actual mob count
	Global.game_manager.total_mobs = Global.game_manager.MOB_CAP # Sets mob count to max to stop spawning
	
	for being: Node2D in Global.get_beings():
		being.master.vincible = false

func _on_dialogue_end() -> void:
	Global.player.set_physics_process(true)
	Global.player.can_shoot = true
	Global.game_manager.total_mobs = total_mobs # Restores actual mob count
	
	for being: Node2D in Global.get_beings():
		being.master.vincible = true
	
	Global.speed_mult = 1.0
	
