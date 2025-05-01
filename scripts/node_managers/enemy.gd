extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = true
@export var debugging: bool
@export var base_speed: float = 3500.0
@export var base_damage: float = 300.0
@export var base_health: float = 30
@export var repulsion_strength: float = 5000.0
@export var perception: float = 500.0
@export var exp_on_kill: int = 10
@export var nomen: String = ""
@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
@export var faction: Factions.FACTIONS = -1 # -1 is not in enum

# Nodes
@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var health_bar: TextureProgressBar
@export var audio: AudioStreamPlayer2D

@onready var master: Object = Being.create_being(self)

func _ready() -> void:
	master.toggle_collision(collision_on)
		
func _physics_process(delta: float) -> void:
	if master.is_hostile():
		master.approach_player(delta, perception, repulsion_strength)
		if master.is_touching_player:
			Player.damage(master._damage)
	move_and_slide()

func _on_area_body_entered(body: Node) -> void:
	if body == Global.player:
		master.is_touching_player = true
		
func _on_area_body_exited(body: Node) -> void:
	if body == Global.player:
		master.is_touching_player = false
