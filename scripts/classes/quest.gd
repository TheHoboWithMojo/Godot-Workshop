class_name Quest
extends Node

var nomen: String = ""
var linked_quest: Quests.QUESTS
var characters: Array[DialogicCharacter] = [] # store related characters
var timelines: Array[DialogicTimeline] = [] # store related timelines for detection logic
var levels: Array[String] = [] # store related levels file paths
var rewards: Array[String] = [] # buff string parsing?
var waypoints: Dictionary[String, Waypoint] = {} # array of waypoints but i cant enforce bc a lack of nested dicts
var caller: Node = null # save what called it
var mainplot: Plot = null # non-optional parts
var sideplots: Dictionary[String, Plot] = {} # optional parts
var choices: Array[int] = [] # enum parsing (enum in caller)
var completed: bool = false # is quest completed?
var active: bool = false # is this the current quest?
var started: bool = false

func _init(self_node: Node, quest: Quests.QUESTS) -> void:
	caller = self_node

	linked_quest = quest

	nomen = Quests.get_quest_name(quest)

	mainplot = Plot.new()
	mainplot.quest = self

	Dialogic.timeline_started.connect(_on_timeline_started)
	Global.level_manager.level_loaded.connect(_on_level_loaded)
	caller.add_to_group("quests")


func waypoint_overview() -> void:
	print("%s's Waypoints Overview (name, position):" % [nomen])
	for waypoint_name: String in waypoints:
		print(waypoint_name + " " + str(waypoints[waypoint_name].global_position))


func add_timelines(_timelines: Array[Dialogue.TIMELINES]) -> Array[DialogicTimeline]:
	for timeline: Dialogue.TIMELINES in _timelines:
		timelines.append(Dialogue.get_timeline_resource(timeline))
	return timelines


func add_characters(_characters: Array[Characters.CHARACTERS]) -> Array[DialogicCharacter]:
	for character: Characters.CHARACTERS in _characters:
		characters.append(Characters.get_character_resource(character))
		return characters
	return [null]


func add_levels(_levels: Array[Levels.LEVELS]) -> Array[String]:
	for level: Levels.LEVELS in _levels:
		levels.append(Levels.get_level_path(level))
		return levels
	return [""]


func _on_timeline_started() -> void: # notify the caller if a related timeline has been played (have to reconvert to enum form)
	if Dialogic.current_timeline in timelines:
		var timeline_name: String = Global.get_rawname(Dialogic.current_timeline)
		@warning_ignore("int_as_enum_without_cast")
		var timeline: Dialogue.TIMELINES = Global.string_to_enum_value(timeline_name, Dialogue.TIMELINES)
		caller._on_related_timeline_played(timeline)


signal waypoints_assigned
func _on_level_loaded() -> void:
	var current_level: Node = Levels.get_current_level()
	if current_level.scene_file_path in levels:
		var new_waypoints: Array = Quests.get_quest_waypoints(linked_quest) # update the linked waypoints every time a level is loaded
		for waypoint: Waypoint in new_waypoints:
			waypoints[Global.get_rawname(waypoint)] = waypoint
		waypoints_assigned.emit()
		caller._on_related_level_loaded(current_level)


func new_sideplot(_nomen: String) -> Plot:
	var sideplot: Plot = Plot.new(_nomen)
	sideplot.quest = self
	sideplots[_nomen] = sideplot
	return sideplot


func set_active(value: bool) -> void:
	active = value
	if value:
		Player.set_quest(self)


func start() -> bool:
	if not mainplot.objectives:
		Debug.throw_error("quest.gd", "start", "Quest plot %'s objectives have not been declared" % [mainplot.nomen])
		return false
	mainplot.set_started(true)
	mainplot.current_objective = mainplot.objectives.keys()[0]
	for plot: String in sideplots:
		var _plot: Plot = sideplots[plot]
		if not _plot.objectives:
			Debug.throw_error("quest.gd", "start", "Quest %'s objectives have not been declared" % [_plot.nomen])
			return false
		_plot.current_objective = _plot.objectives.keys()[0]
		_plot.set_started(true)
	started = true
	return true


func make_choice(choice: int) -> bool:
	if not choice in caller.CHOICES.values():
		Debug.throw_error("quest.gd", "make_choice", "choice '%s' is not in the CHOICE enum" % [choice])
		return false
	choices.append(choice)
	Player.choices.append(Global.enum_to_title(choice, caller.CHOICES))
	return true


func choice_made(choice: int) -> bool:
	if choice in choices:
		return true
	return false


func complete() -> void:
	caller.queue_free()


func is_active() -> bool:
	return active


func is_started() -> bool:
	return started


func overview() -> void:
	print("\n'%s' (Quest) Overview:" % [nomen.capitalize()])
	mainplot.overview()
	for plot_name: String in sideplots:
		sideplots[plot_name].overview()


class Plot:
	var objectives: Dictionary[Objective, String] # Objective + description
	var objective_waypoint_dict: Dictionary [Objective, Array] = {} # objective + array Vector2
	var current_objective: Objective = null
	var quest: Quest = null
	var nomen: String = ""
	var rewards: Array[String] = []
	var completed: bool = false
	var started: bool = false


	func _init(_nomen: String = "main") -> void:
		nomen = _nomen


	func advance() -> bool: # moves forward in the plot
		if not is_started():
			Debug.throw_error("quest.gd", "advance", "Cannot advance the plot '%s' without first starting the quest '%s'" % [nomen, quest.nomen])
			return false
		var objectives_keys: Array[Objective] = objectives.keys()
		var index: int = objectives_keys.find(current_objective)
		if (index + 1) > objectives_keys.size()-1: # if we can't advance anymore, complete the quest
			complete()
			return true
		var new_objective: Objective = objectives_keys[index + 1]
		for waypoint: Waypoint in current_objective.waypoints:
			waypoint.set_active(false)
		current_objective = new_objective
		if quest.is_active():
			for waypoint: Waypoint in current_objective.waypoints:
				waypoint.set_active(true)
			Player.set_objective(new_objective)
		return true


	func skip_to_objective(objective: Objective) -> bool: # move to a specific plot objective
		if not objective in objectives:
			Debug.throw_error("quest.gd", "skip_to", "event '%s' has not been declared" % [objective.nomen])
			return false
		var _objectives: Array[Objective] = objectives.keys()
		var target_index: int = _objectives.find(objective)
		var current_index: int = _objectives.find(current_objective)
		if target_index == current_index:
			Debug.throw_error("quest.gd", "skip_to", "cannot skip to the same event")
			return false
		if target_index < current_index:
			Debug.throw_error("quest.gd", "skip_to", "cannot skip to a past event")
			return false
		if target_index == _objectives.size() - 1:
			current_objective = objective
			complete()
			return true
		current_objective = objective
		return true


	func complete() -> void:
		for reward: String in rewards:
			pass
		if self == quest.mainplot:
			quest.complete()
		completed = true
		print("quest '%s' completed!" % [nomen])


	func create_new_objective(objective_name: String, description: String = "") -> Objective:
		var new_objective: Objective = Objective.new(objective_name, self, self.quest)
		objective_waypoint_dict[new_objective] = []
		objectives[new_objective] = description
		if not current_objective and quest.started:
			current_objective = new_objective
		return new_objective


	func objective_complete(objective: Objective) -> bool:
		return objectives.keys().find(objective) < objectives.keys().find(current_objective)


	func overview() -> void:
		print("\n'%s' (Quest: '%s'):" % [nomen.capitalize(), quest.nomen.capitalize()])
		var new_dict: Dictionary[String, String] = {}
		for objective: Objective in objectives:
			new_dict[objective.nomen] = objectives[objective]
		Debug.pretty_print_dict(new_dict)


	func get_current_objective_name() -> String:
		return current_objective.nomen


	func is_complete() -> bool:
		return completed


	func is_started() -> bool:
		return started


	func set_started(value: bool) -> void:
		started = value


class Objective:
	var nomen: String
	var plot: Plot
	var quest: Quest
	var completed: bool = false
	var waypoints: Array[Waypoint]


	func _init(_nomen: String, _plot: Plot, _quest: Quest) -> void:
		nomen = _nomen
		plot = _plot
		quest = _quest
		if plot.nomen == "main" and plot.objectives.size() == 0:
			Player.set_objective(self)


	func complete() -> void:
		plot.advance()
		completed = true


	func is_complete() -> bool:
		return completed


	func pair_waypoints(waypoint_names: Array[String]) -> bool:
		for waypoint_name: String in waypoint_names:
			if not waypoint_name in quest.waypoints.keys():
				Debug.throw_error(quest.caller, "pair_waypoints", "waypoint %s does not exist" % [waypoint_name])
				return false
			var waypoint: Waypoint = quest.waypoints[waypoint_name]
			waypoints.append(waypoint)
			plot.objective_waypoint_dict[self].append(waypoint.global_position)
			continue
		return true
