extends StaticBody2D

@export var base_health: float
@export var nomen: String
@export var hostile: bool
@export var sprite: AnimatedSprite2D
@export var collision: CollisionShape2D
@export var area: Area2D
@export var animator: AnimationPlayer
@export var debug_mode: bool
@onready var is_touching_player: bool = false

func _ready() -> void:
	var steve = Being.create_being(self)
	steve.take_damage(100)

func _process(_delta: float) -> void:
	if is_touching_player && Input.is_action_just_pressed("interact"):
		Global.start_dialog("npc")

func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	if body.name == "Player":
		is_touching_player = true

func _on_area_2d_body_exited(body: CharacterBody2D) -> void:
	if body.name == "Player":
		is_touching_player = false
