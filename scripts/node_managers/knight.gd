extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false


# Bases are used for being init, non are used for active tracking
@export var base_speed: float = 3500.0
@onready var speed: float

@export var base_damage: float = 10.0
@onready var damage: float = base_damage

@export var base_health: float = 300.0
@onready var health: float

@export var perception: float = 50.0

@export var nomen: String = ""

@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var animator: AnimationPlayer
@export var debugging: bool
@export var health_bar: TextureProgressBar


@onready var being: Object

@onready var is_touching_player: bool = false

func _ready() -> void:
	await Global.active_and_ready(self, active)
	
	preload("res://dialogic/characters/npc.dch")
	
	being = Being.create_being(self)
	
	health_bar.max_value = base_health
	health_bar.min_value = 0.0
	
	if not collision_on:
		being.toggle_collision(false)

func _process(_delta: float) -> void:
	health = being.health
	
	if is_touching_player && Input.is_action_just_pressed("interact"):
		Global.start_dialog("npc")
		
	health_bar.set_value(health)
	
	if not being.is_alive():
		health_bar.set_value(0.0)
		await being.die()
		
func _physics_process(delta: float) -> void:
	if hostile:
		var vector_to_player =  Global.get_vector_to_player(self)
		var direction: Vector2 = vector_to_player.normalized()
		var detection_range: float = perception * 10
		
		if vector_to_player.length() < detection_range:
			velocity = direction * being.speed * delta * Global.speed_mult
			if velocity.length() > 0:
				being.play_animation("run")
			if direction.x < 0:
				being.flip_sprite(true)
			else:
				being.flip_sprite(false)
			
			move_and_slide()
		else:
			being.play_animation("idle")

func _on_area_body_entered(body) -> void:
	if body == Global.player:
		is_touching_player = true
	
	if hostile:
		while is_touching_player:
			Global.damage_player(10)
			await Global.delay(self, 1.0) # two second delay between damage to avoid overload

func _on_area_body_exited(body) -> void:
	if body == Global.player:
		is_touching_player = false
