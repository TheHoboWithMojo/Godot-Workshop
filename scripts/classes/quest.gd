class_name Quest
extends Node

@export var linked_quest: Quests.QUESTS
@export var characters: Array[Characters.CHARACTERS]
@export var timelines: Array[Dialogue.TIMELINES] = []
@export var levels: Array[Levels.LEVELS] = []
#@export var rewards: Array[String] = []
#@export var choices: Array[int] = []

var character_resources: Array[DialogicCharacter] = []
var completed: bool = false
var active: bool = false
var started: bool = false
var quest_waypoints: Dictionary[String, Waypoint] = {}
var quest_navpoints: Dictionary[String, Navpoint] = {}
var mainplot: Plot = null
var sideplots: Dictionary[String, Plot] = {}

signal waypoints_assigned
signal navpoints_assigned
signal related_character_loaded(character: Characters.CHARACTERS)
signal related_timeline_played(timelines: Dialogue.TIMELINES)
signal related_level_loaded(level: Levels.LEVELS)
signal quest_created
signal started_quest

func _init() -> void:
	if not Global.level_manager or not Global.npc_manager:
		await Global.active_and_ready(self)
	name = Quests.get_quest_name(linked_quest)
	mainplot = Plot.new()
	mainplot.quest = self
	Dialogic.timeline_started.connect(_on_timeline_started)
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)
	Global.npc_manager.new_npc_loaded.connect(_on_new_npc_loaded)
	add_to_group("quests")
	quest_created.emit()

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
			waypoints_assigned.emit()
			for navpoint: Navpoint in new_navpoints:
				quest_navpoints[Global.get_rawname(navpoint)] = navpoint
			navpoints_assigned.emit()
			related_level_loaded.emit(new_level.get_level_enum())

func _on_new_npc_loaded(npc: NPC) -> void:
	var npc_char: Characters.CHARACTERS = npc.get_character_enum()
	for character: Characters.CHARACTERS in characters:
		if npc_char == character:
			related_character_loaded.emit(npc.get_character_enum())

func waypoint_overview() -> void:
	print("\n%s's Waypoints Overview (name, position):" % [name])
	for waypoint_name: String in quest_waypoints:
		print(waypoint_name + " " + str(quest_waypoints[waypoint_name].global_position))

func navpoint_overview() -> void:
	print("\n%s's Navpoints Overview (name, position):" % [name])
	for navpoint_name: String in quest_navpoints:
		print(navpoint_name + " " + str(quest_navpoints[navpoint_name].global_position))

func get_navpoint_position(navpoint_name: String) -> Vector2:
	return quest_navpoints[navpoint_name].global_position if not Debug.throw_warning_if(navpoint_name not in quest_navpoints.keys(), "The navpoint provided %s does not exist" % [navpoint_name], self) else Vector2.ZERO

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
	print("Quest '%s': set_active(%s)" % [name, value]) # DEBUG
	active = value
	if active == true:
		Player.set_quest(self)
		Player.set_objective(mainplot.current_objective)
		for quest: Quest in self.get_tree().get_nodes_in_group("quests"):
			if quest != self and quest.is_started(): # turn of all other quests if they've started
				print("Quest '%s' deactivating quest '%s'" % [name, quest.name]) # DEBUG
				quest.set_active(false)
	if active == false:
		print("Quest '%s': turning off all waypoints" % [name]) # DEBUG
		for plot: Plot in sideplots.values():
			for objective: Objective in plot.objectives:
				plot._set_active_all_waypoints(objective, false)
		for objective: Objective in mainplot.objectives:
			mainplot._set_active_all_waypoints(objective, false)

func start() -> bool:
	if not await Levels.get_current_level_node():
		await Global.level_manager.new_level_loaded
	if not quest_waypoints and "waypoint_manager" in await Levels.get_current_level_node():
		await waypoints_assigned
	if not quest_navpoints and "navpoint_manager" in await Levels.get_current_level_node():
		await navpoints_assigned
	if not mainplot.objectives:
		Debug.throw_warning("Quest plot %'s objectives have not been declared" % [mainplot.nomen], self)
		return false
	mainplot._start()
	for plot_name: String in sideplots:
		var plot: Plot = sideplots[plot_name]
		if not plot.objectives:
			Debug.throw_warning("Quest %'s objectives have not been declared" % [plot.nomen], self)
			return false
		if not plot.activate_on_main:
			continue
		plot._start()
	set_active(true)
	Global.quest_manager.set_current_quest(self, true)
	started_quest.emit()
	started = true
	return true

func get_quest_enum() -> Quests.QUESTS:
	return linked_quest

func complete() -> void:
	self.queue_free()

func is_active() -> bool:
	print("Quest '%s': is_active() == %s" % [name, active]) # DEBUG
	return active

func is_started() -> bool:
	return started

func overview() -> void:
	print("\n'%s' (Quest) Overview:" % [name.capitalize()])
	mainplot.overview()
	for plot_name: String in sideplots:
		sideplots[plot_name].overview()

func get_active_waypoints() -> Array[Waypoint]:
	if not started:
		push_warning(Debug.define_error("Trying to get waypoints before the quest has started, waiting for start", self))
		await started_quest
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
	var objective_waypoint_dict: Dictionary [Objective, Array] = {}
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

	func _start() -> void:
		if started:
			print("Plot '%s': already started, skipping _start()" % [nomen]) # DEBUG
			return
		if not current_objective.objective_waypoints:
			await current_objective.waypoint_paired
		print("Plot '%s': starting, activating waypoint '%s'" % [nomen, current_objective.objective_waypoints[0].name]) # DEBUG
		current_objective.objective_waypoints[0].set_active(true)
		started = true

	func advance() -> bool:
		if not is_started():
			Debug.throw_warning("Cannot advance the plot '%s' without first starting the quest '%s'" % [nomen, quest.name], quest)
			return false
		if is_complete():
			Debug.throw_warning("Trying to advance a plot that was already completed", quest)
			return false
		var objectives_array: Array[Objective] = objectives.keys()
		var current_position: int = objectives_array.find(current_objective)
		if not _has_next_objective(current_position, objectives_array):
			_complete()
			return true
		var _new_objective: Objective = objectives_array[current_position + 1]
		print("Plot '%s': deactivating objective '%s'" % [nomen, current_objective.nomen]) # DEBUG
		_set_active_all_waypoints(current_objective, false)
		current_objective = _new_objective
		print("Plot '%s': advanced to new objective '%s'" % [nomen, current_objective.nomen]) # DEBUG
		if quest.is_active():
			print("Plot '%s': quest is active, activating new objective '%s'" % [nomen, current_objective.nomen]) # DEBUG
			_set_active_all_waypoints(current_objective, true)
			Player.set_objective(current_objective)
		return true

	func _has_next_objective(index: int, array: Array) -> bool:
		return index + 1 < array.size()

	func _set_active_all_waypoints(objective: Objective, value: bool) -> void:
		for waypoint: Waypoint in objective.objective_waypoints:
			if waypoint:
				print("Plot '%s': setting waypoint '%s' active = %s" % [nomen, waypoint.name, value]) # DEBUG
				waypoint.set_active(value)

	func skip_to_objective(objective: Objective) -> bool:
		if not objective in objectives:
			Debug.throw_warning("event '%s' has not been declared" % [objective.nomen], quest)
			return false
		var _objectives: Array[Objective] = objectives.keys()
		var target_index: int = _objectives.find(objective)
		var current_index: int = _objectives.find(current_objective)
		if target_index == current_index:
			Debug.throw_warning("cannot skip to the same event", quest)
			return false
		if target_index < current_index:
			Debug.throw_warning("cannot skip to a past event", quest)
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
		var _new_objective: Objective = Objective.new(objective_name, self, quest)
		if not objectives:
			current_objective = _new_objective
		objective_waypoint_dict[_new_objective] = []
		objectives[_new_objective] = description
		return _new_objective

	func is_objective_complete(objective: Objective) -> bool:
		return objectives.keys().find(objective) < objectives.keys().find(current_objective)

	func overview() -> void:
		print("\n'%s' (Quest: '%s'):" % [nomen.capitalize(), quest.name.capitalize()])
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
	var quest: Quest
	var completed: bool = false
	var objective_waypoints: Array[Waypoint]
	signal waypoint_paired

	func _init(_nomen: String, _plot: Plot, _quest: Quest) -> void:
		nomen = _nomen
		plot = _plot
		quest = _quest

	func complete() -> void:
		print("Objective '%s': complete() called" % [nomen]) # DEBUG
		plot.advance()
		completed = true

	func is_complete() -> bool:
		return completed

	func get_waypoints() -> Array[Waypoint]:
		return objective_waypoints

	func pair_waypoints(waypoint_names: Array[String]) -> bool:
		for waypoint_name: String in waypoint_names:
			if not waypoint_name in quest.quest_waypoints.keys():
				Debug.throw_warning("waypoint %s does not exist" % [waypoint_name], quest)
				return false
			var waypoint: Waypoint = quest.quest_waypoints[waypoint_name]
			objective_waypoints.append(waypoint)
			plot.objective_waypoint_dict[self].append(waypoint.global_position)
		waypoint_paired.emit()
		return true
