extends Area2D

@export var speed: float = 500.0
@export var sprite: AnimatedSprite2D
@export var damage: int = 10
@export var audio: AudioStreamPlayer2D
@export var collider: CollisionShape2D

@onready var velocity: Vector2 = Vector2.ZERO
@onready var entered: bool = false

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body in get_tree().get_nodes_in_group("beings"):
		entered = true
		body.master.take_damage(damage)
		destroy()
	elif not body == Global.player:
		destroy()

func _on_body_exited(_body: Node2D) -> void:
	if not entered:
		await Global.delay(self, 3.0) # wait three seconds and self destruct if it doesnt hit anything
		destroy()
		
func destroy() -> void:
	velocity = Vector2.ZERO
	collider.call_deferred("set_disabled", true)
	if sprite:
		sprite.visible = false
	if audio.playing:
		await audio.finished
	queue_free()
