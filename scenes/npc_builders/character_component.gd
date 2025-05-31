@icon("res://assets/Icons/16x16/character_npc.png")
extends Node
class_name CharacterComponent
@export var character: Characters.CHARACTERS
@export var parent: Node2D
@export var track_death: HealthComponent
@onready var faction: Factions.FACTIONS
@onready var character_name: String
@onready var faction_name: String
@onready var parent_has_health_component: bool = false

func _ready() -> void:
	assert(parent)
	await parent.ready
	assert(character != Characters.CHARACTERS.UNASSIGNED)
	assert(track_death, "All characters must have a be connected to a health component in order to process their death.")
	if not Characters.is_character_alive(character):
		parent.queue_free()
		return
	character_name = Characters.get_character_name(character)
	parent.set_name(character_name)
	if "name_tag" in parent:
		parent.name_tag.set_text(parent.name)
	faction = Characters.get_character_faction(character)
	faction_name = Factions.get_faction_name(faction)
	parent.add_to_group(faction_name)
	parent.add_to_group("interactable")
	parent.add_to_group("npc")
	Global.level_manager.level_loaded.connect(_on_level_loaded)


func _on_death() -> void:
	if not Characters.is_character_alive(character):
		return
	Characters.set_alive(character, false)
	Factions.member_died.emit(character)


func _on_level_loaded() -> void:
	pass
	#if Factions.get_rep_status(faction) == "hostile":
		#set_hostile(true)


func _on_tree_entered() -> void:
	Characters.set_character_last_level(character, Levels.get_current_level().get_level())
	Characters.set_character_last_position(character, parent.global_position)


func _on_tree_exited() -> void:
	Characters.set_character_last_level(character, Levels.get_current_level().get_level())
	Characters.set_character_last_position(character, parent.global_position)
