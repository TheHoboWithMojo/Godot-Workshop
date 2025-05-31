class_name Quest
extends Node

var nomen: String = ""
var linked_quest: Quests.QUESTS
var characters: Array[DialogicCharacter] = [] # store related characters
var timelines: Array[DialogicTimeline] = [] # store related timelines for detection logic
var levels: Array[String] = [] # store related levels file paths
var rewards: Array[String] = [] # buff string parsing?
var quest_waypoints: Dictionary[String, Waypoint] = {} # array of waypoints but i cant enforce bc a lack of nested dicts
var quest_navpoints: Dictionary[String, Navpoint] = {}
var caller: Node = null # save what called it
var mainplot: Plot = null # non-optional parts
var sideplots: Dictionary[String, Plot] = {} # optional parts
var choices: Array[int] = [] # enum parsing (enum in caller)
var completed: bool = false # is quest completed?
var active: bool = false # is this the current quest?
var started: bool = false

signal waypoints_assigned
signal navpoints_assigned

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
	print("\n%s's Waypoints Overview (name, position):" % [nomen])
	for waypoint_name: String in quest_waypoints:
		print(waypoint_name + " " + str(quest_waypoints[waypoint_name].global_position))


func navpoint_overview() -> void:
	print("\n%s's Navpoints Overview (name, position):" % [nomen])
	for navpoint_name: String in quest_navpoints:
		print(navpoint_name + " " + str(quest_navpoints[navpoint_name].global_position))


func get_navpoint_position(navpoint_name: String) -> Vector2:
	assert(navpoint_name in quest_navpoints.keys())
	var navpoint: Navpoint = quest_navpoints[navpoint_name]
	return navpoint.global_position


func get_waypoint_position(waypoint_name: String) -> Vector2:
	if not waypoint_name in quest_waypoints.keys():
		return Vector2.ZERO
	var waypoint: Waypoint = quest_waypoints[waypoint_name]
	return waypoint.global_position


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


func _on_level_loaded() -> void:
	if not completed:
		var current_level: Node = Levels.get_current_level()
		if current_level.scene_file_path in levels:
			var new_waypoints: Array = Quests.get_quest_waypoints(linked_quest) # update the linked waypoints every time a level is loaded
			var new_navpoints: Array = Quests.get_quest_navpoints(linked_quest)
			for waypoint: Waypoint in new_waypoints:
				quest_waypoints[Global.get_rawname(waypoint)] = waypoint
			waypoints_assigned.emit()
			for navpoint: Navpoint in new_navpoints:
				quest_navpoints[Global.get_rawname(navpoint)] = navpoint
			navpoints_assigned.emit()
			caller._on_related_level_loaded(current_level)
		if quest_waypoints:
			var level_waypoints: Array[Waypoint] = current_level.get_waypoints()
			for waypoint: Waypoint in quest_waypoints.values():
				if not waypoint in level_waypoints:
					waypoint.set_visible(false)


func new_sideplot(_nomen: String) -> Plot:
	var sideplot: Plot = Plot.new(_nomen)
	sideplot.quest = self
	sideplots[_nomen] = sideplot
	return sideplot


func set_active(value: bool) -> void:
	active = value
	if active == true:
		Player.set_quest(self)
		Player.set_objective(mainplot.current_objective)
		for quest: Node in caller.get_tree().get_nodes_in_group("quests"):
			if quest.quest != caller:
				quest.quest.set_active(false)
	if active == false:
		for plot: Plot in sideplots.values():
			for objective: Objective in plot.objectives:
				plot._set_active_all_waypoints(objective, false)
		for objective: Objective in mainplot.objectives:
			mainplot._set_active_all_waypoints(objective, false)


func start() -> bool:
	if not Levels.get_current_level():
		await Global.level_manager.level_loaded
	if not quest_waypoints and "waypoint_manager" in Levels.get_current_level():
		await waypoints_assigned
	if not quest_navpoints and "navpoint_manager" in Levels.get_current_level():
		await navpoints_assigned

	if not mainplot.objectives:
		Debug.throw_error("quest.gd", "start", "Quest plot %'s objectives have not been declared" % [mainplot.nomen])
		return false
	mainplot._start()
	set_active(true) # quests always are set active on start
	for plot_name: String in sideplots:
		var plot: Plot = sideplots[plot_name]
		if not plot.objectives:
			Debug.throw_error("quest.gd", "start", "Quest %'s objectives have not been declared" % [plot.nomen])
			return false
		if not plot.activate_on_main:
			continue
		plot._start()
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
	var activate_on_main: bool = true # whether or not the sideplot starts when the main does
	var quest: Quest = null
	var nomen: String = ""
	var rewards: Array[String] = []
	var completed: bool = false
	var started: bool = false


	func _init(_nomen: String = "main", _activate_on_main: bool = true) -> void:
		nomen = _nomen
		activate_on_main = _activate_on_main


	func _start() -> void:
		if is_started():
			return
		current_objective = objectives.keys()[0]
		if not current_objective.objective_waypoints:
			await current_objective.waypoint_paired
		current_objective.objective_waypoints[0].set_active(true)
		started = true


	func advance() -> bool: # moves forward in the plot
		if not is_started():
			Debug.throw_error("quest.gd", "advance", "Cannot advance the plot '%s' without first starting the quest '%s'" % [nomen, quest.nomen])
			return false
		if is_complete():
			Debug.throw_error("quest.gd", "advance", "Trying to advance a plot that was already completed")
			return false

		var objectives_array: Array[Objective] = objectives.keys()
		var current_position: int = objectives_array.find(current_objective)
		if not _has_next_objective(current_position, objectives_array):
			_complete()
			return true

		var _new_objective: Objective = objectives_array[current_position + 1]
		_set_active_all_waypoints(current_objective, false)
		current_objective = _new_objective
		if quest.is_active():
			_set_active_all_waypoints(current_objective, true)
			Player.set_objective(current_objective)
		return true


	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()


	func _set_active_all_waypoints(objective: Objective, value: bool) -> void:
		for waypoint: Waypoint in objective.objective_waypoints:
			waypoint.set_active(value)


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
			_complete()
			return true
		current_objective = objective
		return true


	func _complete() -> void:
		for reward: String in rewards:
			pass
		if self == quest.mainplot:
			quest.complete()
		completed = true
		print("plot '%s' completed!" % [nomen])


	func new_objective(objective_name: String, description: String = "") -> Objective:
		var _new_objective: Objective = Objective.new(objective_name, self, self.quest)
		objective_waypoint_dict[_new_objective] = []
		objectives[_new_objective] = description
		return _new_objective


	func is_objective_complete(objective: Objective) -> bool:
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


class Objective:
	var nomen: String
	var plot: Plot
	var quest: Quest
	var completed: bool = false
	var objective_waypoints: Array[Waypoint]
	signal waypoint_paired


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
			if not waypoint_name in quest.quest_waypoints.keys():
				Debug.throw_error(quest.caller, "pair_waypoints", "waypoint %s does not exist" % [waypoint_name])
				return false
			var waypoint: Waypoint = quest.quest_waypoints[waypoint_name]
			objective_waypoints.append(waypoint)
			plot.objective_waypoint_dict[self].append(waypoint.global_position)
		waypoint_paired.emit()
		return true
