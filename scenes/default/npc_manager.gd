@icon("res://assets/Icons/16x16/party.png")
extends Node
class_name NPCManager
@export var debugging: bool = false
signal new_npc_loaded(npc: NPC)


func _ready() -> void:
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)


func _on_new_level_loaded(level: Level) -> void:
	for npc: NPC in get_children():
		var nav: NavigationComponent = npc.get_navigator()
		if nav and nav.moving_to_level == level.get_level_enum(): # leave logic up to move to level function
			continue
		if Characters.get_character_last_level(npc.character) == level.get_level_enum():
			var spawn_position: Vector2 = Characters.get_character_last_position(npc.character)
			npc.set_global_position(spawn_position)
			await set_npc_enabled(npc, true)
			continue
		Debug.debug("%s not a resident or pathfinder to current level %s, disabling" % [npc.name, level.name], self, "_on_new_level_loaded")
		await set_npc_enabled(npc, false)


func add_new_npc(node: NPC) -> void:
	if node in get_children():
		return
	node.reparent.call_deferred(self, true)
	if node.get_character():
		Characters.set_character_last_level(node.get_character_enum(), await Levels.get_current_level_enum())
		Characters.set_character_last_position(node.get_character_enum(), node.global_position)
	await child_entered_tree
	new_npc_loaded.emit(node)
	Debug.debug("NPC %s added." % [node.name], self, "_on_new_npc_loaded")


func remove_duplicate_npc(dup_npc: NPC) -> void:
	dup_npc.set_process(false) # stop from updating position
	dup_npc.queue_free()


func set_npc_enabled(npc: NPC, value: bool) -> void:
	# Immediately freeze physics processing
	npc.set_physics_process(false)
	npc.set_process(false)
	npc.collider.set_disabled(true)
	npc.set_visible(false)

	if value:
		await get_tree().process_frame  # Wait one frame for stability
		npc.set_visible(true)
		npc.collider.set_disabled(false)
		npc.set_physics_process(true)
		npc.set_process(true)


func store_npc(npc: NPC) -> bool:
	if is_character_stored(npc.character):
		npc.queue_free()
		return false
	npc.reparent(self)
	await get_tree().process_frame
	await set_npc_enabled(npc, false)
	return true


func is_character_stored(character: Characters.CHARACTERS) -> bool:
	for npc: NPC in get_children(): # stop duplication of characters
		if npc.character == character:
			return true
	return false


func get_npcs() -> Array[Node]:
	return get_children()


func get_npc(character: Characters.CHARACTERS) -> NPC:
	var char_name: String = Characters.get_character_name(character)
	if not get_children(): # ensure at least one npc is stored
		Debug.debug("NPC Manager has no children, waiting for one to be added", self, "get_npc")
		await child_entered_tree
		Debug.debug("Child added, resuming function", self, "get_npc")
	if not Characters.is_character_alive(character):
		Debug.debug("NPC %s is dead and could not be retrieved" % [char_name], self, "get_npc")
		return null
	if not is_character_stored(character):
		Debug.debug("NPC %s hasn't been stored, delaying and trying again." % [char_name], self, "get_npc")
		await get_tree().process_frame # give a moment for the npc to load if its a new scene
	for npc: NPC in get_children():
		if npc.get_character_enum() == character:
			Debug.debug("Returning npc %s" % [npc.name], self, "get_npc")
			return npc
	return null


func get_stored_npcs_enums() -> Array[Characters.CHARACTERS]:
	var array: Array[Characters.CHARACTERS]
	for npc: NPC in get_children():
		array.append(npc.character)
	return array


func load_npc(npc: NPC, position: Vector2 = Vector2.ZERO) -> void:
	npc.set_global_position(position)
	set_npc_enabled(npc, true)


func get_hostile_npcs() -> Array[NPC]:
	var array: Array[NPC]
	for npc: NPC in get_children():
		if Factions.get_rep_status(Characters.get_character_faction(npc.character)) == "hostile":
			array.append(npc)
	return array
