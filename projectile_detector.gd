class_name ProjectileDetector extends Area2D

signal projectile_entered(projectile: Projectile)

@export var collider: CollisionShape2D

func _ready() -> void:
	assert(collider)
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		projectile_entered.emit(area)
