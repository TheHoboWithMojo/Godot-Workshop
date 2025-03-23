extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false


# Bases are used for being init, non are used for active tracking
@export var base_speed: float = 3500.0
@onready var speed: float

@export var base_damage: float = 10.0
@onready var damage: float = base_damage

@export var base_health: float = 50.0
@onready var health: float

@export var perception: float = 50.0

@export var EXP_ON_KILL: int = 10

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
	if hostile:
		add_to_group("enemies")
		
	being = Being.create_being(self)
	
	if not collision_on:
		being.toggle_collision(false)

func _process(_delta: float) -> void:
	if not being.is_alive():
		await being.die(EXP_ON_KILL)
	
	health_bar.set_value(being.health)
		
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

func _on_area_body_entered(body: Node) -> void:
	if body == Global.player:
		is_touching_player = true
	
	if hostile:
		while is_touching_player:
			Global.damage_player(10)
			await Global.delay(self, 1.0) # one second delay between damage to avoid overload

func _on_area_body_exited(body: Node) -> void:
	if body == Global.player:
		is_touching_player = false
