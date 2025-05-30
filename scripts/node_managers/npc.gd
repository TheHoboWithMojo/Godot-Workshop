@icon("res://assets/Icons/16x16/character_npc.png")
class_name NPC
extends CharacterBody2D
@export_group("Config")
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false
@export var debugging: bool
@export var seeking_enabled: bool = false

@export_group("Stats")
@export var repulsion_strength: float = 5000.0
@export var base_speed: float = 50.0
@export var base_damage: float = 10.0
@export var base_health: float = 30
@export var perception: float = 200.0
@export var exp_on_kill: int = 10

@export_group("Character")
@export var faction: Factions.FACTIONS = Factions.FACTIONS.UNASSIGNED
@export var character: Characters.CHARACTERS
@export var timeline: Dialogue.TIMELINES
@onready var nomen: String = Characters.get_character_name(character)

####### RUNTIME VARIABLES ##############
@onready var sprite: Sprite2D = null
@onready var audio: AudioStreamPlayer2D = null
@onready var nametag: RichTextLabel = $Texture/NameTag
@onready var collider: CollisionShape2D = $Collider
@onready var touch_detector: TouchDetector = $TouchDetector
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var master: Being = Being.new(self)

func _ready() -> void:
	if not active:
		queue_free()
	nametag.set_text(nomen)
	set_name(Characters.get_character_name(character))
	touch_detector.player_entered_area.connect(_check_for_dialog)


var talked_to: bool = false
func _check_for_dialog() -> void:
	if timeline and not Player.is_occupied():
		while Global.player_bubble in touch_detector.get_overlapping_areas():
			if Input.is_action_just_pressed("interact"):
				if await Dialogue.start(timeline):
					talked_to = true
					await Dialogic.timeline_ended
			await get_tree().process_frame


func _physics_process(_delta: float) -> void:
	if master._navigation_target != Vector2.ZERO:
		master.seek()
	move_and_slide()
