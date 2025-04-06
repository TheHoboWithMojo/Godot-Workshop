extends Area2D

@export var speed: float = 500.0
@export var sprite: AnimatedSprite2D
@export var damage: int = 10
@export var audio: AudioStreamPlayer2D
@export var collider: CollisionShape2D

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	self.visible = true

func set_velocity(dir: Vector2) -> void:
	velocity = dir * speed

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body in get_tree().get_nodes_in_group("beings"):
		body.master.take_damage(damage)
		velocity = Vector2.ZERO
		collider.call_deferred("set_disabled", true)
		if sprite:
			sprite.visible = false
		if audio.playing:
			await audio.finished
		queue_free()
