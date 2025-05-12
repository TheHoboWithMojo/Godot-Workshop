class_name Quest
extends Node2D

var nomen: String = ""
var characters: Array[DialogicCharacter] = []
var rewards: Array[String] = [] # buff string parsing?
var caller: Node = null
var mainplot: Plot = null
var subplots: Dictionary[String, Plot] = {}
var choices: Array[int] = []
var related_timelines: Array[DialogicTimeline] = []
var completed: bool = false
var quest: Quest = self # need an instanced version of quest for plot to reference

func _init(self_node: Node) -> void:
	if "CHOICES" not in self_node:
		Debug.throw_error(self_node, "quest_init", "quest node must contain a CHOICES enum")
		return
	
	caller = self_node
	nomen = caller.name
	characters = caller.characters
	related_timelines = caller.related_timelines
	
	mainplot = Plot.new()
	mainplot.quest = quest
	Dialogic.timeline_started.connect(_on_timeline_started)
	
	caller.add_to_group("quests")
	
func _on_timeline_started() -> void:
	if Dialogic.current_timeline in related_timelines:
		pass

func new_subplot(_nomen: String) -> Plot:
	var subplot: Plot = Plot.new(_nomen)
	subplot.quest = quest
	subplots[_nomen] = subplot
	return subplot
	
func make_choice(choice: int) -> bool:
	if choice in caller.CHOICES.values():
		choices.append(choice)
		Player.choices.append(Global.enum_to_title(choice, caller.CHOICES))
		return true
	Debug.throw_error(caller, "make_choice", "choice %s is not in the CHOICE enum" % [choice])
	return false
		
func choice_made(choice: int) -> bool:
	if choice in choices:
		return true
	return false
	
func complete() -> void:
	caller.queue_free()
	
func overview() -> void:
	print("\n%s (Quest) Overview:" % [nomen.capitalize()])
	mainplot.overview()
	for plot_name: String in subplots:
		subplots[plot_name].overview()
	
class Plot:
	var objectives: Dictionary[String, String] # objective + description
	var current_objective: String
	var quest: Quest
	var nomen: String
	var rewards: Array[String]
	var completed: bool = false
	
	func _init(_nomen: String = "main") -> void:
		nomen = _nomen
		
	func advance() -> bool: # moves forward in the plot
		var objectives_array: Array = objectives.keys()
		var index: int = objectives_array.find(current_objective)
		if not (index + 1) > objectives_array.size() - 1: # if the new objective is within range
			current_objective = objectives_array[index + 1]
			return true
		if index == objectives.size() - 1:
			complete()
			return true
		return false
			
	func skip_to_objective(objective: String) -> bool: # move to a specific plot objective
		objective = objective.to_lower()

		if not objective in objectives:
			Debug.throw_error(quest.caller, "skip_to", "event %s has not been declared" % [objective])
			return false

		var _objectives: Array[String] = objectives.keys()
		var target_index: int = _objectives.find(objective)
		var current_index: int = _objectives.find(current_objective)

		if target_index == current_index:
			Debug.throw_error(quest.caller, "skip_to", "cannot skip to the same event")
			return false
			
		if target_index < current_index:
			Debug.throw_error(quest.caller, "skip_to", "cannot skip to a past event")
			return false

		if target_index == _objectives.size() - 1:
			current_objective = objective
			complete()
			return true

		current_objective = objective
		return true
		
	func complete() -> void:
		for reward: String in rewards:
			Player.change_stat(reward)
		if self == quest.mainplot:
			quest.complete()
		completed = true
		print("quest %s completed!" % [nomen])
	
	func new_objective(objective: String, description: String = "") -> void:
		objectives[objective.to_lower()] = description.to_lower()
		if not current_objective:
			current_objective = objectives.keys()[0]
	
	func objective_complete(objective: String) -> bool:
		return objectives.keys().find(objective.to_lower()) < objectives.keys().find(current_objective.to_lower())
		
	func overview() -> void:
		print("\n%s (Quest: %s):" % [nomen.capitalize(), quest.nomen.capitalize()])
		Debug.pretty_print_dict(objectives)
		
	func get_current_objective() -> String:
		return current_objective
		
	func is_complete() -> bool:
		return completed
