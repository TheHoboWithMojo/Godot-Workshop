class_name Quest extends Node
@export var debugging: bool
@export var print_overview_on_advance: bool = false
@export var linked_quest: Quests.QUESTS
@export var characters: Array[Characters.CHARACTERS]
@export var timelines: Array[Dialogue.TIMELINES] = []
@export var levels: Array[Levels.LEVELS] = []
#@export var refresh_timelines: Dialogue.TIMELINES forces enum refresh

var finished: bool = false
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
	if Quests.is_quest_finished(linked_quest):
		started = true
		finished = true
		Debug.debug("is finished", self, "_init")
	assert(levels and characters and timelines, Debug.define_error("[Quest] Every quest node should contain related levels, characters, and timelines", self))
	quest_navpoints = Markers.get_quest_navpoints(linked_quest)
	quest_waypoints = Markers.get_quest_waypoints(linked_quest)
	mainplot = Plot.new("main", true, self)
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


func finish() -> void:
	if finished:
		return
	finished = true
	set_active(false)
	Global.quest_displayer.find_child("Quest").set_text("")
	Global.quest_displayer.find_child("Objective").set_text("")
	Quests.set_quest_finished(linked_quest, true)
	Characters.character_died.disconnect(_on_character_died)
	Dialogic.timeline_started.disconnect(_on_timeline_started)
	Global.level_manager.new_level_loaded.disconnect(_on_new_level_loaded)
	print("[Quest] Quest '%s' was finished!" % [name])
	if chained_quest:
		chained_quest.start()
		print("[Quest] '%s' triggered quest '%s' to start" % [name, chained_quest.name])


func set_subsequent_quest(quest: Quests.QUESTS) -> void:
	chained_quest = Global.quest_manager.get_quest_node(quest)


func is_finished() -> bool:
	return finished


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
	var finished: bool = false
	var started: bool = false


	func _init(_nomen: String = "main", _activate_on_main: bool = true, _quest: Quest = null) -> void:
		quest = _quest
		if _quest and quest.finished:
			finished = true
			return
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
			_set_current_objective(objectives[0])
		if not current_objective.get_waypoints():
			Debug.debug("[Plot] Waiting for plot %s's first objective '%s' to be assigned a waypoint" % [nomen, current_objective.nomen], quest, "plot._start")
			await current_objective.waypoint_paired
			Debug.debug("[Plot] plot '%s's first objective %s's waypoint succesfully assigned, starting plot." % [nomen, current_objective.nomen], quest, "_start")
		started = true
		return true


	func _set_current_objective(_new_objective: Objective) -> void:
		if not current_objective:
			current_objective = _new_objective
			current_objective._try_activate()
			return
		current_objective.finished = true
		current_objective = _new_objective
		current_objective._try_activate()


	func get_latest_unfinished_objective() -> Objective:
		for objective: Objective in objectives:
			if not objective.is_finished():
				return objective
		return null


	func declare_all_objectives_assigned() -> void:
		var objective_to_skip_to: Objective
		# if the first objective isn't stored, the quest data has been cleared and needs to be reset
		if not Quests.is_objective_stored(quest.linked_quest, objectives[0].nomen):
			Debug.debug("[Plot] The first objective is not stored in quest data, updating the data now", quest, "declare_all_objectives_assigned")
			var updated_objective_dict: Dictionary[String, bool]
			for objective: Objective in objectives:
				updated_objective_dict[objective.nomen] = false
			Data.game_data[Data.PROPERTIES.QUESTS][quest.linked_quest][Quests.PROPERTIES.OBJECTIVES] = updated_objective_dict
			Debug.debug("[Plot] Quest objectives data updated to:", quest, "declare_all_objectives_assigned")
			if quest.debugging:
				Debug.pretty_print_dict(updated_objective_dict)
		else:
			Debug.debug("[Plot] The first objective was stored in quest data, updating all objective completion bools", quest, "declare_all_objectives_assigned")
			for objective: Objective in objectives:
				if Quests.is_objective_finished(quest.linked_quest, objective.nomen):
					quest.start()
					Debug.debug("[Plot] objective '%s' was finished, moving to next objective" % objective.nomen, quest, "declare_all_objective_assigned")
					objective._set_finished(true)
					continue
				objective_to_skip_to = objective
				break
			if objective_to_skip_to:
				skip_to_objective(objective_to_skip_to)


	func advance() -> bool:
		if is_finished():
			Debug.debug("[Plot] Redundant call, quest is already finished", quest, "plot.advance")
			return false
		if not is_started():
			Debug.debug("[Plot] Trying to advance the plot '%s' before its quest has started, waiting quest started" % [nomen], quest, "plot.advance")
			await quest.quest_started
			Debug.debug("[Plot] the plot '%s's respective quest has started, continuing" % [nomen], quest, "plot.advance")
		var current_position: int = objectives.find(current_objective)
		if not _has_next_objective(current_position, objectives):
			Debug.debug("[Plot] No remaning objectives to advance to found, completing plot", quest, "advance")
			_finish()
			return true
		current_objective._set_finished(true)
		var _new_objective: Objective = objectives[current_position + 1]
		Debug.debug("[Plot] plot '%s' deactivating objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		_set_current_objective(_new_objective)
		Debug.debug("[Plot] plot '%s' advanced to new objective '%s'" % [nomen, current_objective.nomen], quest, "plot.advance")
		if quest.print_overview_on_advance:
			quest.overview()
		return true


	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()


	func skip_to_objective(objective: Objective) -> bool:
		Debug.debug("[Plot] attempting to skip to objective %s" % [objective.nomen], quest, "plot.skip_to_objective")
		if not objective in objectives:
			push_warning(Debug.define_error("event '%s' has not been declared" % [objective.nomen], quest))
			return false
		var target_index: int = objectives.find(objective)
		var current_index: int = objectives.find(current_objective)
		if target_index < current_index:
			push_warning(Debug.define_error("cannot skip to a past event", quest))
			return false
		if target_index == objectives.size() - 1 and objective.is_finished():
			Debug.debug("[Objectives] Skipped to the last objective of plot '%s', ending plot.", quest, "objective.skip_to_objective")
			_finish()
			return true
		current_objective = objective
		Debug.debug("[Plot] Successfully skipped to objective %s" % [current_objective.nomen], quest, "plot.skip_to_objective")
		return true


	func _finish() -> void:
		for reward: String in rewards:
			pass
		if self == quest.mainplot:
			quest.finish()
		for objective: Objective in objectives:
			objective.finished = true
		finished = true
		Debug.debug("[Plot] plot '%s' finished!" % [nomen], quest, "plot._finish")


	func new_objective(objective_description: String) -> Objective:
		var _new_objective: Objective = Objective.new(objective_description, self, quest)
		if not objectives:
			current_objective = _new_objective
		objectives.append(_new_objective)
		return _new_objective


	func is_objective_finished(objective: Objective) -> bool:
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


	func is_finished() -> bool:
		return finished


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
	var finished: bool = false
	var objective_waypoints: Dictionary[String, Vector3]
	signal waypoint_paired


	func _init(_nomen: String, _plot: Plot, _quest: Quest) -> void:
		plot = _plot
		quest = _quest
		if plot and plot.finished or quest and quest.finished:
			finished = true
			return
		nomen = _nomen


	func _set_finished(value: bool) -> void:
		Debug.debug("[Objective] '%s' setting finished to '%s'" % [nomen, value], quest, "objective._set_finished")
		Data.game_data[Data.PROPERTIES.QUESTS][quest.linked_quest][Quests.PROPERTIES.OBJECTIVES][nomen] = value
		finished = value


	func is_finished() -> bool:
		return finished


	func _try_activate() -> void:
		if quest.is_active():
			Player.set_objective(self)
			if objective_waypoints:
				Global.active_waypoint.set_active_waypoint(objective_waypoints.keys()[0])


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
