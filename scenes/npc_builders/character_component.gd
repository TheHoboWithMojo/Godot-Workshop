@icon("res://assets/Icons/16x16/character_npc.png")
extends Node
class_name CharacterComponent
@export var character: Characters.CHARACTERS
@export var parent: Node2D
@export var track_death: HealthComponent
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@onready var faction: Factions.FACTIONS
@onready var character_name: String
@onready var faction_name: String
@onready var parent_health: HealthComponent = parent.get_health_component() if parent is NPC else null
@onready var current_level: Level = null

func _ready() -> void:
	assert(parent != null, Debug.define_error("Character must reference a parent", self))
	await parent.tree_entered
	assert(character != Characters.CHARACTERS.UNASSIGNED, Debug.define_error("Character cannot be unassigned, parent (%s)" % [parent.name], parent))
	assert(track_death != null, Debug.define_error("All characters must have a be connected to a health component in order to process their death.", parent))
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
	if inherit_debugging:
		debugging = parent.debugging


func _on_death() -> void:
	if not Characters.is_character_alive(character):
		return
	Characters.set_alive(character, false)
	Factions.member_died.emit(character)
	Debug.debug("character died.", parent, "_on_death")


func get_character_enum() -> Characters.CHARACTERS:
	return character


func get_character_name() -> String:
	return Characters.get_character_name(character)
