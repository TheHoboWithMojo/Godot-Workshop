extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = true
@export var debugging: bool

@export_group("Stats")
@export var base_speed: float = 3500.0
@export var base_damage: float = 50.0
@export var base_health: float = 30
@export var repulsion_strength: float = 5000.0
@export var perception: float = 500.0
@export var exp_on_kill: int = 10

@export_group("Nodes")
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var health_bar: TextureProgressBar
@export var audio: AudioStreamPlayer2D

@onready var master: Being = Being.new(self)

func _ready() -> void:
	master.set_collision(collision_on)

func _physics_process(delta: float) -> void:
	if master.is_hostile():
		master.approach_player(delta, perception, repulsion_strength)
		if Global.is_touching_player(self):
			print("touching")
			Player.damage(master._damage)
	move_and_slide()
