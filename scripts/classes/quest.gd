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
var quest_waypoints: Dictionary[String, Vector3] = {}
var quest_navpoints: Dictionary[String, Vector3] = {}
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
	if Quests.is_quest_completed(linked_quest):
		queue_free()
		return
	assert(levels and characters and timelines, Debug.define_error("[Quest] Every quest node should contain related levels, characters, and timelines", self))
	quest_navpoints = Markers.get_quest_navpoints(linked_quest)
	quest_waypoints = Markers.get_quest_waypoints(linked_quest)
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
	@warning_ignore("int_as_enum_without_cast")
	var current_timeline: Dialogue.TIMELINES = Global.string_to_enum_value(Global.get_rawname(Dialogic.current_timeline), Dialogue.TIMELINES)
	if current_timeline in timelines:
		related_timeline_played.emit(current_timeline)


func _on_new_level_loaded(new_level: Level) -> void:
	quest_waypoints = Markers.get_quest_waypoints(linked_quest)
	quest_navpoints = Markers.get_quest_navpoints(linked_quest)
	waypoints_assigned.emit()
	navpoints_assigned.emit()
	if new_level.get_level_enum() in levels:
		related_level_loaded.emit(new_level.get_level_enum())


func advance() -> void:
	if mainplot:
		mainplot.advance()
		return
	Debug.debug("Tried to call advance before mainplot was started", self, "quest.advance")


func waypoint_overview() -> void:
	print("\n%s's Waypoints Overview (name, position):" % [name])
	for waypoint_name: String in quest_waypoints:
		print(waypoint_name + " " + str(Vector2(quest_waypoints[waypoint_name].x, quest_waypoints[waypoint_name].y)))


func navpoint_overview() -> void:
	print("\n%s's Navpoints Overview (name, position):" % [name])
	for navpoint_name: String in quest_navpoints:
		Debug.debug(navpoint_name + " " + str(get_waypoint_position(navpoint_name)), self, "navpoint_overview")


func get_navpoint_position(navpoint_name: String) -> Vector2:
	if navpoint_name not in quest_navpoints:
		push_warning(Debug.define_error("The navpoint provided %s does not exist, check to see if the related quest enum reference broke." % [navpoint_name], self))
		return Vector2.ZERO
	var navpoint_pos: Vector2 = Vector2(quest_navpoints[navpoint_name].x, quest_navpoints[navpoint_name].y)
	Debug.debug("[Quest] Navpoint %s position %s succsessfully retrieved" % [navpoint_name, navpoint_pos], self, "get_navpoint_position")
	return navpoint_pos


func get_waypoint_position(waypoint_name: String) -> Vector2:
	if not waypoint_name in quest_waypoints.keys():
		return Vector2.ZERO
	var waypoint_pos: Vector2 = Vector2(quest_waypoints[waypoint_name].x, quest_waypoints[waypoint_name].y)
	return waypoint_pos


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
	if completed:
		return
	completed = true
	set_active(false)
	Global.quest_displayer.find_child("Quest").set_text("")
	Global.quest_displayer.find_child("Objective").set_text("")
	Quests.set_quest_complete(linked_quest, true)
	Characters.character_died.disconnect(_on_character_died)
	Dialogic.timeline_started.disconnect(_on_timeline_started)
	Global.level_manager.new_level_loaded.disconnect(_on_new_level_loaded)
	print("[Quest] Quest '%s' was completed!" % [name])
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


func get_active_waypoints() -> Dictionary[String, Vector3]:
	if not started:
		Debug.debug("[Quest] Tried to get waypoints before the quest has started, waiting for start", self, "get_active_waypoints")
		await quest_started
	var waypoints: Dictionary[String, Vector3]
	var mainplot_waypoints: Dictionary[String, Vector3] = mainplot.current_objective.get_waypoints()
	waypoints.merge(mainplot_waypoints)
	for plot: Plot in sideplots:
		var plot_waypoints: Dictionary[String, Vector3] = plot.current_objective.get_waypoints()
		waypoints.merge(plot_waypoints)
	return waypoints


class Plot:
	signal objective_assigned(objective: Objective)
	var objectives: Array[Objective]
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
		Global.active_waypoint.set_active_waypoint(current_objective.objective_waypoints.keys()[0])
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
		current_objective._complete()
		current_objective = _new_objective
		Debug.debug("[Plot] plot '%s' advanced to new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		if quest.is_active():
			Debug.debug("[Plot] plot '%s's quest is active, activating its new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
			Player.set_objective(current_objective)
			if not current_objective.get_waypoints():
				await current_objective.waypoint_paired
			Global.active_waypoint.set_active_waypoint(current_objective.get_waypoints().keys()[0])
		if quest.print_overview_on_advance:
			quest.overview()
		return true

	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()

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

	func get_current_waypoint() -> Vector3:
		return current_objective.objective_waypoints.values()[0]

class Objective:
	var nomen: String
	var plot: Plot
	var quest: Quest
	var completed: bool = false
	var objective_waypoints: Dictionary[String, Vector3]
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

	func get_waypoints() -> Dictionary[String, Vector3]:
		return objective_waypoints

	func pair_waypoints(waypoint_names: Array[String]) -> void:
		for waypoint_name: String in waypoint_names:
			Debug.debug("[Objective] Attempting to pair waypoint '%s' to objective '%s' of plot '%s', entering await loop" % [waypoint_name, nomen, plot.nomen], quest, "objective.pair_waypoints")
			while not waypoint_name in quest.quest_waypoints:
				Debug.debug("[Objective] Waiting for waypoints to update to add '%s' waypoints to objective '%s'" % [str(waypoint_names), nomen], quest, "objective.pair_waypoints")
				await quest.waypoints_assigned
			var waypoint: Vector3 = quest.quest_waypoints[waypoint_name]
			objective_waypoints[waypoint_name] = waypoint
			Debug.debug("[Objective] Successfully Added waypoint %s to objective %s of plot %s" % [waypoint_name, nomen, plot.nomen], quest, "objective.pair_waypoints")
		waypoint_paired.emit()
