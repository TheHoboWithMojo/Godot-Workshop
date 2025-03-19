extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false

@export var base_speed: float = 3000.0
@export var damage: float = 10.0
@export var base_health: float = 100.0
@export var nomen: String = "Steve"

@export var sprite: AnimatedSprite2D
@export var collision: CollisionShape2D
@export var area: Area2D
@export var animator: AnimationPlayer
@export var debug_mode: bool

@onready var is_touching_player: bool = false

func _ready() -> void:
	if active:
		preload("res://dialogic/characters/npc.dch")
		if not collision_on:
			collision.queue_free()
	else:
		self.queue_free()

func _process(_delta: float) -> void:
	if is_touching_player && Input.is_action_just_pressed("interact"):
		Global.start_dialog("npc")
		
func _physics_process(delta: float) -> void:
	if hostile:
		var direction: Vector2 = Global.get_vector_to_player(self).normalized()
		
		velocity = direction * base_speed * delta * Global.speed_mult
		
		move_and_slide()

func _on_area_2d_body_entered(body) -> void:
	if body == Global.player:
		is_touching_player = true
	
	if hostile:
		while is_touching_player:
			Global.player_change_stat("health - %s" % [damage], true)
			await get_tree().create_timer(1.0).timeout

func _on_area_2d_body_exited(body) -> void:
	if body == Global.player:
		is_touching_player = false
