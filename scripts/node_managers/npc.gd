extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false
@export var debugging: bool

@export_group("Stats")
@export var repulsion_strength: float = 5000.0
@export var base_speed: float = 3500.0
@export var base_damage: float = 10.0
@export var base_health: float = 30
@export var perception: float = 200.0
@export var exp_on_kill: int = 10

@export_group("Nodes")
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var health_bar: TextureProgressBar
@export var audio: AudioStreamPlayer2D

@export_group("Character")
@export var style: DialogicStyle
@export var character: DialogicCharacter
@export var timelines: Array[DialogicTimeline]

####### RUNTIME VARIABLES ##############
@onready var nomen: String = "steve"
@export var faction: Factions.FACTIONS = Factions.FACTIONS.NEW_CALIFORNIA_REPUBLIC
@onready var master: Object

signal player_entered_area

func _ready() -> void:
	player_entered_area.connect(_check_for_dialog)
	
	for timeline: DialogicTimeline in timelines:
		Dialogic.preload_timeline(timeline)
	
	add_to_group("interactable")
	add_to_group("npc")
		
	master = Being.create_being(self)
	
	master.toggle_collision(collision_on)

func _check_for_dialog() -> void:
	while Global.is_touching_player(self):
		if Input.is_action_just_pressed("interact"):
			Dialogue.start(timelines[0])
			await Dialogic.timeline_ended
		await get_tree().process_frame

func _physics_process(delta: float) -> void:
	if master.is_hostile():
		master.approach_player(delta, perception, repulsion_strength)
		if Global.is_touching_player(self):
			Player.damage(master._damage)
	move_and_slide()
