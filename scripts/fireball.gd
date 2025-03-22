extends Area2D

@export var speed: float = 500.0
@export var sprite: AnimatedSprite2D
var velocity: Vector2 = Vector2.ZERO

func _ready():
	self.visible = true

func set_velocity(dir: Vector2):
	velocity = dir * speed

func _physics_process(delta):
	position += velocity * delta

func _on_body_entered(body: Node2D):
	if body != Global.player:
		if "being" in body:
			body.being.take_damage(10)
		queue_free()  # Destroy projectile on impact
