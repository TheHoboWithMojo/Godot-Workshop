class_name QuestMaker extends Node
@export var debugging: bool
@export var linked_quest: Quests.QUESTS
@export var characters: Array[Characters.CHARACTERS]
@export var timelines: Array[Dialogue.TIMELINES] = []
@export var levels: Array[Levels.LEVELS] = []

var completed: bool = false
var active: bool = false
var started: bool = false
var quest_waypoints: Dictionary[String, Waypoint] = {}
var quest_navpoints: Dictionary[String, Navpoint] = {}
var mainplot: Plot = null
var sideplots: Dictionary[String, Plot] = {}

signal waypoints_assigned(self_node: QuestMaker)
signal navpoints_assigned(self_node: QuestMaker)
signal related_timeline_played(timelines: Dialogue.TIMELINES)
signal related_level_loaded(level: Levels.LEVELS)
signal quest_created(self_node: QuestMaker)
signal quest_started(self_node: QuestMaker)

func _init() -> void:
	await Global.ready_to_start()
	name = Quests.get_quest_name(linked_quest)
	assert(levels and characters and timelines, Debug.define_error("[Quest] Every quest node should contain related levels, characters, and timelines", self))
	mainplot = Plot.new()
	mainplot.quest = self
	Dialogic.timeline_started.connect(_on_timeline_started)
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)
	add_to_group("quests")
	quest_created.emit(self)


func _on_timeline_started() -> void:
	@warning_ignore("int_as_enum_without_cast")
	var current_timeline: Dialogue.TIMELINES = Global.string_to_enum_value(Global.get_rawname(Dialogic.current_timeline), Dialogue.TIMELINES)
	if current_timeline in timelines:
		related_timeline_played.emit(current_timeline)


func _on_new_level_loaded(new_level: Level) -> void:
	if not completed:
		if new_level.get_level_enum() in levels:
			var new_waypoints: Array = Quests.get_quest_waypoints(linked_quest)
			var new_navpoints: Array = Quests.get_quest_navpoints(linked_quest)
			for waypoint: Waypoint in new_waypoints:
				quest_waypoints[Global.get_rawname(waypoint)] = waypoint
			waypoints_assigned.emit(self)
			for navpoint: Navpoint in new_navpoints:
				quest_navpoints[Global.get_rawname(navpoint)] = navpoint
			navpoints_assigned.emit(self)
			related_level_loaded.emit(new_level.get_level_enum())


func waypoint_overview() -> void:
	print("\n%s's Waypoints Overview (name, position):" % [name])
	for waypoint_name: String in quest_waypoints:
		print(waypoint_name + " " + str(quest_waypoints[waypoint_name].global_position))


func navpoint_overview() -> void:
	print("\n%s's Navpoints Overview (name, position):" % [name])
	for navpoint_name: String in quest_navpoints:
		Debug.debug(navpoint_name + " " + str(quest_navpoints[navpoint_name].global_position), self, "navpoint_overview")


func get_navpoint_position(navpoint_name: String) -> Vector2:
	if navpoint_name not in quest_navpoints.keys():
		push_warning(Debug.define_error("The navpoint provided %s does not exist, check to see if the related quest enum reference broke." % [navpoint_name], self))
	var navpoint_pos: Vector2 = quest_navpoints[navpoint_name].global_position
	Debug.debug("[Quest] Navpoint %s position %s succsessfully retrieved" % [navpoint_name, navpoint_pos], self, "get_navpoint_position")
	return navpoint_pos


func get_waypoint_position(waypoint_name: String) -> Vector2:
	if not waypoint_name in quest_waypoints.keys():
		return Vector2.ZERO
	var waypoint: Waypoint = quest_waypoints[waypoint_name]
	return waypoint.global_position


func new_sideplot(_nomen: String) -> Plot:
	var sideplot: Plot = Plot.new(_nomen)
	sideplot.quest = self
	sideplots[_nomen] = sideplot
	return sideplot


func set_active(value: bool) -> void:
	Debug.debug("[Quest] '%s': set_active(%s)" % [name, value], self, "set_active")
	active = value
	if active == true:
		Player.set_quest(self)
		Player.set_objective(mainplot.current_objective)
		for quest: QuestMaker in self.get_tree().get_nodes_in_group("quests"):
			if quest != self and quest.is_started():
				Debug.debug("[Quest] '%s' deactivating quest '%s'" % [name, quest.name], self, "set_active")
				quest.set_active(false)
	if active == false:
		Debug.debug("[Quest] '%s': turning off all waypoints" % [name], self, "set_active")
		for plot: Plot in sideplots.values():
			for objective: Objective in plot.objectives:
				plot._set_active_all_waypoints(objective, false)
		for objective: Objective in mainplot.objectives:
			mainplot._set_active_all_waypoints(objective, false)

func start() -> bool:
	Debug.debug("[Quest] Starting quest", self, "start")
	if not await Levels.get_current_level_node():
		Debug.debug("[Quest] not level loaded, waiting level loaded", self, "quest.start")
		await Global.level_manager.new_level_loaded
	if not quest_waypoints and "waypoint_manager" in await Levels.get_current_level_node():
		Debug.debug("[Ques t]No quest waypoints, waiting for assignment", self, "quest.start")
		await waypoints_assigned
	if not quest_navpoints and "navpoint_manager" in await Levels.get_current_level_node():
		Debug.debug("[Quest] No quest navpoints, waiting for assignment", self, "quest.start")
		await navpoints_assigned
	if not mainplot.objectives:
		push_warning(Debug.define_error("[Quest] plot %'s objectives have not been declared" % [mainplot.nomen], self))
		return false
	Debug.debug("[Quest] Attempting to start mainplot", self, "quest.start")
	if await mainplot._start():
		Debug.debug("[Quest] Successfully started mainplot", self, "quest.start")
	else:
		Debug.debug("[Quest] Starting mainquest failed, returning false", self, "qiest.start")
		return false
	for plot_name: String in sideplots:
		var plot: Plot = sideplots[plot_name]
		if not plot.objectives:
			push_warning(Debug.define_error("[Quest] plot %'s objectives have not been declared" % [plot.nomen], self))
			return false
		if not plot.activate_on_main:
			continue
		plot._start()
	set_active(true)
	Global.quest_manager.set_current_quest(self, true)
	quest_started.emit(self)
	started = true
	return true

func get_quest_enum() -> Quests.QUESTS:
	return linked_quest


func complete() -> void:
	completed = true
	#self.queue_free()


func is_active() -> bool:
	Debug.debug("[Quest] '%s': is_active() == %s" % [name, active], self, "is_active")
	return active


func is_started() -> bool:
	return started


func overview() -> void:
	print("\n'%s' (QuestMaker) Overview:" % [name.capitalize()])
	mainplot.overview()
	for plot_name: String in sideplots:
		sideplots[plot_name].overview()


func get_active_waypoints() -> Array[Waypoint]:
	if not started:
		Debug.debug("[Quest] Tried to get waypoints before the quest has started, waiting for start", self, "get_active_waypoints")
		await quest_started
	var waypoints: Array[Waypoint] = []
	var mainplot_waypoints: Array[Waypoint] = mainplot.current_objective.get_waypoints()
	if mainplot_waypoints:
		waypoints += mainplot_waypoints
	for plot: Plot in sideplots.values():
		var plot_waypoints: Array[Waypoint] = plot.current_objective.get_waypoints()
		if plot_waypoints:
			waypoints += plot_waypoints
	return waypoints


class Plot:
	var objectives: Dictionary[Objective, String]
	var objective_waypoint_dict: Dictionary[Objective, Array] = {}
	var current_objective: Objective = null
	var activate_on_main: bool = true
	var quest: QuestMaker = null
	var nomen: String = ""
	var rewards: Array[String] = []
	var completed: bool = false
	var started: bool = false

	func _init(_nomen: String = "main", _activate_on_main: bool = true) -> void:
		nomen = _nomen
		activate_on_main = _activate_on_main

	func _start() -> bool:
		if started:
			Debug.debug("[Plot] already started, skipping _start()" % [nomen], quest, "plot._start")
			return true
		if not objectives:
			Debug.debug("[Plot] Cannot start a plot without any objectives declared", quest, "_start")
			return false
		if not current_objective:
			current_objective = objectives.keys()[0]
		if not current_objective.objective_waypoints:
			Debug.debug("[Plot] Waiting for plot %s's first objective '%s' to be assigned a waypoint" % [nomen, current_objective.nomen], quest, "plot._start")
			await current_objective.waypoint_paired
			Debug.debug("[Plot] plot '%s's first objective %s's waypoint succesfully assigned, starting plot." % [nomen, current_objective.nomen], quest, "_start")
		Debug.debug("[Plot] '%s' starting, activating waypoint '%s'" % [nomen, current_objective.objective_waypoints[0].name], quest, "plot._start")
		current_objective.objective_waypoints[0].set_active(true)
		started = true
		return true

	func advance() -> bool:
		if is_complete():
			Debug.debug("[Plot] Redundant call, quest is already completed", quest, "plot.advance")
			return false
		if not is_started():
			Debug.debug("[Plot] Trying to advance the plot '%s' before its quest has started, waiting quest started" % [nomen], quest, "plot.advance")
			await quest.quest_started
			Debug.debug("[Plot] the plot '%s's respective quest has started, continuing" % [nomen], quest, "plot.advance")
		var objectives_array: Array[Objective] = objectives.keys()
		var current_position: int = objectives_array.find(current_objective)
		if not _has_next_objective(current_position, objectives_array):
			_complete()
			return true
		var _new_objective: Objective = objectives_array[current_position + 1]
		Debug.debug("[Plot] plot '%s' sdeactivating objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		_set_active_all_waypoints(current_objective, false)
		current_objective = _new_objective
		Debug.debug("[Plot] plot '%s' advanced to new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		if quest.is_active():
			Debug.debug("[Plot] plot '%s's quest is active, activating its new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
			_set_active_all_waypoints(current_objective, true)
			Player.set_objective(current_objective)
		return true

	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()

	func _set_active_all_waypoints(objective: Objective, value: bool) -> void:
		for waypoint: Waypoint in objective.objective_waypoints:
			Debug.debug("[Plot] setting waypoint '%s' of objective '%s' active = %s" % [waypoint.name, objective, value], quest, "plot._set_active_all_waypoints")
			waypoint.set_active(value)

	func skip_to_objective(objective: Objective) -> bool:
		if not objective in objectives:
			push_warning(Debug.define_error("event '%s' has not been declared" % [objective.nomen], quest))
			return false
		var _objectives: Array[Objective] = objectives.keys()
		var target_index: int = _objectives.find(objective)
		var current_index: int = _objectives.find(current_objective)
		if target_index == current_index:
			push_warning(Debug.define_error("cannot skip to the same event", quest))
			return false
		if target_index < current_index:
			push_warning(Debug.define_error("cannot skip to a past event", quest))
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
		Debug.debug("[Plot] completed!" % [nomen], quest, "plot._complete")

	func new_objective(objective_name: String, description: String = "") -> Objective:
		var _new_objective: Objective = Objective.new(objective_name, self, quest)
		if not objectives:
			current_objective = _new_objective
		objective_waypoint_dict[_new_objective] = []
		objectives[_new_objective] = description
		return _new_objective

	func is_objective_complete(objective: Objective) -> bool:
		return objectives.keys().find(objective) < objectives.keys().find(current_objective)

	func overview() -> void:
		print("\n'%s' (QuestMaker: '%s'):" % [nomen.capitalize(), quest.name.capitalize()])
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

	func get_current_objective() -> Objective:
		return current_objective

	func get_current_waypoint() -> Waypoint:
		return current_objective.objective_waypoints[0]

class Objective:
	var nomen: String
	var plot: Plot
	var quest: QuestMaker
	var completed: bool = false
	var objective_waypoints: Array[Waypoint]
	signal waypoint_paired

	func _init(_nomen: String, _plot: Plot, _quest: QuestMaker) -> void:
		nomen = _nomen
		plot = _plot
		quest = _quest

	func complete() -> void:
		Debug.debug("[Objective] complete() called" % [nomen], quest, "objective.complete")
		plot.advance()
		completed = true

	func is_complete() -> bool:
		return completed

	func get_waypoints() -> Array[Waypoint]:
		return objective_waypoints

	func pair_waypoints(waypoint_names: Array[String]) -> bool:
		for waypoint_name: String in waypoint_names:
			Debug.debug("[Objective] Attempting to pair waypoint '%s' to objective '%s' of plot '%s', entering await loop" % [waypoint_name, nomen, plot.nomen], quest, "objective.pair_waypoints")
			while not waypoint_name in quest.quest_waypoints.keys():
				await quest.waypoints_assigned
			var waypoint: Waypoint = quest.quest_waypoints[waypoint_name]
			objective_waypoints.append(waypoint)
			plot.objective_waypoint_dict[self].append(waypoint.global_position)
			Debug.debug("[Objective] Successfully Added waypoint %s to objective %s of plot %s" % [waypoint_name, nomen, plot.nomen], quest, "objective.pair_waypoints")
		waypoint_paired.emit()
		return true
