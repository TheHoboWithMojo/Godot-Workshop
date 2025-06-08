@icon("res://assets/Icons/16x16/party.png")
extends Node
class_name NPCManager
enum PROPERTIES {NAVIGATION, DIALOGUE, CHARACTER, CHARACTER_ENUM, DEFAULT_LEVEL, DEFAULT_SPAWN, LAST_POSITION, LAST_LEVEL, NAME}
var npc_dict: Dictionary[NPC, Dictionary] = {}

@export var debugging: bool = false


func _ready() -> void:
	Debug.debug("Game reloaded, reloading all npcs.", self, "_ready")
	Global.level_manager.about_to_change_level.connect(_on_about_to_change_level)
	child_entered_tree.connect(_on_child_entered_tree)
	for character: Characters.CHARACTERS in Characters.characters:
		var npc: NPC = Characters.get_character_instantiated_scene(character)
		add_child(npc)
		npc_dict[npc] = {}
		npc_dict[npc][PROPERTIES.NAVIGATION] = npc.get_navigation_component()
		npc_dict[npc][PROPERTIES.DIALOGUE] = npc.get_dialog_component()
		npc_dict[npc][PROPERTIES.CHARACTER] = npc.get_character_component()
		npc_dict[npc][PROPERTIES.CHARACTER_ENUM] = npc.get_character_enum()
		npc_dict[npc][PROPERTIES.DEFAULT_LEVEL] = npc.get_default_level()
		npc_dict[npc][PROPERTIES.DEFAULT_SPAWN] = npc.get_default_spawn_position()
		npc_dict[npc][PROPERTIES.LAST_POSITION] = Characters.get_character_last_position(npc.get_character_enum()) if Characters.get_character_last_position(npc.get_character_enum()) else npc.get_default_spawn_position()
		npc_dict[npc][PROPERTIES.LAST_LEVEL] = Characters.get_character_last_level(npc.get_character_enum())
		npc_dict[npc][PROPERTIES.NAME] = Characters.get_character_name(npc.get_character_enum())


func retrieve_property(npc: NPC, property: PROPERTIES) -> Variant:
	return npc_dict[npc][property]


func _on_about_to_change_level(level: Levels.LEVELS) -> void:
	Global.if_do(debugging, [{print: ["\n"]}])
	var level_name: String = Levels.get_level_name(level)
	Debug.debug("Level %s loaded, processing npcs:" % [level_name], self, "_on_new_level_loaded")
	for npc: NPC in get_children():
		var nav: NavigationComponent = retrieve_property(npc, PROPERTIES.NAVIGATION)
		var character_enum: Characters.CHARACTERS = retrieve_property(npc, PROPERTIES.CHARACTER_ENUM)
		var default_level: Levels.LEVELS = retrieve_property(npc, PROPERTIES.DEFAULT_LEVEL)
		var default_spawn: Vector2 = retrieve_property(npc, PROPERTIES.DEFAULT_SPAWN)
		var last_position: Vector2 = retrieve_property(npc, PROPERTIES.LAST_POSITION)
		var nomen: String = retrieve_property(npc, PROPERTIES.NAME)
		var last_level: Levels.LEVELS = retrieve_property(npc, PROPERTIES.LAST_LEVEL)
		if nav and nav.moving_to_level == level:
			Debug.debug("%s is navigating to the current level %s, deferring logic to its navigator" % [nomen, level_name], self, "_on_new_level_loaded")
			continue
		elif last_level == level:
			Debug.debug("%s's last level is the loaded level %s, restoring its last loaded position" % [nomen, level_name], self, "_on_new_level_loaded")
			load_npc(npc, last_position)
			Characters.set_character_last_level(character_enum, level)
			npc_dict[npc][PROPERTIES.LAST_LEVEL] = level
		elif not npc.has_been_encountered() and default_level == level:
			Debug.debug("%s has not been encountered before, spawning at default position" % [nomen], self, "_on_new_level_loaded")
			npc.set_encountered(true)
			load_npc(npc, default_spawn)
			Characters.set_character_last_level(character_enum, level)
			npc_dict[npc][PROPERTIES.LAST_LEVEL] = level
		else:
			Debug.debug("%s not a resident or pathfinder to current level %s, disabling" % [nomen, level_name], self, "_on_new_level_loaded")
			set_npc_enabled(npc, false)


func set_npc_enabled(npc: NPC, value: bool) -> void:
	npc.set_visible(false)
	npc.set_physics_process(false)
	npc.set_process(false)
	npc.collider.set_disabled(true)

	if value:
		await get_tree().process_frame
		npc.collider.set_disabled(false)
		npc.set_physics_process(true)
		npc.set_process(true)
		npc.set_visible(true)


func is_character_stored(character: Characters.CHARACTERS) -> bool:
	return get_children().any(func(npc: NPC) -> bool: return retrieve_property(npc, PROPERTIES.CHARACTER_ENUM) == character)


func get_npcs() -> Array[Node]:
	return get_children()


func is_npc_enabled(npc: NPC) -> bool:
	return npc.is_visible_in_tree()


func get_npc(character: Characters.CHARACTERS) -> NPC:
	var char_name: String = Characters.get_character_name(character)
	if not Characters.is_character_alive(character):
		Debug.debug("NPC %s is dead and could not be retrieved" % [char_name], self, "get_npc")
		return null
	if not is_character_stored(character):
		Debug.debug("Trying to retrieve the NPC %s which has not yet been stored" % [char_name], self, "get_npc")
		return null
	var stored_character: Array = get_children(false).filter(func(npc: NPC) -> bool: return retrieve_property(npc, PROPERTIES.CHARACTER_ENUM) == character)
	match(stored_character.size()):
		0:
			push_error(Debug.define_error("NPC %s does not exist in stored characters" % [char_name], self))
			return null
		1:
			Debug.debug("Returning npc %s" % [char_name], self, "get_npc")
			return stored_character[0]
		_:
			push_error(Debug.define_error("More than one npc shares the same character enum as %s, returning one copy" % [char_name], self))
			return stored_character[0]


func get_stored_npcs_enums() -> Array[Characters.CHARACTERS]:
	return get_children().map(func(npc: NPC) -> Characters.CHARACTERS: return retrieve_property(npc, PROPERTIES.CHARACTER_ENUM))


func load_npc(npc: NPC, position: Vector2 = Vector2.ZERO) -> void:
	npc.set_visible(false)
	npc.set_global_position(position)
	await get_tree().process_frame
	await set_npc_enabled(npc, true)


func get_hostile_npcs() -> Array[NPC]:
	return get_children().filter(func(npc: NPC) -> bool: return Factions.is_faction_hostile(npc.get_faction_enum()))


func _on_child_entered_tree(node: Node) -> void:
	assert(node is NPC, Debug.define_error("Tried to add a node of non-npc type %s to npc manager" % [Global.get_class_of(node)], self))
