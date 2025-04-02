extends Node

# Timelines Dictionary
var timelines_dict: Dictionary = {
	"npc": {
		"completed": false,
		"repeatable": false,
		"characters": ["steve"]
	}
}

func start(timeline: String) -> void:
	if _is_timeline_running():
		Debug.throw_error(self, "start_dialog", "A timeline is already running! Cannot start a new one")
		return
	if timeline in timelines_dict.keys():
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " has been played and is not repeatable")
			return
		
		timelines_dict[timeline]["completed"] = true
		Dialogic.start(timeline)
	else:
		Debug.throw_error(self, "start_dialog", "The timeline " + timeline + " does not exist")
		
func aggro_conversers()  -> void:
	if _is_timeline_running():
		var timeline_name: String = Global.get_rawname(Dialogic.current_timeline.resource_path)
		for character: String in timelines_dict[timeline_name]["characters"]:
			for npc: Node2D in get_tree().get_nodes_in_group("npc"):
				if npc.name.to_lower() == character:
					npc.master.hostile = true
		
func _is_timeline_completed(timeline: String) -> bool:
	return timelines_dict[timeline]["completed"] == true

func _is_timeline_repeatable(timeline: String) -> bool:
	return timelines_dict[timeline]["repeatable"] == true

func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null
