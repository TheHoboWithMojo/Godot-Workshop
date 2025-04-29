extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = true
@export var debugging: bool
@export var base_speed: float = 3500.0
@export var base_damage: float = 10.0
@export var base_health: float = 30
@export var perception: float = 50.0
@export var exp_on_kill: int = 10
@export var nomen: String = ""
@export var faction: int = Factions.factions.NEW_CALIFORNIA_REPUBLIC

@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var health_bar: TextureProgressBar
@export var audio: AudioStreamPlayer2D

@onready var master: Object

func _ready() -> void:
	master = Being.create_being(self)
	
	master.toggle_collision(collision_on)
		
func _physics_process(delta: float) -> void:
	if master.is_hostile():
		var vector_to_player: Vector2 =  Global.get_vector_to_player(self)
		var direction: Vector2 = vector_to_player.normalized()
		var detection_range: float = perception * 10
		
		if vector_to_player.length() < detection_range:
			velocity = direction * master.speed * delta * Global.speed_mult
			if velocity.length() > 0:
				master.play_animation("run")
			if direction.x < 0:
				master.flip_sprite(true)
			else:
				master.flip_sprite(false)
			
			move_and_slide()
		else:
			master.play_animation("idle")

func _on_area_body_entered(body: Node) -> void:
	if body == Global.player:
		master.is_touching_player = true
	
	if master.is_hostile():
		while master.is_touching_player:
			Player.damage(master._damage)
			await Global.delay(self, 0.1) # avoid overload

func _on_area_body_exited(body: Node) -> void:
	if body == Global.player:
		master.is_touching_player = false
