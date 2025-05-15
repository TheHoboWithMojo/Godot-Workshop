class_name Quest
extends Object

var nomen: String = ""
var characters: Array[DialogicCharacter] = [] # store related characters
var related_timelines: Array[DialogicTimeline] = [] # store related timelines for detection logic
var related_levels: Array[String] = [] # store related levels file paths
var rewards: Array[String] = [] # buff string parsing?
var caller: Node = null # save what called it
var mainplot: Plot = null # non-optional parts
var sideplots: Dictionary[String, Plot] = {} # optional parts
var choices: Array[int] = [] # enum parsing (enum in caller)
var completed: bool = false # is quest completed?
var active: bool = false # is this the current quest?
var started: bool = false

func _init(self_node: Node) -> void:
	if "CHOICES" not in self_node:
		Debug.throw_error("quest.gd", "quest_init", "quest node must contain a CHOICES enum")
		return

	caller = self_node
	nomen = caller.name
	
	for character: Dialogue.CHARACTERS in caller.characters:
		characters.append(Dialogue.get_character(character))
		
	for related_timeline: Dialogue.TIMELINES in caller.related_timelines:
		related_timelines.append(Dialogue.get_timeline(related_timeline))
		
	for level: Levels.LEVELS in caller.related_levels:
		related_levels.append(Levels.get_level_path(level))

	mainplot = Plot.new()
	mainplot.quest = self
	
	Dialogic.timeline_started.connect(_on_timeline_started)
	Global.game_manager.level_loaded.connect(_on_level_loaded)

	caller.add_to_group("quests")

func _on_timeline_started() -> void: # notify the caller if a related timeline has been played (have to reconvert to enum form)
	if Dialogic.current_timeline in related_timelines:
		var timeline: int = Global.string_to_enum(Global.get_rawname(Dialogic.current_timeline), Dialogue.TIMELINES)
		caller._on_related_timeline_played(timeline)

func _on_level_loaded() -> void:
	var current_level: Node = Levels.get_current_level()
	if current_level.scene_file_path in related_levels:
		caller._on_related_level_loaded(current_level)

func new_sideplot(_nomen: String) -> Plot:
	var sideplot: Plot = Plot.new(_nomen)
	sideplot.quest = self
	sideplots[_nomen] = sideplot
	return sideplot

func set_active(value: bool) -> void:
	active = value
	
func start() -> bool:
	if mainplot.objectives:
		mainplot.current_objective = mainplot.objectives.keys()[0]
	for plot: String in sideplots:
		var _plot: Plot = sideplots[plot]
		if _plot.objectives:
			_plot.current_objective = _plot.objectives.keys()[0]
		else:
			Debug.throw_error("quest.gd", "start", "Quest %'s objectives have not been declared" % [_plot.nomen])
			return false
	started = true
	return true

func make_choice(choice: int) -> bool:
	if choice in caller.CHOICES.values():
		choices.append(choice)
		Player.choices.append(Global.enum_to_title(choice, caller.CHOICES))
		return true
	Debug.throw_error("quest.gd", "make_choice", "choice '%s' is not in the CHOICE enum" % [choice])
	return false

func choice_made(choice: int) -> bool:
	if choice in choices:
		return true
	return false

func complete() -> void:
	caller.queue_free()

func overview() -> void:
	print("\n'%s' (Quest) Overview:" % [nomen.capitalize()])
	mainplot.overview()
	for plot_name: String in sideplots:
		sideplots[plot_name].overview()

class Plot:
	var objectives: Dictionary[Objective, String] # objective + description
	var waypoints: Dictionary[Objective, Vector2] # objective + waypoint
	var current_objective: Objective
	var quest: Quest
	var nomen: String
	var rewards: Array[String]
	var completed: bool = false

	func _init(_nomen: String = "main") -> void:
		nomen = _nomen

	func advance() -> bool: # moves forward in the plot
		if quest.started:
			if current_objective:
				var objectives_array: Array = objectives.keys()
				var index: int = objectives_array.find(current_objective)
				if not (index + 1) > objectives_array.size() - 1: # if the new objective is within range
					current_objective = objectives_array[index + 1]
					return true
				if index == objectives.size() - 1:
					complete()
					return true
			else:
				current_objective = objectives.keys()[0]
		Debug.throw_error("quest.gd", "advance", "Cannot advance the plot '%s' without first starting the quest '%s'" % [nomen, quest.nomen])
		return false

	func skip_to_objective(objective: Objective) -> bool: # move to a specific plot objective
		if not objective in objectives:
			Debug.throw_error("quest.gd", "skip_to", "event '%s' has not been declared" % [objective.nomen])
			return false

		var _objectives: Array[String] = objectives.keys()
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
			Player.change_stat(reward)
		if self == quest.mainplot:
			quest.complete()
		completed = true
		print("quest '%s' completed!" % [nomen])

	func new_objective(objective_name: String, description: String = "") -> Objective:
		var _new_objective: Objective = Objective.new(objective_name)
		_new_objective.plot = self
		objectives[_new_objective] = description.to_lower()
		if not current_objective and quest.started:
			current_objective = _new_objective
		return _new_objective

	func objective_complete(objective: Objective) -> bool:
		return objectives.keys().find(objective) < objectives.keys().find(current_objective)

	func overview() -> void:
		print("\n'%s' (Quest: '%s'):" % [nomen.capitalize(), quest.nomen.capitalize()])
		var new_dict: Dictionary[String, String] = {}

		for objective: Objective in objectives:
			new_dict[objective.nomen] = objectives[objective]

		Debug.pretty_print_dict(new_dict)

	func get_current_objective() -> String:
		return current_objective.nomen

	func is_complete() -> bool:
		return completed

class Objective:
	var nomen: String
	var plot: Plot
	var completed: bool = false

	func _init(_nomen: String) -> void:
		nomen = _nomen

	func complete() -> void:
		plot.advance()
		completed = true

	func is_complete() -> bool:
		return completed
		
	func pair_waypoint(vector: Vector2) -> void:
		plot.waypoints[self] = vector
