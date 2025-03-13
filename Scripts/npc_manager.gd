extends StaticBody2D

@export var interaction_bubble: Area2D
@export var collision: CollisionShape2D
@export var sprite: Sprite2D

@onready var is_touching_player: bool = false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if is_touching_player && Input.is_action_just_pressed("interact"):
		Global.start_dialog("npc")

func _on_area_2d_body_entered(body: CharacterBody2D) -> void:
	if body.name == "Player":
		is_touching_player = true

func _on_area_2d_body_exited(body: CharacterBody2D) -> void:
	if body.name == "Player":
		is_touching_player = false
