class_name NPC
extends CharacterBody2D
@export_group("Optional Components")
@export var dialog_manager: DialogComponent
@export var timeline: Dialogue.TIMELINES
@export var health_manager: HealthComponent
@export var max_health: int = 300
@export var navigation_manager: NavigationComponent
@export var speed: int = 100
@export var character_manager: CharacterComponent
@export var character: Characters.CHARACTERS

@export_group("Nodes")
@export var collider: Collider

@export_group("Config")
@export var active: bool = true
@export var collision_on: bool = true
@export var debugging: bool

@onready var name_tag: RichTextLabel = $Texture/NameTag
@onready var hostile: bool = false # placeholders for future attack manager or something of the sort


func set_hostile(value: bool) -> void:
	hostile = value


func set_paused(value: bool) -> void:
	if navigation_manager:
		navigation_manager.set_physics_process(value)


func get_character_enum() -> Characters.CHARACTERS:
	return character


func await_name_changed() -> void:
	if Characters.get_character_name(character) != name and character_manager:
		await renamed


func get_navigator() -> NavigationComponent:
	return navigation_manager


func get_character() -> CharacterComponent:
	return character_manager


func get_health_component() -> HealthComponent:
	return health_manager


func get_dialog_component() -> DialogComponent:
	return dialog_manager


func _ready() -> void:
	if not active:
		queue_free()
	if not Global.npc_manager.is_character_stored(character):
		Global.npc_manager.add_new_npc(self)
	else:
		Global.npc_manger.remove_duplicate_npc(self)
		return
	if character_manager:
		character_manager.character = character
	if collider:
		collider.set_disabled(!collision_on)
	if dialog_manager and timeline != Dialogue.TIMELINES.UNASSIGNED:
		dialog_manager.set_timeline(timeline)
	if health_manager:
		health_manager.set_max_health(max_health)
		health_manager.set_health(max_health)
