class_name Quest extends Node
@export var debugging: bool
@export var print_overview_on_advance: bool = false
@export var linked_quest: Quests.QUESTS
@export var characters: Array[Characters.CHARACTERS]
@export var timelines: Array[Dialogue.TIMELINES] = []
@export var levels: Array[Levels.LEVELS] = []
#@export var refresh_timelines: Dialogue.TIMELINES forces enum refresh

var completed: bool = false
var active: bool = false
var started: bool = false
var quest_waypoints: Dictionary[String, Waypoint] = {}
var quest_navpoints: Dictionary[String, Navpoint] = {}
var mainplot: Plot = null
var sideplots: Array[Plot] = []
var chained_quest: Quest = null

signal waypoints_assigned(self_node: Quest)
signal navpoints_assigned(self_node: Quest)
signal related_timeline_played(timelines: Dialogue.TIMELINES)
signal related_level_loaded(level: Levels.LEVELS)
signal related_character_died(character: Characters.CHARACTERS)
signal quest_created(self_node: Quest)
signal quest_started(self_node: Quest)

func _init() -> void:
	await Global.ready_to_start()
	assert(levels and characters and timelines, Debug.define_error("[Quest] Every quest node should contain related levels, characters, and timelines", self))
	mainplot = Plot.new()
	mainplot.quest = self
	Characters.character_died.connect(_on_character_died)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)
	add_to_group("quests")
	quest_created.emit(self)


func _on_character_died(character: Characters.CHARACTERS) -> void:
	if character in characters:
		related_character_died.emit(character)


func _on_timeline_started() -> void:
	if not completed:
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


func advance() -> void:
	if mainplot:
		mainplot.advance()
		return
	Debug.debug("Tried to call advance before mainplot was started", self, "quest.advance")


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
		return Vector2.ZERO
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
	sideplots.append(sideplot)
	return sideplot


func set_active(value: bool) -> void:
	Debug.debug("[Quest] '%s': set_active(%s)" % [name, value], self, "set_active")
	active = value
	if active == true:
		Player.set_quest(self)
		Player.set_objective(mainplot.current_objective)
		for quest: Quest in self.get_tree().get_nodes_in_group("quests"):
			if quest != self and quest.is_started():
				Debug.debug("[Quest] '%s' deactivating quest '%s'" % [name, quest.name], self, "set_active")
				quest.set_active(false)
	if active == false:
		Debug.debug("[Quest] '%s': turning off all waypoints" % [name], self, "set_active")
		for plot: Plot in sideplots:
			for objective: Objective in plot.objectives:
				plot._set_active_all_waypoints(objective, false)
		for objective: Objective in mainplot.objectives:
			mainplot._set_active_all_waypoints(objective, false)


func start() -> bool:
	Debug.debug("[Quest] Starting quest...", self, "start")
	if started:
		Debug.debug("[Quest] Tried to start quest %s which was already started" % [name], self, "quest.start")
		return false
	if not mainplot.objectives:
		Debug.debug("[Quest] awaiting mainplot objective to be assigned before starting", self, "start")
		await mainplot.objective_assigned
	Debug.debug("[Quest] Attempting to start mainplot", self, "quest.start")
	if not await mainplot._start():
		Debug.debug("[Quest] Starting mainquest failed, returning false", self, "qiest.start")
		return false
	Debug.debug("[Quest] Successfully started mainplot", self, "quest.start")
	if not quest_waypoints and "waypoint_manager" in await Levels.get_current_level_node():
		Debug.debug("[Quest] No quest waypoints, waiting for assignment", self, "quest.start")
		await waypoints_assigned
	if not quest_navpoints and "navpoint_manager" in await Levels.get_current_level_node():
		Debug.debug("[Quest] No quest navpoints, waiting for assignment", self, "quest.start")
		await navpoints_assigned
	for plot: Plot in sideplots:
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
	print("[Quest] %s successfully started!" % [self.name])
	return true


func get_quest_enum() -> Quests.QUESTS:
	return linked_quest


func complete() -> void:
	print("[Quest] Quest '%s' was completed!" % [name])
	completed = true
	set_active(false)
	Global.quest_displayer.find_child("Quest").set_text("")
	Global.quest_displayer.find_child("Objective").set_text("")
	if chained_quest:
		chained_quest.start()
		print("[Quest] '%s' triggered quest '%s' to start" % [name, chained_quest.name])


func set_subsequent_quest(quest: Quests.QUESTS) -> void:
	chained_quest = Global.quest_manager.get_quest_node(quest)


func is_complete() -> bool:
	return completed


func is_active() -> bool:
	return active


func is_started() -> bool:
	return started


func overview() -> void:
	print("\n'%s' (Quest) Overview:" % [name.capitalize()])
	mainplot.overview()
	for plot: Plot in sideplots:
		plot.overview()


func get_active_waypoints() -> Array[Waypoint]:
	if not started:
		Debug.debug("[Quest] Tried to get waypoints before the quest has started, waiting for start", self, "get_active_waypoints")
		await quest_started
	var waypoints: Array[Waypoint] = []
	var mainplot_waypoints: Array[Waypoint] = mainplot.current_objective.get_waypoints()
	if mainplot_waypoints:
		waypoints += mainplot_waypoints
	for plot: Plot in sideplots:
		var plot_waypoints: Array[Waypoint] = plot.current_objective.get_waypoints()
		if plot_waypoints:
			waypoints += plot_waypoints
	return waypoints


class Plot:
	signal objective_assigned(objective: Objective)
	var objectives: Array[Objective]
	var objective_waypoint_dict: Dictionary[Objective, Array] = {}
	var current_objective: Objective = null
	var activate_on_main: bool = true
	var quest: Quest = null
	var nomen: String = ""
	var rewards: Array[String] = []
	var completed: bool = false
	var started: bool = false

	func _init(_nomen: String = "main", _activate_on_main: bool = true) -> void:
		nomen = _nomen
		activate_on_main = _activate_on_main

	func _start() -> bool:
		if started:
			Debug.debug("[Plot] plot '%s' already started, skipping _start()" % [nomen], quest, "plot._start")
			return true
		if not objectives:
			Debug.debug("[Plot] Cannot start a plot without any objectives declared", quest, "_start")
			return false
		if not current_objective:
			current_objective = objectives[0]
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
		var current_position: int = objectives.find(current_objective)
		if not _has_next_objective(current_position, objectives):
			_complete()
			if self == quest.mainplot:
				quest.complete()
			return true
		var _new_objective: Objective = objectives[current_position + 1]
		Debug.debug("[Plot] plot '%s' deactivating objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		_set_active_all_waypoints(current_objective, false)
		current_objective._complete()
		current_objective = _new_objective
		Debug.debug("[Plot] plot '%s' advanced to new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		if quest.is_active():
			Debug.debug("[Plot] plot '%s's quest is active, activating its new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
			_set_active_all_waypoints(current_objective, true)
			Player.set_objective(current_objective)
		if quest.print_overview_on_advance:
			quest.overview()
		return true

	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()

	func _set_active_all_waypoints(objective: Objective, value: bool) -> void:
		for waypoint: Waypoint in objective.objective_waypoints:
			Debug.debug("[Plot] setting waypoint '%s' of objective '%s' active = %s" % [waypoint.name, objective.nomen, value], quest, "plot._set_active_all_waypoints")
			waypoint.set_active(value)

	func skip_to_objective(objective: Objective) -> bool:
		if not objective in objectives:
			push_warning(Debug.define_error("event '%s' has not been declared" % [objective.nomen], quest))
			return false
		var target_index: int = objectives.find(objective)
		var current_index: int = objectives.find(current_objective)
		if target_index == current_index:
			push_warning(Debug.define_error("cannot skip to the same event", quest))
			return false
		if target_index < current_index:
			push_warning(Debug.define_error("cannot skip to a past event", quest))
			return false
		if target_index == objectives.size() - 1:
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
		Debug.debug("[Plot] plot '%s' completed!" % [nomen], quest, "plot._complete")

	func new_objective(objective_description: String) -> Objective:
		var _new_objective: Objective = Objective.new(objective_description, self, quest)
		if not objectives:
			current_objective = _new_objective
		objectives.append(_new_objective)
		objective_waypoint_dict[_new_objective] = []
		objective_assigned.emit(_new_objective)
		return _new_objective

	func is_objective_complete(objective: Objective) -> bool:
		return objectives.find(objective) < objectives.find(current_objective)

	func overview() -> void:
		print("\n'%s' (Quest: '%s'):" % [nomen.capitalize(), quest.name.capitalize()])
		var name_array: Array[String]
		for objective: Objective in objectives:
			if objective == current_objective:
				name_array.append(objective.nomen + " - CURRENT OBJECTIVE")
				continue
			name_array.append(objective.nomen)
		Debug.pretty_print_array(name_array)

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
	var quest: Quest
	var completed: bool = false
	var objective_waypoints: Array[Waypoint]
	signal waypoint_paired

	func _init(_nomen: String, _plot: Plot, _quest: Quest) -> void:
		nomen = _nomen
		plot = _plot
		quest = _quest

	func _complete() -> void:
		Debug.debug("[Objective] '%s' complete() called" % [nomen], quest, "objective.complete")
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
