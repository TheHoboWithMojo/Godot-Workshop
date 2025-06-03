@icon("res://assets/Icons/16x16/party.png")
extends Node
class_name NPCManager
@export var debugging: bool = false
signal npc_assigned(character: Characters.CHARACTERS)


func _ready() -> void:
	if Global.level_manager:
		Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)


func _on_child_entered_tree(node: Node) -> void:
	npc_assigned.emit(node)
	Debug.debug("NPC %s added, displaying current children:" % [node.name], self, "_on_child_entered_tree", {Debug.pretty_print_array:[get_npcs()]})


func _on_new_level_loaded() -> void:
	var new_level: Level = await Levels.get_current_level()
	_replace_duplicates(new_level)
	for npc: NPC in get_npcs(): # hide all npcs that arent moving to the next level
		if Characters.get_character_last_level(npc.character) == new_level.get_level_enum():
			await set_npc_enabled(npc, true)
		else:
			await set_npc_enabled(npc, false)


func _replace_duplicates(new_level: Level) -> void:
	for new_level_npc: NPC in new_level.get_npcs(): # prevent duplicates
		if not is_character_stored(new_level_npc.character):
			new_level_npc.reparent(self)
			Characters.set_character_last_level(new_level_npc.character, new_level.get_level_enum())
			continue
		var duplicate_npc: NPC = new_level_npc
		var stored_npc: NPC = await get_npc(duplicate_npc.character)
		duplicate_npc.queue_free()
		await set_npc_enabled(stored_npc, true)
		stored_npc.set_global_position(Characters.get_character_last_position(stored_npc.character))


func set_npc_enabled(npc: NPC, value: bool) -> void:
	npc.set_visible(value)
	npc.collider.set_disabled(!value)
	npc.set_physics_process(value)
	npc.set_process(value)
	await get_tree().physics_frame


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
	if not get_npcs(): # ensure an npc is stored
		await npc_assigned
	if not Characters.is_character_alive(character) or not is_character_stored(character):
		return null
	for npc: NPC in get_npcs():
		if npc.get_character_enum() == character:
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
