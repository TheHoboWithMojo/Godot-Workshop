extends CharacterBody2D
@export_group("Tinker")
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
@export var ibubble: Area2D
@export var health_bar: TextureProgressBar
@export var audio: AudioStreamPlayer2D

@export_group("Character")
@export var character: Dialogue.CHARACTERS
@onready var nomen: String = Dialogue.characters[character]["name"]
@export var timeline: Dialogue.TIMELINES

####### RUNTIME VARIABLES ##############
@export var faction: Factions.FACTIONS = Factions.FACTIONS.NEW_CALIFORNIA_REPUBLIC
@onready var master: Object

signal player_entered_area

func _ready() -> void:
	$Texture/NameTag.set_text(nomen)
	player_entered_area.connect(_check_for_dialog)
	
	Dialogic.preload_timeline(Dialogue.timelines[timeline]["resource"])
	
	add_to_group("interactable")
	add_to_group("npc")
		
	master = Being.new(self)
	
	master.toggle_collision(collision_on)


var first_time_talked_to: bool = true
func _check_for_dialog() -> void:
	if timeline:
		while Global.is_touching_player(self):
			if Input.is_action_just_pressed("interact"):
				if first_time_talked_to:
					first_time_talked_to = false
					if await Dialogue.start(timeline):
						await Dialogic.timeline_ended
			await get_tree().process_frame


func _physics_process(_delta: float) -> void:
	master.seek()
	move_and_slide()
